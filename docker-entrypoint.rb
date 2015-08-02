#!/usr/bin/env ruby

require 'twelve_factor_config'

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
      config_directory: '/12factor-config',
      data_directory: '/12factor-data'
    }
    TwelveFactorConfig.new(config, options)
  end
end

# Execute the passed in command if provided
exec(*ARGV) if ARGV.size > 0
