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
      FileUtils.mkdir_p(File.join(ENV['CONFIG_DIRECTORY'], config_dir))
    end
  end

  def deploy_host_files
    return unless (host_files = @config['host_files']) && !host_files.empty?
    host_files.each do |file|
      # Check for required arguments
      unless file['path'] && !file['path'].empty?
        STDERR.puts 'Mandatory file path not specified.'
        exit 1
      end
      if File.exist?(file['path'])
        STDERR.puts "File path '#{file['path']}' already exists."
        exit 1
      end
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
      if File.exist?(file['path'])
        STDERR.puts "File path '#{file['path']}' already exists."
        exit 1
      end
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
      unit['path'] = File.join(ENV['CONFIG_DIRECTORY'], 'systemd', unit['name'])
      if File.exist?(unit['path'])
        STDERR.puts "Systemd unit '#{unit['name']}' already exists."
        exit 1
      end
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
        File.open(File.join(ENV['CONFIG_DIRECTORY'], 'systemd', 'start'), 'a') do |f|
          puts "Adding #{name} to systemd auto-start list"
          f.puts name
        end
      end
  end

  def build_environment_files
    # Extract the network environment variables
    # This relies on the parasite stage one init being run with docker
    # '--net host' parameter
    # It also assumes that the /etc/hostname file on the host has the host's FQDN
    network_env = {
      'DOCKER_HOSTNAME' => ENV['HOSTNAME'].split('.').first,
      'DOCKER_HOSTNAME_FULL' => ENV['HOSTNAME']
    }
    if ENV['PARASITE_OS'] == 'coreos'
      network_env['HOST_PUBLIC_IP_ADDRESS'] = ENV['COREOS_PUBLIC_IPV4']
      network_env['HOST_PRIVATE_IP_ADDRESS'] = ENV['COREOS_PRIVATE_IPV4']
      if network_env['HOST_PUBLIC_IP_ADDRESS'].nil? || network_env['HOST_PRIVATE_IP_ADDRESS'].nil?
        STDERR.puts 'CoreOS IPv4 address not found in environment, did you run docker with --env-file=/etc/environment?'
      end
    end

    # Build the systemd, docker and profile environment files
    %w( systemd.env docker.env profile.sh ).each do |env_type|
      File.open(File.join(File.join(ENV['CONFIG_DIRECTORY'], 'env'), env_type), 'w') do |env_file|
        environment = {}
        network_env.each { |k, v| environment[k] = v }
        Dir["#{File.join(ENV['CONFIG_DIRECTORY'], 'env.d')}/*.env"]
          .select { |f| f =~ /^[^.]\.env$/ || f =~ /^.+\.#{File.basename(env_type, '.*')}.*\.env$/ }
          .sort.each do |env_part_file|
          File.readlines(env_part_file).each do |line|
            if (match = /^\s*(?<name>[^#][^=]+)[=](?<value>.+)$/.match(line))
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
