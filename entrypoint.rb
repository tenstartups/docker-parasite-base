#!/usr/bin/env ruby
require 'parasite_config'

STDERR.puts('Specify the service name as the first argument and optional target directory as the second') && exit(1) if ARGV[0].nil?

Thread.current.thread_variable_set('parasite_service_name', ARGV[0].tr('-', '_'))
Thread.current.thread_variable_set('parasite_config_directory', ARGV[1])

# Prepare parasite environment variables
parasite_config = ParasiteConfig.new
parasite_config.set_environment
parasite_config.check_new_image_id
parasite_config.backup_existing_files
parasite_config.process_config_files
parasite_config.update_image_id
