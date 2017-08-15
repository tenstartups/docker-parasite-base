#!/usr/bin/env ruby
require 'parasite_config'

STDERR.puts('Specify the service name as the first argument and optional target directory as the second') && exit(1) if ARGV[0].nil?

# Prepare parasite environment variables
parasite_config = ParasiteConfig.new(name: ARGV[0].tr('-', '_'), directory: ARGV[1])
parasite_config.set_environment
parasite_config.check_new_image_id
parasite_config.backup_existing_files
parasite_config.process_config_files
parasite_config.build_systemd_start_list
parasite_config.update_image_id
