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
      source_dirname: File.basename(config)[/(?<dirname>[0-9]+\-[a-z0-9]+)(\-.+)?\.yml/, :dirname],
      hostname: ENV['HOSTNAME'].split('.').first,
      stage: ENV['STAGE'],
      role: ENV['ROLE']
    }
    TwelveFactorConfig.new(config, options)
  end
end

# Execute the passed in command if provided
exec(*ARGV) if ARGV.size > 0
