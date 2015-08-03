#!/usr/bin/env ruby

require 'twelve_factor_config'

# Set default environment
ENV['CONFIG_DIRECTORY'] = '/12factor-config' if ENV['CONFIG_DIRECTORY'].nil? || ENV['CONFIG_DIRECTORY'] == ''
ENV['DATA_DIRECTORY'] = '/12factor-data' if ENV['DATA_DIRECTORY'].nil? || ENV['DATA_DIRECTORY'] == ''

# Look for known command aliases
case ARGV[0]
when /host|container/
  mode = ARGV.shift
  puts "Deploying 12factor files in #{mode} mode..."
  # Execute each deploy script in order
  Dir['./conf.d/*.yml'].sort.each do |config|
    options = {
      mode: mode,
      hostname: ENV['HOSTNAME'].split('.').first,
      stage: ENV['STAGE'],
      role: ENV['ROLE'],
      source_directory: File.join(
        '.',
        File.basename(config)[/([0-9]+\-[a-z0-9]+)(\-.+)?\.yml/, 1],
        mode
      ),
      config_directory: ENV['CONFIG_DIRECTORY'],
      data_directory: ENV['DATA_DIRECTORY']
    }
    TwelveFactorConfig.new(config, options)
  end
end

# Execute the passed in command if provided
exec(*ARGV) if ARGV.size > 0
