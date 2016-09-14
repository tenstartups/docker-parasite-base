#!/usr/bin/env ruby

require 'net_http_unix'
require 'parasite_config'

# Set default parasite environment
ENV['PARASITE_DOCKER_IMAGE_NAME'] ||=
  begin
    unless File.exist?('/proc/1/cgroup')
      STDERR.puts 'Cannot find /proc/1/cgroup file.'
      exit 1
    end
    container_id = `cat /proc/1/cgroup | grep 'docker/' | tail -1 | sed 's/^.*\\///'`.strip
    container_id = nil if container_id == ''
    container_id ||= `cat /proc/1/cgroup | grep '/docker-' | tail -1 | sed -Ee 's/^.+\\/docker\-([0-9a-f]+)\\.scope$/\\1/g'`.strip
    container_id = nil if container_id == ''
    if container_id.nil?
      STDERR.puts 'Unable to determine container ID.'
      exit 1
    end
    unless File.socket?('/var/run/docker.sock')
      STDERR.puts 'You must map the docker socket to this container at /var/run/docker.sock.'
      exit 1
    end
    request = Net::HTTP::Get.new('/containers/json')
    client = NetX::HTTPUnix.new('unix:///var/run/docker.sock')
    response = client.request(request)
    JSON.parse(response.body).select { |e| e['Id'] == container_id }.first['Image']
  end
ENV['PARASITE_OS'] = ENV['PARASITE_OS'].downcase
ENV['PARASITE_USER'] ||=
  ENV['PARASITE_USER'] =
    case ENV['PARASITE_OS']
    when 'coreos'
      'core'
    when 'hypriotos'
      'pirate'
    else
      'root'
    end
ENV['PARASITE_HOSTNAME'] = ENV['HOSTNAME'] if ENV['PARASITE_HOSTNAME'].nil? || ENV['PARASITE_HOSTNAME'] == ''
ENV['PARASITE_HOSTNAME_SHORT'] = ENV['PARASITE_HOSTNAME'].split('.').first if ENV['PARASITE_HOSTNAME_SHORT'].nil? || ENV['PARASITE_HOSTNAME_SHORT'] == ''
ENV['PARASITE_DOCKER_BRIDGE_NETWORK'] = 'parasite' if ENV['PARASITE_DOCKER_BRIDGE_NETWORK'].nil? || ENV['PARASITE_DOCKER_BRIDGE_NETWORK'] == ''
ENV['PARASITE_CONFIG_DOCKER_VOLUME'] = 'parasite-config' if ENV['PARASITE_CONFIG_DOCKER_VOLUME'].nil? || ENV['PARASITE_CONFIG_DOCKER_VOLUME'] == ''
ENV['PARASITE_DATA_DOCKER_VOLUME'] = 'parasite-data' if ENV['PARASITE_DATA_DOCKER_VOLUME'].nil? || ENV['PARASITE_DATA_DOCKER_VOLUME'] == ''
ENV['PARASITE_CONFIG_DIRECTORY'] = '/parasite-config' if ENV['PARASITE_CONFIG_DIRECTORY'].nil? || ENV['PARASITE_CONFIG_DIRECTORY'] == ''
ENV['PARASITE_DATA_DIRECTORY'] = '/parasite-data' if ENV['PARASITE_DATA_DIRECTORY'].nil? || ENV['PARASITE_DATA_DIRECTORY'] == ''
ENV['PARASITE_DATA_BACKUP_ARCHIVE'] = 'parasite-data.tar.gz' if ENV['PARASITE_DATA_BACKUP_ARCHIVE'].nil? || ENV['PARASITE_DATA_BACKUP_ARCHIVE'] == ''

# Look for known command aliases
case ARGV[0]
when /host|container/
  Thread.current.thread_variable_set('parasite_mode', ARGV.shift)
  puts "Deploying parasite files in #{Thread.current.thread_variable_get('parasite_mode')} mode..."
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
    Thread.current.thread_variable_set(
      'parasite_source_directory',
      File.join(
        '.',
        File.basename(config)[/([0-9]+\-[a-z0-9]+)(\-.+)?\.yml/, 1],
        Thread.current.thread_variable_get('parasite_mode')
      )
    )
    ParasiteConfig.new(config)
    Thread.current.thread_variable_set('parasite_source_directory', nil)
  end
end

# Execute the passed in command if provided
exec(*ARGV) unless ARGV.empty?
