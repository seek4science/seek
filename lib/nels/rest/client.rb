require 'rest-client'
require 'uri'
require 'tempfile'

module Nels
  module Rest
    class Client
      attr_reader :base, :access_token

      def initialize(access_token, base = nil)
        base ||= Seek::Config.nels_api_url
        @access_token = access_token
        @base = RestClient::Resource.new(base)
      end

      def sanitiseStoragePath(file_path)
        # IMPORTANT! The file_path uses project,dataset names instead of ids, and there cannot be a trailing backslash (/)
        if file_path[-1]=="/"
          return file_path[0...-1]
        end
        return file_path
      end

      def user_info
        perform('user-info', :get)
      end

      def projects
        perform('sbi/projects', :get)
      end

      def datasets(project_id)
        perform("sbi/projects/#{project_id}/datasets", :get)
      end

      def dataset(project_id, dataset_id)
        perform("sbi/projects/#{project_id}/datasets/#{dataset_id}", :get)
      end

      def persistent_url(project_id, dataset_id, subtype)
        perform("sbi/projects/#{project_id}/datasets/#{dataset_id}/do", :post,
                body: { method: 'get_nels_url', subtype_name: subtype })['url']
      end

      def sample_metadata(reference)
        perform("sbi/sample-metadata?ref=#{reference}", :get, skip_parse: true)
      end

      def datasettypes
        response = perform("sbi/datasettypes", :get)
        newHash={}
        response["data"].each { |x| newHash[x["name"]]=x["id"]}
        return newHash
      end

      def create_dataset(project_id, datasettype, name, description)
        perform("v2/sbi/projects/"+project_id+"/datasets/", :post,
          body: {datasettypeid:datasettype.to_i,name:name,description:description})
      end
      
      # Checks if there is a metadata file associated with the given dataset->subtype
      # NeLS responds 404 if no metadata exists, and 302 if it does
      def check_metadata_exists(project_id, dataset_id, subtype_name)
        perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/metadata/do", :post,
          body: { method: 'seek_metadata_exist'})['state']
      end

      def get_metadata(project_id, dataset_id, subtype_name)
        response_file = perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/metadata", :get, skip_parse: true, raw_response: true)
        # TODO: replace with determine_filename_from_disposition function
        file_name = Mechanize::HTTP::ContentDispositionParser.parse(response_file.headers[:content_disposition]).try(:filename)
        tmp_file = Tempfile.new()
        File.open(tmp_file.path, 'wb'){|f| f << response_file.to_str}

        return file_name, tmp_file.path
      end

      def upload_metadata(project_id, dataset_id, subtype_name, file_path)
        perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/metadata", :post,
          :body => IO.read(file_path),
          :content_type => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      end

      def delete_metadata(project_id, dataset_id, subtype_name, file_path)
        perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/metadata", :delete);
      end

      def sbi_storage_list_demo()
        puts "sbi_storage_list_demo function"

        # It currently returns  {"elements"=>[{"name"=>"analysis_test", "size"=>0, "path"=>"Storebioinfo/SEEK-2021/454_test_tutorial/Analysis/analysis_test", "project_id"=>1125801, "dataset_id"=>1125209, "refid"=>"d648392f-5183-4e81-9e77-88bd23de511d", "description"=>"", "islocked"=>false, "membership_type"=>1, "isFolder"=>true}]}
        perform("/user/sbi-storage/do", :post,
          body: {
            "method":"list",
            "payload":{
              "path":"Storebioinfo/SEEK-2021/454_test_tutorial/Analysis/analysis_test",
              "project_id":1125801,
              "dataset_id":1125209
            }
          });
      end
      
      
      def sbi_storage_list(project_id, dataset_id, file_path)
        puts "sbi_storage_list function"

        # IMPORTANT! The file_path uses project,dataset names instead of ids, and there cannot be a trailing backslash (/)
        file_path = sanitiseStoragePath(file_path)
        puts project_id
        puts dataset_id
        
        puts file_path
        perform("/user/sbi-storage/do", :post,
          body: {
            "method": "list",
            "payload":{
              "path": file_path,
              "project_id": project_id,
              "dataset_id": dataset_id
            }
          })['elements'];
      end

      # UPLOAD FILE FLOW
      # 1. upload_get_reflink: get upload-reference-uri
      # 2. Use upload-reference-uri to upload file
      # 3. Upload file to retrieved URI
      # 4. Once the file is uploaded, trigger transfer to next storage area
      # 5. Return job-id, which can be used in upload_check_progress() to check progress
      def upload_file(project_id, dataset_id,subtype_name, path, file_name, file_path)

        path = sanitiseStoragePath(path)
        file_path = sanitiseStoragePath(file_path)

        # 1. Retrieve upload-reference-uri to upload the file to
        response = perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/data/do", :post,
          body: {
            "method": "initiate_upload",
            "payload":{
              "location_in_sub_type": path,
              "file_name": file_name,
            }
          }
        );
        puts (response)
        reflink = response.url
        job_id = response.job_id

        puts "REFLINK = #{reflink}"
        puts "JOBID = #{jobid}"

        # Upload the file, 204 if success (maybe 200 in new API) 400 with errors otherwise
        response = perform(reflink, :post, :body => IO.read(file_path))
        puts "UPLOAD RESPONSE = #{response}"

          # Once upload is done, trigger NeLS transfer
        response = perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/data/do", :post,
          body: {
            "method": "upload_done",
            "payload":{
              "job_id": job_id,
            }
          });

        puts "UPLOAD DONE RESPONSE = #{response}"
        job_state = 0
        while (job_state != 101)
          response = upload_check_progress(project_id, dataset_id, subtype_name, jobid)
          job_state = response['state_id']
          puts "JOB STATE = #{job_state}"
          puts "COMPLETION = #{response['completion']}"
          sleep(2)
        end

      end
      
      # returns {job_state: state-enums, completion: completion-percentage} 
      # state-enums: SUCCESS(101), FAILURE(102), SUBMITTED(100), PROCESSING(103);
      def upload_check_progress(project_id, dataset_id, subtype_name, job_id)
        path = sanitiseStoragePath(path)

        perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/data/do", :post,
          body: {
            "method": "job_state",
            "payload":{
              "job_id": job_id,
            }
          });
      end

      # DOWNLOAD FILE FLOW
      # 1. fetch file to intermediate area
      # 2. Use given job-id to check progress of transfer
      # 3. Once status is 101, fetch download URI
      # 4. Use one-time use download-URI to download file
      def download_file(project_id, dataset_id,subtype_name, path, file_name)
        path = sanitiseStoragePath(path)

        # 1. Retrieve upload-reference-uri to upload the file to
        response = perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/data/do", :post,
          body: {
            "method": "initiate_download",
            "payload":{
              "location_in_sub_type": path,
              "file_name": file_name,
            }
          }
        );
        job_id = response['jobId'];
        puts "JOBID: #{job_id}"

        # TODO: Poll given job_id until status is 101
        job_state = 0

        while job_state != 101 do
          response = perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/data/do", :post,
                             body: {
                               "method": "job_state",
                               "payload":{
                                 "job_id": job_id
                               }
                             }
          );
          job_state = response['state_id']
          completion_percentage = response['completion']
          puts "STATE = #{job_state}"
          puts "COMP % = #{completion_percentage}"
          sleep(0.25)
        end

        if (job_state == 101)
          # Once the file has been transfered, request download-uri
          response = perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/data/do", :post,
            body: {
              "method": "download_reference",
              "payload":{
                "job_id": job_id
              }
            }
          );
          download_uri = response['url']
          puts "DOWNLOAD URL = #{download_uri}"


          tmp_file = Tempfile.new()
          URI.open(download_uri) do |stream|
            File.open(tmp_file.path, 'wb') do |file|
              file.write(stream.read)
            end
          end
          return file_name, tmp_file.path
        end
      end

      def perform(path, method, opts = {})
        opts[:content_type] ||= :json
        opts[:Authorization] = "Bearer #{@access_token}"
        puts ("DEBUG MODE PRINT ACCESS TOKEN")
        puts "Bearer #{@access_token}"
        body = opts.delete(:body)
        args = [method]
        if body
          body = body.to_json if opts[:content_type] == :json
          args << body
        end
        args << opts

        response = base[path].send(*args)
        # # 404 and 302 exceptions have to be caught, as they are valid responses from NeLS
        # begin
        #   response = base[path].send(*args)
        # rescue RestClient::ResourceNotFound => err
        #   return 404
        # rescue RestClient::Found => err
        #   return 302
        # # rescue RestClient::MovedPermanently, #301
        # #        RestClient::TemporaryRedirect #307
        # #   puts "Other exception"
        # #   return response
        # end

        return response if opts[:skip_parse]

        JSON.parse(response) unless response.empty?
      end

    end
  end
end
