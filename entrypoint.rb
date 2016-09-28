#!/usr/bin/env ruby

# Look for known command aliases
case ARGV[0]
when /host|container/
  require 'parasite_config'
  Thread.current.thread_variable_set('parasite_mode', ARGV.shift)
  puts "Deploying parasite files in #{Thread.current.thread_variable_get('parasite_mode')} mode..."

  # Prepare parasite environment variables
  parasite_config = ParasiteConfig.new
  parasite_config.set_environment
  parasite_config.backup_existing_files
  parasite_config.process_config_files('./conf.d')
end

# Execute the passed in command if provided
exec(*ARGV) unless ARGV.empty?
