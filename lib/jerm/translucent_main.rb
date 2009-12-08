require 'cosmic_harvester'
require 'ba_cell_harvester'
require 'scarab_harvester'
require 'cosmic_resource'
require 'translucent_harvester'
require 'pp'
require 'yaml'
require 'simple_crypt'
require 'base64'

include SimpleCrypt

h = Jerm::TranslucentHarvester.new("")
h.update


#b="hz3Ym9YZnLRz/kNf45aWCqXrLq+H0nA8FhsHArLppQTnCWoJKYFElICR/DhB
#IAqa2xuYhCJfKTubyczTXgfSC3nYY/nS83fZePvxbW/InS6QA/dyKTzApEKa
#20ZhYplI"
#
##puts "Passcode?"
#passcode="12345"
#
#key=generate_key(passcode)
#
#credentials=dec(Base64.decode64(b),key)
##
#h = Jerm::CosmicHarvester.new credentials[:cosmic][:u],credentials[:cosmic][:p]
#h.update

#base="webdav://sysmo-alginate.net/Root/"
#h = Jerm::ScarabHarvester.new "smuser","dbk2009"
#h.update
#h.update
#m={:full_path=>"https://waals.informatik.uni-rostock.de/alfresco/webdav/Projects/Cosmic/Document%20Library/Repository/transcriptomics/transcriptomics001/metadata.csv"}
#r=Jerm::CosmicResource.new({:metadata=>m,:asset=>""},"SysMoAgent","dae4iepib2ki")
#r.populate
#puts r.author_first_name
#puts r.author_last_name
#puts r.author_seek_id
#puts r.protocol

