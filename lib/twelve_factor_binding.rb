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
    Dir[File.join(get(:source_directory), pattern)]
      .map { |f| f.slice!(File.join(get(:source_directory), '')); f }
      .each do |file|
      block.call(file)
    end
  end
end
