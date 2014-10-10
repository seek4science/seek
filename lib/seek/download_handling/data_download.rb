require 'net/ftp'

module Seek
  module DownloadHandling
    module DataDownload
      #MERGENOTE - replace this with check_url_response_code from upload_handling
      def url_response_code asset_url
        url = URI.parse(URI.encode(asset_url.strip))
        code=""
        begin
          if (["http","https"].include?(url.scheme))
            http =  Net::HTTP.new(url.host, url.port)
            http.use_ssl=true if url.scheme=="https"
            http.start do |http|
              code = http.head(url.request_uri).code
            end
          elsif (url.scheme=="ftp")
            username = 'anonymous'
            password = nil
            username, password = url.userinfo.split(/:/) if url.userinfo

            ftp = Net::FTP.new(url.host)
            ftp.login(username,password)
            ftp.getbinaryfile(url.path, '/dev/null', 20) { break }
            ftp.close
            code="200"
          else
            raise Seek::IncompatibleProtocolException.new("Only http, https and ftp protocols are supported")
          end
        rescue Net::FTPPermError
          code="401"
        rescue Errno::ECONNREFUSED,SocketError,Errno::EHOSTUNREACH
          #FIXME:also using 404 for uknown host, which wouldn't actually really be a http response code
          #indicating that using response codes is not the best approach here.
          code="404"
        end

        return code
      end

      def download
        if self.controller_name=="models"
          download_model
        else
          download_single
        end
      end

      #current model is the only type with multiple content-blobs, this may change in the future
      def download_model

        @model.just_used

        handle_download_zip @display_model
      end

      #for data files, SOPs and presentations, that only have a single content-blob
      def download_single
        name = self.controller_name.singularize
        @asset = eval("@#{name}")

        @asset_version = eval("@display_#{name}")
        @content_blob = @asset_version.content_blob
        @asset.just_used

        disposition = params[:disposition] || 'attachment'

        respond_to do |format|
          format.html {handle_download disposition}
        end
      end

      def show_via_url asset, content_blob=nil
        content_blob = content_blob.nil? ? asset.content_blob : content_blob
        code = url_response_code(content_blob.url)
        if (["301","302", "401"].include?(code))
          redirect_to(content_blob.url, :target=>"_blank")
        elsif code=="404"
          flash[:error]="This item is referenced at a remote location, which is currently unavailable"
          redirect_to polymorphic_path(asset.parent, {:version=>asset.version})
        else
          downloader=Seek::RemoteDownloader.new
          data_hash = downloader.get_remote_data content_blob.url
          send_file data_hash[:data_tmp_path], :filename => data_hash[:filename] || content_blob.original_filename, :content_type => data_hash[:content_type] || content_blob.content_type, :disposition => 'inline'
        end
      end

      def handle_download_zip asset
        #get the list of filename and filepath, {:filename => filepath}
        files_to_download = {}
        #store content_type for the case of 1 file
        content_type = nil
        if asset.respond_to?(:model_image) && asset.model_image
          model_image = asset.model_image
          filename = check_and_rename_file files_to_download.keys, model_image.original_filename
          files_to_download["#{filename}"] = model_image.file_path
          content_type = model_image.content_type
        end
        asset.content_blobs.each do |content_blob|
          if File.exists? content_blob.filepath
            filename = check_and_rename_file files_to_download.keys, content_blob.original_filename
            files_to_download["#{filename}"] = content_blob.filepath
            content_type = content_blob.content_type
          elsif !content_blob.url.nil?
            downloader=Seek::RemoteDownloader.new
            data_hash = downloader.get_remote_data content_blob.url, nil, nil, nil, true
            original_filename = get_filename data_hash[:filename], content_blob.original_filename
            filename = check_and_rename_file files_to_download.keys, original_filename
            files_to_download["#{filename}"] = data_hash[:data_tmp_path]
            content_type = data_hash[:content_type] || content_blob.content_type
          end
        end

        content_type ||= "application/octet-stream"

        #making and sending zip file if there are more than one file
        if files_to_download.count > 1
          make_and_send_zip_file files_to_download, asset
        else
          filepath = files_to_download.values.first
          send_file filepath, :filename => files_to_download.keys.first, :type => content_type
          headers["Content-Length"]=File.size(filepath).to_s
        end
      end

      def make_and_send_zip_file files_to_download, asset
        zip_path= File.join(tmp_zip_file_dir,"#{Time.now.to_f}_#{asset.uuid}.zip")

        t = File.new(zip_path,"w+")
        # Give the path of the temp file to the zip outputstream, it won't try to open it as an archive.
        Zip::OutputStream.open(t.path) do |zos|
          files_to_download.each do |filename,filepath|
            zos.put_next_entry(filename)
            zos.print IO.read(filepath)
          end
        end
        t.close

        send_file t.path, :type => 'application/zip', :disposition => 'attachment', :filename => "#{asset.title}.zip"
        headers["Content-Length"]=File.size(t.path).to_s
      end

      def tmp_zip_file_dir
        if Rails.env=="test"
          dir = File.join(Dir.tmpdir,"seek-tmp","zip-files")
        else
          dir = File.join(Rails.root,"tmp","zip-files")
        end
        FileUtils.mkdir_p dir if !File.exists?(dir)
        dir
      end

      def check_and_rename_file filename_list, filename
        file = filename.split('.')
        file_format = file.last
        original_name = file.take(file.size - 1).join('.')
        i = 1
        while filename_list.include?(filename)
          filename = original_name + '_' + i.to_s + '.' + file_format
          i += 1
        end
        filename
      end

      #prioritize filename from data_hash
      def get_filename filename_from_data_hash, filename_from_content_blob
        if !filename_from_data_hash.blank? && filename_from_data_hash != 'download'
          filename = filename_from_data_hash
        elsif filename_from_data_hash == 'download' && !filename_from_content_blob.blank?
          filename = filename_from_content_blob
        else
          filename = "download"
        end
        filename
      end
    end
  end
end