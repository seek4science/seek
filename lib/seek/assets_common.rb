require 'seek/annotation_common'

module Seek
  module AssetsCommon

    include Seek::AnnotationCommon
    include Seek::ContentBlobCommon
    include Seek::UploadHandling::DataUpload
    include Seek::DownloadHandling::DataDownload

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



    def destroy_version
      name = self.controller_name.singularize
      @asset = eval("@#{name}")

      if Seek::Config.delete_asset_version_enabled
        @asset.destroy_version  params[:version]

        flash[:notice] = "Version #{params[:version]} was deleted!"
        respond_to do |format|
          format.html { redirect_to(polymorphic_path(@asset)) }
          format.xml { head :ok }
        end
      else
        flash[:error] = "Deleting a version of #{@asset.class.name.underscore.humanize} is not enabled!"
        respond_to do |format|
          format.html { redirect_to(polymorphic_path(@asset)) }
          format.xml { head :ok }
        end
      end
    end


  end
end
