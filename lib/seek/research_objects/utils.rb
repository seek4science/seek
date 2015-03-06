module Seek::ResearchObjects
  module Utils
    def temp_file(filename, prefix = '')
      dir = Dir.mktmpdir(prefix)
      open(File.join(dir, filename), 'w+')
    end

    def create_agent(person = User.current_user.try(:person))
      unless person.nil?
        person = person.person if person.is_a?(User)
        ROBundle::Agent.new(person.title, person.rdf_resource.to_uri.to_s, person.orcid_uri)
      end
    end

    def asset_blobs(asset)
      asset.respond_to?(:content_blob) ? [asset.content_blob] : asset.content_blobs
    end
  end
end
