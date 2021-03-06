#!/usr/bin/env ruby

class ParasiteBinding
  def getenv(key, fail_if_missing = false)
    key = nkey(key)
    value = ENV[key]
    raise "Missing environment variable #{key}" if fail_if_missing && value.nil?
    value
  end

  def getenv!(key)
    getenv(key, true)
  end

  %w(coreos hypriotos).each do |os_key|
    define_method :"#{os_key}?" do
      getenv!(:parasite_os) == os_key
    end
  end

  def choose(key, choices = {}, fail_if_missing = false)
    value = getenv(key, fail_if_missing)
    choice = choices[value] || choices[value.to_sym]
    raise "Missing choice for environment variable #{key} (#{value})" if fail_if_missing && choice.nil?
    choice
  end

  def choose!(key, choices = {})
    choose(key, choices, true)
  end

  def source_files(pattern)
    return unless Dir.exist?(dir = Thread.current.thread_variable_get('parasite_source_directory'))
    Dir.chdir(dir) { Dir[pattern].select { |f| File.file?(f) }.each { |f| yield(f) } }
  end

  private

  def nkey(key)
    key.to_s.upcase
  end
end
