module Seek
  module BioSchema
    module ResourceWrappers
      class Person < ResourceWrapper
        def image
          return unless resource.avatar
          "#{Seek::Config.site_base_host}/#{resource.class.table_name}/#{resource.id}/avatars/#{resource.avatar.id}&size=250"
        end
      end
    end
  end
end
