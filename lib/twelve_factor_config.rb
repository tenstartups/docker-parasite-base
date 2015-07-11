#!/usr/bin/env ruby

require 'erb'
require 'fileutils'
require 'ostruct'
require 'yaml'

class TwelveFactorConfig

  def initialize(config_file, options = {})

    bindings = OpenStruct.new(options)

    # Process the yml configuration through erb
    template = open(config_file, 'r') { |f| f.read }
    yaml = ERB.new(template).result(bindings.instance_eval { binding })
    config = YAML.load(yaml)

    # Process each file specified
    config['files'].each do |file|

      # Check for required arguments
      unless file['path'] && file['path'].length > 0
        STDERR.puts "Mandatory file path not specified."
        exit 1
      end
      unless file['source'] && file['source'].length > 0
        STDERR.puts "Mandatory file source not specified."
        exit 1
      end
      unless File.exist?(file['source'])
        STDERR.puts "File source '#{file['source']}' not found."
        exit 1
      end
      if File.exist?(file['path'])
        STDERR.puts "File path '#{file['path']}' already exists."
        exit 1
      end

      # Echo a message
      puts "'#{file['source']}' -> '#{file['path']}'"
      template = open(file['source'], 'r') { |f| f.read }
      content = ERB.new(template).result(bindings.instance_eval { binding })
      FileUtils.mkdir_p(File.dirname(file['path']))
      open(file['path'], 'w') { |f| f.write(content) }
      if file['permissions']
        if file['permissions'] =~ /[0-7]{3,4}/
          FileUtils.chmod(file['permissions'].to_i(8), file['path'])
        else
          FileUtils.chmod(file['permissions'], file['path'])
        end
      end
    end

  end

end
