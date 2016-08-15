#!/usr/bin/env ruby

require 'parasite_config'

# Set default environment
ENV['PARASITE_CONFIG_DIRECTORY'] = '/parasite-config' if ENV['PARASITE_CONFIG_DIRECTORY'].nil? || ENV['PARASITE_CONFIG_DIRECTORY'] == ''
ENV['PARASITE_DATA_DIRECTORY'] = '/parasite-data' if ENV['PARASITE_DATA_DIRECTORY'].nil? || ENV['PARASITE_DATA_DIRECTORY'] == ''
ENV['PARASITE_OS'] = ENV['PARASITE_OS'].downcase
if ENV['PARASITE_USER'].nil? || ENV['PARASITE_USER'] == ''
  ENV['PARASITE_USER'] =
    case ENV['PARASITE_OS']
    when 'coreos'
      'core'
    when 'hypriotos'
      'pirate'
    else
      'root'
    end
end

# Look for known command aliases
case ARGV[0]
when /host|container/
  ENV['MODE'] = ARGV.shift
  puts "Deploying parasite files in #{ENV['MODE']} mode..."
  # Backup existing files
  backup_dir = "#{ENV['PARASITE_CONFIG_DIRECTORY']}/.backup_#{Time.now.strftime('%Y%m%d%H%M%S')}"
  Dir["#{ENV['PARASITE_CONFIG_DIRECTORY']}/*"].each do |dir|
    FileUtils.mkdir_p(backup_dir)
    FileUtils.mv(dir, backup_dir)
  end
  # Delete old backups
  Dir.glob("#{ENV['PARASITE_CONFIG_DIRECTORY']}/.backup_*").each do |dir|
    FileUtils.rm_rf(dir) if ((Time.now - File.ctime(dir)) / (24 * 3600)) > 7
  end
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
