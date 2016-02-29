#!/usr/bin/env ruby

require 'parasite_config'

# Set default environment
ENV['CONFIG_DIRECTORY'] = '/parasite-config' if ENV['CONFIG_DIRECTORY'].nil? || ENV['CONFIG_DIRECTORY'] == ''
ENV['DATA_DIRECTORY'] = '/parasite-data' if ENV['DATA_DIRECTORY'].nil? || ENV['DATA_DIRECTORY'] == ''
ENV['PARASITE_OS'] = ENV['PARASITE_OS'].downcase
ENV['PARASITE_USER'] = case ENV['PARASITE_OS']
                       when 'coreos'
                         'core'
                       when 'hypriotos'
                         'pi'
                       end

# Look for known command aliases
case ARGV[0]
when /host|container/
  ENV['MODE'] = ARGV.shift
  puts "Deploying parasite files in #{ENV['MODE']} mode..."
  # Execute each deploy script in order
  Dir['./conf.d/*.yml'].sort.each do |config|
    ENV['SOURCE_DIRECTORY'] = File.join(
      '.',
      File.basename(config)[/([0-9]+\-[a-z0-9]+)(\-.+)?\.yml/, 1],
      ENV['MODE']
    )
    ParasiteConfig.new(config)
  end
end

# Execute the passed in command if provided
exec(*ARGV) unless ARGV.empty?
