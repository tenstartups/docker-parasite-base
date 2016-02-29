#!/usr/bin/env ruby

require 'httparty'
require 'resolv'

class ParasiteBinding
  def getenv(key, fail_on_blank = false)
    key = nkey(key)
    value = ENV[key]
    raise "Missing environment variable #{key}" if fail_on_blank && (value.nil? || value == '')
    value
  end

  def getenv!(key)
    getenv(key, true)
  end

  def choose(key, choices = {}, fail_on_blank = false)
    value = getenv(key, fail_on_blank)
    choice = choices[value] || choices[value.to_sym]
    raise "Missing choice for environment variable #{key} (#{value})" if fail_on_blank && (choice.nil? || choice == '')
    choice
  end

  def choose!(key, choices = {})
    choose(key, choices, true)
  end

  def source_files(mode, pattern, &block)
    return unless Dir.exist?(dir = getenv!(:source_directory))
    Dir.chdir(dir) { Dir[pattern].select { |f| File.file?(f) }.each { |f| yield(f) } }
  end

  private

  def nkey(key)
    key.to_s.upcase
  end
end
