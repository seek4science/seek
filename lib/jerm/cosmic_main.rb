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


b="hz3Ym9YZnLRz/kNf45aWCqXrLq+H0nA8FhsHArLppQTnCWoJKYFElICR/DhB
IAqa2xuYhCJfKTubyczTXgfSC3nYY/nS83fZePvxbW/InS6QA/dyKTzApEKa
20ZhYplI"

passcode="12345"
key=generate_key(passcode)
credentials=dec(Base64.decode64(b),key)

harvester= Jerm::CosmicHarvester.new credentials[:cosmic][:u],credentials[:cosmic][:p]
harvester.update

