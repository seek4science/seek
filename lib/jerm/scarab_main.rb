require 'cosmic_harvester'
require 'ba_cell_harvester'
require 'scarab_harvester'
require 'cosmic_resource'
require 'translucent_harvester'
require 'pp'
require 'yaml'
require 'simple_crypt'
require 'base64'


harvester= Jerm::ScarabHarvester.new "sysmo11","pseudomonasswb25"
harvester.update

