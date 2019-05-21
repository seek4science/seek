module Seek
  module BioSchema
    # Exception thrown when attempting to generate JSON-LD for a resource type that isn't supported
    class UnsupportedTypeException < RuntimeError; end
  end
end
