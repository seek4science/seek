require 'json/ld'

module Seek
  module Rdf
    # Preloads the remote JSON-LD contexts that SEEK's own JSON-LD refers to, so that converting it to RDF never needs to
    # fetch them over the network. The context documents are kept in json_ld_contexts/, as published at their URLs.
    module JSONLdContexts
      DIRECTORY = File.join(__dir__, 'json_ld_contexts')

      CONTEXTS = {
        'https://w3id.org/ro/crate/1.1/context' => 'ro-crate-1.1.jsonld',
        'https://w3id.org/ro/crate/1.2/context' => 'ro-crate-1.2.jsonld',
        'https://w3id.org/ro/crate/1.3/context' => 'ro-crate-1.3.jsonld'
      }.freeze

      def self.preload
        CONTEXTS.each do |url, filename|
          path = File.join(DIRECTORY, filename)
          # JSON::LD looks up preloaded contexts by their URL with the scheme changed to http.
          # The block is only called the first time the context is used.
          [url, url.sub(/\Ahttps:/, 'http:')].each do |key|
            JSON::LD::Context.add_preloaded(key) do
              JSON::LD::Context.parse(JSON.parse(File.read(path))['@context'])
            end
          end
        end
      end
    end
  end
end
