#!/usr/bin/env ruby

require 'ostruct'

class TwelveFactorBinding < OpenStruct
  def get(var)
    send(var.to_sym) || fail("Missing bind variable #{var.to_sym.inspect}")
  end

  def choose(var, choices = {})
    choices[get(var).to_sym] || fail("Missing choice for #{get(var).to_sym.inspect}")
  end

  def source_files(mode, pattern, &block)
    root_path = File.join('.', get(:source_dirname), mode.to_s)
    Dir[File.join(root_path, pattern)].map { |f| f.slice!(File.join(root_path, '')); f }.each do |file|
      block.call(file)
    end
  end
end
