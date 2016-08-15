#!/usr/bin/env ruby

require 'erb'
require 'fileutils'
require 'ipaddr'
require 'shellwords'
require 'socket'
require 'parasite_binding'
require 'yaml'

# From ioctls.h
SIOCGIFADDR = 0x8915

class ParasiteConfig
  def initialize(config_file)
    @bindings = ParasiteBinding.new

    # Process the yml configuration through erb
    template = File.read(config_file)
    yaml = ERB.new(template).result(@bindings.instance_eval { binding })
    @config = YAML.load(yaml) || {}

    # Call individual config methods
    case ENV['MODE']
    when 'host'
      deploy_host_files
      deploy_systemd_units
      build_environment_files
    when 'container'
      deploy_container_files
    end
  end

  private

  def deploy_host_files
    return unless (host_files = @config['host_files']) && !host_files.empty?
    host_files.each do |file|
      # Check for required arguments
      unless file['path'] && !file['path'].empty?
        STDERR.puts 'Mandatory file path not specified.'
        exit 1
      end
      file['path'] = File.join(ENV['PARASITE_CONFIG_DIRECTORY'], file['path']) unless file['path'].start_with?('/')
      unless file['source'] && !file['source'].empty?
        STDERR.puts 'Mandatory file source not specified.'
        exit 1
      end
      file['source'] = File.join(ENV['SOURCE_DIRECTORY'], file['source']) unless file['source'].start_with?('/')
      unless File.exist?(file['source'])
        STDERR.puts "File source '#{file['source']}' not found."
        exit 1
      end
      deploy_file(file['source'], file['path'], file['permissions'])
    end
  end

  def deploy_container_files
    return unless (container_files = @config['container_files']) && !container_files.empty?
    container_files.each do |file|
      # Check for required arguments
      unless file['path'] && !file['path'].empty?
        STDERR.puts 'Mandatory file path not specified.'
        exit 1
      end
      file['path'] = File.join(ENV['PARASITE_CONFIG_DIRECTORY'], file['path']) unless file['path'].start_with?('/')
      unless file['source'] && !file['source'].empty?
        STDERR.puts 'Mandatory file source not specified.'
        exit 1
      end
      file['source'] = File.join(ENV['SOURCE_DIRECTORY'], file['source']) unless file['source'].start_with?('/')
      unless File.exist?(file['source'])
        STDERR.puts "File source '#{file['source']}' not found."
        exit 1
      end
      deploy_file(file['source'], file['path'], file['permissions'])
    end
  end

  def deploy_systemd_units
    return unless (systemd_units = @config['systemd_units']) && !systemd_units.empty?
    systemd_units.each do |unit|
      # Check for required arguments
      unless unit['name'] && !unit['name'].empty?
        STDERR.puts 'Mandatory systemd unit name not specified.'
        exit 1
      end
      unit['path'] = File.join(ENV['PARASITE_CONFIG_DIRECTORY'], 'systemd', unit['name'])
      next unless unit['source'] && !unit['source'].empty?
      unit['source'] = File.join(ENV['SOURCE_DIRECTORY'], unit['source']) unless unit['source'].start_with?('/')
      unless File.exist?(unit['source'])
        STDERR.puts "Systemd unit source '#{unit['source']}' not found."
        exit 1
      end
      deploy_file(unit['source'], unit['path'], '0644')
    end

    # Create the service start file
    systemd_units
      .select { |attrs| attrs['start'] == true }
      .map { |attrs| attrs['name'] }
      .each do |name|
        File.open(File.join(ENV['PARASITE_CONFIG_DIRECTORY'], 'systemd', 'start'), 'a') do |f|
          puts "Adding #{name} to systemd auto-start list"
          f.puts name
        end
      end
  end

  def build_environment_files
    # Get the parasite image name
    begin
      UNIXSocket.new('/var/run/docker.sock')
    rescue Errno::ECONNREFUSED
      STDERR.puts 'You must map the doker socket to this container at /var/run/docker.sock.'
      exit 1
    end
    container_id = `cat /proc/1/cgroup | grep 'docker/' | tail -1 | sed 's/^.*\\///'`.strip
    container_id = nil if container_id == ''
    container_id ||= `cat /proc/1/cgroup | grep '/docker-' | tail -1 | sed -Ee 's/^.+\\/docker\-([0-9a-f]+)\\.scope$/\\1/g'`.strip
    container_id = nil if container_id == ''
    if container_id.nil?
      STDERR.puts 'Unable to determine container ID.'
      exit 1
    end
    docker_containers = JSON.parse(`curl -s --unix-socket /var/run/docker.sock http:/containers/json`)
    docker_image = docker_containers.select { |e| e['Id'] == container_id }.first['Image']

    # Build the systemd, docker and profile environment files
    %w(systemd.env docker.env profile.sh).each do |env_type|
      env_dir = File.join(ENV['PARASITE_CONFIG_DIRECTORY'], 'env')
      FileUtils.mkdir_p(env_dir)
      File.open(File.join(env_dir, env_type), 'w') do |env_file|
        environment = {}
        Dir["#{File.join(ENV['PARASITE_CONFIG_DIRECTORY'], 'env.d')}/*.env"]
          .select { |f| f =~ /^[^.]\.env$/ || f =~ /^.+\.#{File.basename(env_type, '.*')}.*\.env$/ }
          .sort.each do |env_part_file|
          File.readlines(env_part_file).each do |line|
            if (match = /^\s*(?<name>[^#][^=]+)[=](?<value>.+)$/.match(line))
              environment[match[:name]] = match[:value]
            end
          end
        end
        environment['DOCKER_HOSTNAME'] = ENV['HOSTNAME'].split('.').first
        environment['DOCKER_HOSTNAME_FULL'] = ENV['HOSTNAME']
        environment['DOCKER_IMAGE_PARASITE_CONFIG'] = docker_image if %w(systemd.env profile.sh).include?(env_type)
        if env_type == 'profile.sh'
          env_file.write(<<-EOT.gsub(/^\s+/, ''))
            #!/bin/bash +x
          EOT
        end
        env_file.write(<<-EOT.gsub(/^\s+/, ''))
          # Do not edit this file.  It is automatically generated by the parasite
          # initialization process from individual entries in the env.d directory
        EOT
        if env_type == 'profile.sh'
          env_file.write(<<-EOT.gsub(/^\s+/, ''))
            export PATH=/opt/bin:$PATH
          EOT
        end
        environment.keys.sort.each do |env_name|
          if env_type == 'profile.sh'
            env_file.puts("export #{env_name}=#{Shellwords.escape(environment[env_name])}")
          else
            env_file.puts("#{env_name}=#{environment[env_name]}")
          end
        end
      end
    end
  end

  def deploy_file(source, target, permissions)
    puts "'#{source}' -> '#{target}'"
    template = File.read(source)
    content = ERB.new(template).result(@bindings.instance_eval { binding })
    content.gsub!(/^(.*)(___ERB_REMOVE_LINE___)(.*)$\n/, '')
    FileUtils.mkdir_p(File.dirname(target))
    open(target, 'w') { |f| f.write(content) }
    return unless permissions
    if permissions =~ /[0-7]{3,4}/
      FileUtils.chmod(permissions.to_i(8), target)
    else
      FileUtils.chmod(permissions, target)
    end
  end
end
