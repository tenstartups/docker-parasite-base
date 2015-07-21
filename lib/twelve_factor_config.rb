#!/usr/bin/env ruby

require 'erb'
require 'fileutils'
require 'open_struct_ext'
require 'yaml'

class TwelveFactorConfig

  def initialize(config_file, options = {})

    @bindings = OpenStructExt.new(options)
    @mode = options[:mode]

    # Process the yml configuration through erb
    template = open(config_file, 'r') { |f| f.read }
    yaml = ERB.new(template).result(@bindings.instance_eval { binding })
    config = YAML.load(yaml)

    # Process each file specified
    config['write_files'].each do |file|
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
      unless File.exist?(file['source'])
        STDERR.puts "File source '#{file['source']}' not found."
        exit 1
      end

      # Copy the file into place
      copy_file(file['source'], file['path'], file['permissions'])
    end

    # Process each systemd unit specified
    config['systemd_units'].each do |unit|
      # Check for required arguments
      unless unit['name'] && unit['name'].length > 0
        STDERR.puts 'Mandatory systemd unit name not specified.'
        exit 1
      end
      if File.exist?(unit['path'] = "/12factor/systemd/#{unit['name']}")
        STDERR.puts "Systemd unit '#{unit['name']}' already exists."
        exit 1
      end
      unless unit['source'] && unit['source'].length > 0
        STDERR.puts 'Mandatory systemd unit source not specified.'
        exit 1
      end
      unless File.exist?(unit['source'])
        STDERR.puts "Systemd unit source '#{unit['source']}' not found."
        exit 1
      end

      # Copy the file into place
      copy_file(unit['source'], unit['path'], '0644')
    end

    # Create the service start file
    config['systemd_units']
      .select { |attrs| attrs['start'] == true }
      .map { |attrs| attrs['name'] }
      .each { |name| File.open('/tmp/start', 'a') { |f| f.puts name } }
    copy_file('/tmp/start', '/12factor/systemd/start', '0644')
  end

  def copy_file(source, target, permissions)
    target_dirs = case @mode
                  when 'init'
                    %w( bin env env.d init init.d script systemd tools.d )
                  when 'conf'
                    %w( conf )
                  else
                    %w()
                  end
    if target_dirs.any? { |dir| target.start_with?("/12factor/#{dir}/") }
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
    else
      puts "skipping '#{source}'"
    end
  end
end
