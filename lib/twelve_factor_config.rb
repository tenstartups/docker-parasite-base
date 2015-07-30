#!/usr/bin/env ruby

require 'erb'
require 'fileutils'
require 'twelve_factor_binding'
require 'yaml'

class TwelveFactorConfig
  def initialize(config_file, options = {})
    @bindings = TwelveFactorBinding.new(options)

    # Process the yml configuration through erb
    template = open(config_file, 'r') { |f| f.read }
    yaml = ERB.new(template).result(@bindings.instance_eval { binding })
    config = YAML.load(yaml) || {}

    # Deploy host files
    if options[:mode] == 'host' && (host_files = config['host_files']) && host_files.length > 0
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
        file['source'] = "./#{options[:source_dirname]}/host/#{file['source']}" unless file['source'].start_with?('/')
        unless File.exist?(file['source'])
          STDERR.puts "File source '#{file['source']}' not found."
          exit 1
        end
        copy_file(file['source'], file['path'], file['permissions'])
      end
    end

    # Deploy host systemd units
    if options[:mode] == 'host' && (systemd_units = config['systemd_units']) && systemd_units.length > 0
      systemd_units.each do |unit|
        # Check for required arguments
        unless unit['name'] && unit['name'].length > 0
          STDERR.puts 'Mandatory systemd unit name not specified.'
          exit 1
        end
        unit['path'] = "/12factor/systemd/#{unit['name']}"
        if File.exist?(unit['path'])
          STDERR.puts "Systemd unit '#{unit['name']}' already exists."
          exit 1
        end
        unless unit['source'] && unit['source'].length > 0
          STDERR.puts 'Mandatory systemd unit source not specified.'
          exit 1
        end
        unit['source'] = "./#{options[:source_dirname]}/host/#{unit['source']}" unless unit['source'].start_with?('/')
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
      copy_file('/tmp/start', '/12factor/systemd/start', '0644')
    end

    # Deploy container files
    if options[:mode] == 'container' && (container_files = config['container_files']) && container_files.length > 0
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
        file['source'] = "./#{options[:source_dirname]}/container/#{file['source']}" unless file['source'].start_with?('/')
        unless File.exist?(file['source'])
          STDERR.puts "File source '#{file['source']}' not found."
          exit 1
        end
        copy_file(file['source'], file['path'], file['permissions'])
      end
    end
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
