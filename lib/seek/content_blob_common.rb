module Seek
  module ContentBlobCommon
    def self.included(base)
      base.before_filter :set_display_asset, :only=>[:view_pdf_content,:get_pdf,:send_image]
    end

    def set_display_asset
      @asset = eval("@#{self.controller_name.singularize}")
      @display_asset = @asset.find_version(params[:version]) || @asset.latest_version
    end

    def view_pdf_content
      #param code is used for temporary link
      get_pdf_url = polymorphic_path(@asset, :version => @display_asset.version, :action => 'get_pdf', :code => params[:code])
      render :partial => 'layouts/pdf_content_display', :locals => {:get_pdf_url => get_pdf_url }
    end

    def get_pdf
      content_blob = @display_asset.content_blob
      dat_filepath = content_blob.filepath
      pdf_filepath = content_blob.filepath('pdf')
      if @display_asset.content_blob.is_pdf?
        send_file dat_filepath, :filename => content_blob.original_filename, :type => content_blob.content_type, :disposition => 'attachment'
      else
        content_blob.convert_to_pdf
        if File.exists?(pdf_filepath)
          send_file pdf_filepath, :filename => content_blob.original_filename, :type => content_blob.content_type, :disposition => 'attachment'
        else
          render :text => 'Unable to convert the file for display'
        end
      end
    end

    def send_image
      content_blob = @display_asset.content_blob
      send_file "#{content_blob.filepath}", :filename => content_blob.original_filename, :type => content_blob.content_type, :disposition=>'inline'
    end
  end
end
