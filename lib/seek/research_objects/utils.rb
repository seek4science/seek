module Seek::ResearchObjects
  module Utils

    def path_for_item item, prefix=""
      prefix=path_for_item(item.study,prefix) if item.is_a?(Assay)
      prefix=path_for_item(item.investigation,prefix) if item.is_a?(Study)


      prefix + path_fragment_for_item(item)
    end

    def path_fragment_for_item item
      "#{item.class.name.underscore.pluralize}/#{item.id}/"
    end

    def temp_file filename,prefix=""
      dir = Dir.mktmpdir(prefix)
      open(File.join(dir,filename),"w+")
    end

    def uri_for_item item
      Seek::Config.site_base_host + "/#{item.class.name.underscore.pluralize}/#{item.id}"
    end

    def create_agent person=User.current_user.try(:person)
      unless person.nil?
        person = person.person if person.is_a?(User)
        ROBundle::Agent.new(person.title,uri_for_item(person),person.orcid)
      end
    end

  end
end