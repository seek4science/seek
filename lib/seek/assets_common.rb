require 'seek/annotation_common'

#MERGENOTE - need to check these changes form local_copy to external_link, since they mean different things but are beign used as local_copy
#MERGENOTE - yep, seems to make a local copy everytime it is not an external link, without asking the user.
module Seek
  module AssetsCommon
    require 'net/ftp'

    include Seek::AnnotationCommon
    #required to get the icon_filename_for_key
    include ImagesHelper



    def find_display_asset asset=eval("@#{self.controller_name.singularize}");
      name = asset.class.name.underscore
      if asset
          #if no version is specified, show the latest version
          #otherwise, show the specified version, if (this version is correct for login and project member user or if (this is the latest version and the user doesn't login or is not project member')
          if params[:version]
            if asset.find_version(params[:version]).blank? || (!(User.logged_in_and_member?) && params[:version].to_i != asset.latest_version.version)
              error('This version is not available', "invalid route")
              return false
            else
              eval "@display_#{name} = asset.find_version(params[:version])"
            end
          else
            eval "@display_#{name} = asset.latest_version"
          end
        end
    end
  end
end
