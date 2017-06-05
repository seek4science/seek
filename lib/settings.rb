# Based on http://github.com/Squeegy/rails-settings
#
# Copyright (c) 2006 Alex Wayne
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOa AND
# NONINFRINGEMENT. IN NO EVENT SaALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

class Settings < ActiveRecord::Base
  class SettingNotFound < RuntimeError; end

  cattr_accessor :defaults
  @@defaults = {}.with_indifferent_access
  # Support old plugin
  if defined?(SettingsDefaults::DEFAULTS)
    @@defaults = SettingsDefaults::DEFAULTS.with_indifferent_access
  end

  #get or set a variable with the variable as the called method
  def self.method_missing(method, *args)
    method_name = method.to_s
    super(method, *args)
  rescue NoMethodError
    if method_name.end_with?('=')
      var_name = method_name.delete('=')
      value = args.first
      self[var_name] = value
    else
      self[method_name]
    end
  end

  #destroy the specified settings record
  def self.destroy(var_name)
    var_name = var_name.to_s
    if self[var_name]
      target(var_name).destroy
      true
    else
      raise SettingNotFound, "Setting variable \"#{var_name}\" not found"
    end
  end

  def self.to_hash(starting_with=nil)
    vars = target_scoped.select(:var, :values)
    vars = vars.where("var LIKE ?", "'#{starting_with}%'") if starting_with

    result = HashWithIndifferentAccess.new
    vars.each do |record|
      result[record.var] = record.value
    end
  end

  #get a setting value by [] notation
  def self.[](var_name)
    if var = target(var_name)
      var.value
    else
      @@defaults[var_name.to_s]
    end
  end

  #set a setting value by [] notation
  def self.[]=(var_name, value)
    var_name = var_name.to_s

    record = target(var_name) || target_scoped.new(var: var_name)
    record.value = value
    record.save!

    value
  end

  def self.merge!(var_name, hash_value)
    raise ArgumentError unless hash_value.is_a?(Hash)

    old_value = self[var_name] || {}
    raise TypeError, "Existing value is not a hash, can't merge!" unless old_value.is_a?(Hash)

    new_value = old_value.merge(hash_value)
    self[var_name] = new_value if new_value != old_value

    new_value
  end

  #get the value field, YAML decoded
  def value
    YAML::load(self[:value])
  end

  #set the value field, YAML encoded
  def value=(new_value)
    self[:value] = new_value.to_yaml
  end

  def self.target(var_name)
    target_scoped.where(var: var_name.to_s).first
  end

  def self.target_scoped
    where(target_type: nil, target_id: nil)
  end
end
