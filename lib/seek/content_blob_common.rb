module Seek
  module ContentBlobCommon
    def self.included(base)
      base.before_filter :set_content_blob, :only=>[:get_pdf,:send_image]
    end

    def set_content_blob
      begin
        @content_blob = ContentBlob.find(params[:content_blob_id])
      rescue ActiveRecord::RecordNotFound
        return false
      end
    end

    def view_pdf_content
      #param code is used for temporary link
      asset = eval("@#{self.controller_name.singularize}")
      get_pdf_url = polymorphic_path(asset, :content_blob_id => params[:content_blob_id], :action => 'get_pdf', :code => params[:code])
      render :partial => 'layouts/pdf_content_display', :locals => {:get_pdf_url => get_pdf_url }
    end

    def get_pdf
      dat_filepath = @content_blob.filepath
      pdf_filepath = @content_blob.filepath('pdf')
      if @content_blob.is_pdf?
        send_file dat_filepath, :filename => @content_blob.original_filename, :type => @content_blob.content_type, :disposition => 'attachment'
      else
        @content_blob.convert_to_pdf
        if File.exists?(pdf_filepath)
          send_file pdf_filepath, :filename => @content_blob.original_filename, :type => @content_blob.content_type, :disposition => 'attachment'
        else
          render :text => 'Unable to convert the file for display'
        end
      end
    end

    def send_image
      send_file "#{@content_blob.filepath}", :filename => @content_blob.original_filename, :type => @content_blob.content_type, :disposition=>'inline'
    end
  end
end
