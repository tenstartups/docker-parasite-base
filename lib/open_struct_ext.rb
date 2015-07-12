#!/usr/bin/env ruby

require 'ostruct'

class OpenStructExt < OpenStruct

  def get(var)
    send(var.to_sym) || fail("Missing bind variable #{var.to_sym.inspect}")
  end

  def choose(var, choices = {})
    choices[get(var).to_sym] || fail("Missing choice for #{get(var).to_sym.inspect}")
  end

end
