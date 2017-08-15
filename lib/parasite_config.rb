#!/usr/bin/env ruby
require 'awesome_print'
require 'erb'
require 'filemagic'
require 'fileutils'
require 'json'
require 'net_http_unix'
require 'shellwords'
require 'parasite_binding'
require 'yaml'


# From ioctls.h
SIOCGIFADDR = 0x8915

class ParasiteConfig
  attr_accessor :systemd_start_list

  def initialize
    self.systemd_start_list ||= []
  end

  def set_environment
    ENV['PARASITE_DOCKER_IMAGE_NAME'] ||=
      begin
        unless File.exist?('/proc/1/cgroup')
          STDERR.puts('Cannot find /proc/1/cgroup file.')
          exit(1)
        end
        container_id = `cat /proc/1/cgroup | grep 'docker/' | tail -1 | sed 's/^.*\\///'`.strip
        container_id = nil if container_id == ''
        container_id ||= `cat /proc/1/cgroup | grep '/docker-' | tail -1 | sed -Ee 's/^.+\\/docker\-([0-9a-f]+)\\.scope$/\\1/g'`.strip
        container_id = nil if container_id == ''
        if container_id.nil?
          STDERR.puts('Unable to determine docker parasite container ID.')
          exit(1)
        end
        unless File.socket?('/var/run/docker.sock')
          STDERR.puts('You must map the docker socket to this container at /var/run/docker.sock')
          exit(1)
        end
        request = Net::HTTP::Get.new('/containers/json')
        client = NetX::HTTPUnix.new('unix:///var/run/docker.sock')
        response = client.request(request)
        JSON.parse(response.body).select { |e| e['Id'] == container_id }.first['Image']
      end
    ENV['PARASITE_DOCKER_IMAGE_ID'] =
      begin
        unless File.socket?('/var/run/docker.sock')
          STDERR.puts('You must map the docker socket to this container at /var/run/docker.sock')
          exit(1)
        end
        request = Net::HTTP::Get.new('/images/json')
        client = NetX::HTTPUnix.new('unix:///var/run/docker.sock')
        response = client.request(request)
        JSON.parse(response.body).select do |e|
          (e['RepoTags'] || []).include?(ENV.fetch('PARASITE_DOCKER_IMAGE_NAME')) ||
            (e['RepoTags'] || []).include?("#{ENV.fetch('PARASITE_DOCKER_IMAGE_NAME')}:latest")
        end.first['Id']
      end
    ENV['PARASITE_OS'] = ENV.fetch('PARASITE_OS').downcase
    ENV['PARASITE_USER'] ||=
      case ENV.fetch('PARASITE_OS')
      when 'coreos'
        'core'
      when 'hypriotos'
        'pirate'
      else
        'root'
      end
    ENV['PARASITE_HOSTNAME'] ||= ENV.fetch('HOSTNAME')
    ENV['PARASITE_HOSTNAME_SHORT'] ||= ENV.fetch('PARASITE_HOSTNAME').split('.').first
    ENV['PARASITE_DOCKER_BRIDGE_NETWORK'] ||= 'parasite'
    ENV['PARASITE_CONFIG_DOCKER_VOLUME'] ||= 'parasite-config'
    ENV['PARASITE_DATA_DOCKER_VOLUME'] ||= 'parasite-data'
    ENV['PARASITE_CONFIG_DIRECTORY'] = Thread.current.thread_variable_get('parasite_config_directory') || ENV['PARASITE_CONFIG_DIRECTORY'] || '/parasite-config'
    ENV['PARASITE_DATA_DIRECTORY'] ||= '/parasite-data'
    ENV['PARASITE_DATA_BACKUP_ARCHIVE'] ||= 'parasite-data.tar.gz'
    Thread.current.thread_variable_set('parasite_image_id_file', "#{ENV.fetch('PARASITE_CONFIG_DIRECTORY')}/parasite.id")
  end

  def check_new_image_id
    File.exist?(Thread.current.thread_variable_get('parasite_image_id_file')) &&
      ENV.fetch('PARASITE_DOCKER_IMAGE_ID') == File.read(Thread.current.thread_variable_get('parasite_image_id_file')).strip &&
      # No change in the parasite image SHA therefore we exit without doing anything
      exit(0)
    puts "Deploying #{Thread.current.thread_variable_get('parasite_service_name')} parasite configuration files..."
  end

  def backup_existing_files
    backup_dir = "#{ENV.fetch('PARASITE_CONFIG_DIRECTORY')}/.backup_#{Time.now.strftime('%Y%m%d%H%M%S')}"
    Dir["#{ENV.fetch('PARASITE_CONFIG_DIRECTORY')}/*"].each do |dir|
      FileUtils.mkdir_p(backup_dir)
      FileUtils.mv(dir, backup_dir)
    end
    # Delete old backups
    Dir.glob("#{ENV.fetch('PARASITE_CONFIG_DIRECTORY')}/.backup_*").each do |dir|
      FileUtils.rm_rf(dir) if ((Time.now - File.ctime(dir)) / (24 * 3600)) > 7
    end
  end

  def process_config_files
    # Execute each deploy script in order
    Dir['./conf.d/*.yml'].sort.each do |config_file|
      # Set the source directory thread variable
      Thread.current.thread_variable_set(
        'parasite_source_directory',
        File.join(
          '.',
          File.basename(config_file)[/([0-9]+\-[a-z0-9]+)(\-.+)?\.yml/, 1],
          Thread.current.thread_variable_get('parasite_service_name').tr('_', '-')
        )
      )
      @bindings = ParasiteBinding.new

      # Process the yml configuration through erb
      template = File.read(config_file)
      yaml = ERB.new(template).result(@bindings.instance_eval { binding })
      @config = YAML.load(yaml) || {}

      # Call individual config methods
      parasite_service_name = Thread.current.thread_variable_get('parasite_service_name')
      raise 'systemd is a reserved key and cannot be use as a service name' if parasite_service_name == 'systemd'
      deploy_service_files(parasite_service_name)
      if parasite_service_name == 'host'
        deploy_systemd_units
        build_environment_files
      end

      # Unset the source directory thread variable
      Thread.current.thread_variable_set('parasite_source_directory', nil)
    end
  end

  def build_systemd_start_list
    File.open(File.join(ENV.fetch('PARASITE_CONFIG_DIRECTORY'), 'systemd', 'start'), 'w') do |f|
      systemd_start_list.each do |name|
        puts "Adding #{name} to systemd auto-start list"
        f.puts name
      end
    end
  end

  def update_image_id
    FileUtils.mkdir_p(File.dirname(Thread.current.thread_variable_get('parasite_image_id_file')))
    File.write(Thread.current.thread_variable_get('parasite_image_id_file'), ENV.fetch('PARASITE_DOCKER_IMAGE_ID'))
  end

  private

  def deploy_service_files(parasite_service_name)
    return if (container_files = @config[parasite_service_name] || @config["#{parasite_service_name}_files"]).nil? || container_files.empty?
    container_files.each do |file|
      # Check for required arguments
      unless file['path'] && !file['path'].empty?
        STDERR.puts 'Mandatory file path not specified.'
        exit 1
      end
      file['path'] = File.join(ENV.fetch('PARASITE_CONFIG_DIRECTORY'), file['path']) unless file['path'].start_with?('/')
      unless file['source'] && !file['source'].empty?
        STDERR.puts 'Mandatory file source not specified.'
        exit 1
      end
      file['source'] = File.join(Thread.current.thread_variable_get('parasite_source_directory'), file['source']) unless file['source'].start_with?('/')
      unless File.exist?(file['source'])
        STDERR.puts "File source '#{file['source']}' not found."
        exit 1
      end
      deploy_file(file['source'], file['path'], file['permissions'])
    end
  end

  def deploy_systemd_units
    return unless (systemd_units = @config['systemd'] || @config['systemd_units']) && !systemd_units.empty?
    systemd_units.each do |unit|
      # Check for required arguments
      unless unit['name'] && !unit['name'].empty?
        STDERR.puts 'Mandatory systemd unit name not specified.'
        exit 1
      end
      unit['path'] = File.join(ENV.fetch('PARASITE_CONFIG_DIRECTORY'), 'systemd', unit['name'])
      next unless unit['source'] && !unit['source'].empty?
      unit['source'] = File.join('systemd', unit['source']) unless unit['source'].start_with?('systemd', '/')
      unit['source'] = File.join(Thread.current.thread_variable_get('parasite_source_directory'), unit['source']) unless unit['source'].start_with?('/')
      unless File.exist?(unit['source'])
        STDERR.puts "Systemd unit source '#{unit['source']}' not found."
        exit 1
      end
      case ext = File.extname(unit['name'])
      when '.service'
        ENV['SYSTEMD_SERVICE_NAME'] = File.basename(File.basename(unit['name'], ext), '@')
      when '.timer'
        ENV['SYSTEMD_TIMER_NAME'] = File.basename(File.basename(unit['name'], ext), '@')
      end
      deploy_file(unit['source'], unit['path'], '0644')
    end

    # Append or remove from list of services to start
    systemd_units.each do |attrs|
      if attrs['start']
        systemd_start_list << attrs['name']
      else
        systemd_start_list.delete(attrs['name'])
      end
    end
  end

  def build_environment_files
    # Ensure the environment file directory is created
    env_dir = File.join(ENV.fetch('PARASITE_CONFIG_DIRECTORY'), 'env')
    FileUtils.mkdir_p(env_dir)

    File.open(File.join(env_dir, 'profile.env'), 'w') do |file|
      file.write(<<-EOT.gsub(/^\s+/, ''))
        #!/bin/bash +x
        # Do not edit this file.  It is automatically generated by the parasite
        # initialization process.

        export PATH=/opt/bin:$PATH

      EOT
      file.puts
      file.write(<<-EOT.gsub(/^\s+/, ''))
        # Print out information about the parasite configuration
      EOT
      `figlet 'Docker Parasite!!!'`.lines.map(&:chomp).each do |line|
        file.puts("echo #{Shellwords.escape(line)}")
      end
      file.puts "echo #{Shellwords.escape("This host been taken over by a Docker Parasite (#{ENV.fetch('PARASITE_DOCKER_IMAGE_NAME')})!")}"
      file.puts 'echo'
      ENV.select { |k, _v| k =~ /^PARASITE_/ }.sort.each do |k, v|
        file.puts("echo #{Shellwords.escape("#{k}=#{v}")}")
      end
    end
  end

  def deploy_file(source, target, permissions)
    FileUtils.mkdir_p(File.dirname(target))
    if binary?(source)
      puts "Copying '#{source}' -> '#{target}'"
      FileUtils.cp(source, target)
    else
      puts "Processing '#{source}' -> '#{target}'"
      template = File.read(source)
      content = ERB.new(template).result(@bindings.instance_eval { binding })
      content.gsub!(/^(.*)(___ERB_REMOVE_LINE___)(.*)$\n/, '')
      File.write(target, content)
    end
    return unless permissions
    if permissions =~ /[0-7]{3,4}/
      FileUtils.chmod(permissions.to_i(8), target)
    else
      FileUtils.chmod(permissions, target)
    end
    # Clear environment variables
    ENV.delete('SYSTEMD_SERVICE_NAME')
    ENV.delete('SYSTEMD_TIMER_NAME')
  end

  def text?(filename)
    fm = FileMagic.new(FileMagic::MAGIC_MIME)
    fm.file(filename) =~ /^text\//
  ensure
    fm.close
  end

  def binary?(filename)
    !text?(filename)
  end
end
