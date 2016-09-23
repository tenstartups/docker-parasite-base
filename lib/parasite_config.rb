#!/usr/bin/env ruby

require 'erb'
require 'fileutils'
require 'json'
require 'shellwords'
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
    case Thread.current.thread_variable_get('parasite_mode')
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
      file['source'] = File.join(Thread.current.thread_variable_get('parasite_source_directory'), file['source']) unless file['source'].start_with?('/')
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
      file['source'] = File.join(Thread.current.thread_variable_get('parasite_source_directory'), file['source']) unless file['source'].start_with?('/')
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
    # Ensure the environment file directory is created
    env_dir = File.join(ENV['PARASITE_CONFIG_DIRECTORY'], 'env')
    env_components_dir = File.join(ENV['PARASITE_CONFIG_DIRECTORY'], 'env.d')
    FileUtils.mkdir_p(env_dir)

    # Write out combined environment files by combining the individual parts with same name suffix
    Dir["#{env_components_dir}/*.env"]
      .each_with_object({}) { |p, h| (h[p[%r{^\s*(.+)/[0-9]+\-(?<env_group_name>[^/]+)\.env\s*$}, :env_group_name]] ||= []) << p }
      .each do |env_group_name, env_group_files|
      environment = {}
      env_group_files.sort.each do |env_group_file|
        File.readlines(env_group_file).each do |line|
          if (match = /^\s*(?<name>[^#][^=]+)[=](?<value>.+)$/.match(line))
            environment[match[:name]] = match[:value]
          end
        end
      end
      File.open(File.join(env_dir, "#{env_group_name}.env"), 'w') do |file|
        file.write(<<-EOT.gsub(/^\s+/, ''))
          # Do not edit this file.  It is automatically generated by the parasite
          # initialization process from individual entries in the env.d directory
        EOT
        environment.keys.sort.each do |env_name|
          file.puts("#{env_name}=#{environment[env_name]}")
        end
      end
    end

    File.open(File.join(env_dir, 'profile.env'), 'w') do |file|
      file.write(<<-EOT.gsub(/^\s+/, ''))
        #!/bin/bash +x
        # Do not edit this file.  It is automatically generated by the parasite
        # initialization process from individual entries in the env.d directory

        export PATH=/opt/bin:$PATH

      EOT
      file.puts
      file.write(<<-EOT.gsub(/^\s+/, ''))
        # Print out information about the parasite configuration
      EOT
      `figlet 'Docker Parasite!!!'`.lines.map(&:chomp).each do |line|
        file.puts("echo #{Shellwords.escape(line)}")
      end
      file.puts "echo #{Shellwords.escape("This host been taken over by a Docker Parasite (#{ENV['PARASITE_DOCKER_IMAGE_NAME']})!")}"
      file.puts 'echo'
      ENV.select { |k, _v| k =~ /^PARASITE_/ }.sort.each do |k, v|
        file.puts("echo #{Shellwords.escape("#{k}=#{v}")}")
      end
    end
  end

  def deploy_file(source, target, permissions)
    puts "'#{source}' -> '#{target}'"
    template = File.read(source)
    content = ERB.new(template).result(@bindings.instance_eval { binding })
    content.gsub!(/^(.*)(___ERB_REMOVE_LINE___)(.*)$\n/, '')
    FileUtils.mkdir_p(File.dirname(target))
    File.write(target, content)
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
end
