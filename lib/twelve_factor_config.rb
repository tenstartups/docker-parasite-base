#!/usr/bin/env ruby

require 'erb'
require 'fileutils'
require 'ipaddr'
require 'shellwords'
require 'socket'
require 'twelve_factor_binding'
require 'yaml'

# From ioctls.h
SIOCGIFADDR = 0x8915

class TwelveFactorConfig
  def initialize(config_file, options = {})
    @options = options
    @bindings = TwelveFactorBinding.new(@options)

    # Process the yml configuration through erb
    template = open(config_file, 'r') { |f| f.read }
    yaml = ERB.new(template).result(@bindings.instance_eval { binding })
    @config = YAML.load(yaml) || {}

    # Call individual config methods
    case @options[:mode]
    when 'host'
      create_host_directories
      deploy_host_files
      deploy_systemd_units
      build_environment_files
    when 'container'
      deploy_container_files
    end
  end

  def create_host_directories
    %w( env env.d init init.d script tools.d systemd ).each do |config_dir|
      FileUtils.mkdir_p(File.join(@options[:config_directory], config_dir))
    end
  end

  def deploy_host_files
    return unless (host_files = @config['host_files']) && host_files.length > 0
    host_files.each do |file|
      # Check for required arguments
      unless file['path'] && file['path'].length > 0
        STDERR.puts 'Mandatory file path not specified.'
        exit 1
      end
      if File.exist?(file['path'])
        STDERR.puts "File path '#{file['path']}' already exists."
        exit 1
      end
      unless file['source'] && file['source'].length > 0
        STDERR.puts 'Mandatory file source not specified.'
        exit 1
      end
      file['source'] = "./#{@options[:source_dirname]}/host/#{file['source']}" unless file['source'].start_with?('/')
      unless File.exist?(file['source'])
        STDERR.puts "File source '#{file['source']}' not found."
        exit 1
      end
      copy_file(file['source'], file['path'], file['permissions'])
    end
  end

  def deploy_container_files
    return unless (container_files = @config['container_files']) && container_files.length > 0
    container_files.each do |file|
      # Check for required arguments
      unless file['path'] && file['path'].length > 0
        STDERR.puts 'Mandatory file path not specified.'
        exit 1
      end
      if File.exist?(file['path'])
        STDERR.puts "File path '#{file['path']}' already exists."
        exit 1
      end
      unless file['source'] && file['source'].length > 0
        STDERR.puts 'Mandatory file source not specified.'
        exit 1
      end
      file['source'] = "./#{@options[:source_dirname]}/container/#{file['source']}" unless file['source'].start_with?('/')
      unless File.exist?(file['source'])
        STDERR.puts "File source '#{file['source']}' not found."
        exit 1
      end
      copy_file(file['source'], file['path'], file['permissions'])
    end
  end

  def deploy_systemd_units
    return unless (systemd_units = @config['systemd_units']) && systemd_units.length > 0
    systemd_units.each do |unit|
      # Check for required arguments
      unless unit['name'] && unit['name'].length > 0
        STDERR.puts 'Mandatory systemd unit name not specified.'
        exit 1
      end
      unit['path'] = "#{@options[:config_directory]}/systemd/#{unit['name']}"
      if File.exist?(unit['path'])
        STDERR.puts "Systemd unit '#{unit['name']}' already exists."
        exit 1
      end
      unless unit['source'] && unit['source'].length > 0
        STDERR.puts 'Mandatory systemd unit source not specified.'
        exit 1
      end
      unit['source'] = "./#{@options[:source_dirname]}/host/#{unit['source']}" unless unit['source'].start_with?('/')
      unless File.exist?(unit['source'])
        STDERR.puts "Systemd unit source '#{unit['source']}' not found."
        exit 1
      end
      copy_file(unit['source'], unit['path'], '0644')
    end

    # Create the service start file
    systemd_units
      .select { |attrs| attrs['start'] == true }
      .map { |attrs| attrs['name'] }
      .each { |name| File.open('/tmp/start', 'a') { |f| f.puts name } }
    copy_file('/tmp/start', "#{@options[:config_directory]}/systemd/start", '0644')
  end

  def build_environment_files
    env_parts_dir = File.join(@options[:config_directory], 'env.d')
    env_dir =
    environment_regex = /^\s*(?<name>[^#][^=]+)[=](?<value>.+)$/

    # Extract the network environment variables
    # This relies on the twelve-factor stage one init being run with docker
    # '--net host' parameter
    # It also assumes that the /etc/hostname file on the host has the host's FQDN
    network_env = {
      'HOST_PUBLIC_IP_ADDRESS' => ENV['COREOS_PUBLIC_IPV4'],
      'HOST_PRIVATE_IP_ADDRESS' => ENV['COREOS_PRIVATE_IPV4'],
      'DOCKER0_IP_ADDRESS' => (ip_address('docker0') rescue '172.17.42.1'),
      'DOCKER_HOSTNAME' => ENV['HOSTNAME'].split('.').first,
      'DOCKER_HOSTNAME_FULL' => ENV['HOSTNAME']
    }

    # Build the systemd, docker and profile environment files
    %w( systemd.env docker.env profile.sh ).each do |env_type|
      File.open(File.join(File.join(@options[:config_directory], 'env'), "#{env_type}"), 'w') do |env_file|
        environment = network_env.clone
        Dir["#{env_parts_dir}/*.env"]
          .select { |f| f =~ /^[^.]\.env$/ || f =~ /^.+\.#{File.basename(env_type, '.*')}.*\.env$/ }
          .each do |env_part_file|
          File.readlines(env_part_file).each do |line|
            if (match = environment_regex.match(line))
              environment[match[:name]] = match[:value]
            end
          end
        end
        if env_type == 'profile.sh'
          env_file.write(<<-EOT.gsub(/^\s+/, ''))
            #!/bin/bash +x
          EOT
        end
        env_file.write(<<-EOT.gsub(/^\s+/, ''))
          # Do not edit this file.  It is automatically generated by the twelve factor
          # initialization process from individual entries in the env.d directory
        EOT
        if env_type == 'profile.sh'
          env_file.write(<<-EOT.gsub(/^\s+/, ''))
            export PATH=$PATH:/opt/bin
          EOT
        end
        environment.keys.sort.each do |env_name|
          if env_type == 'profile.sh' then
            env_file.puts("export #{env_name}=#{Shellwords.escape(environment[env_name])}")
          else
            env_file.puts("#{env_name}=#{environment[env_name]}")
          end
        end
      end
    end
  end

  def ip_address(iface)
    sock = UDPSocket.new
    buf = [iface, ''].pack('a16h16')
    sock.ioctl(SIOCGIFADDR, buf)
    sock.close
    buf[20..24].unpack('CCCC').join('.')
  end

  def copy_file(source, target, permissions)
    puts "'#{source}' -> '#{target}'"
    template = open(source, 'r') { |f| f.read }
    content = ERB.new(template).result(@bindings.instance_eval { binding })
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
