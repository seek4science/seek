# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/gdata.rb'

Hoe.new('GData', GData::VERSION) do |p|
  p.rubyforge_name = 'gdata-ruby'
  p.summary = 'Google GData Ruby API'
  p.author = 'Dion Almaer'
  p.email = 'dion@almaer.com'
  p.extra_deps << ['builder', '>=2.1.2']

  p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")

  #p.executables = %w(addenclosure bloggerfeed gspreadsheet removeenclosure)
end

# vim: syntax=Ruby
