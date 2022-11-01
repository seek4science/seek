require 'rest-client'
require 'uri'
require 'tempfile'

module Nels
  module Rest
    class Client
      class UploadError < StandardError; end
      class TransferError < StandardError; end

      attr_reader :base, :access_token

      def initialize(access_token, base = nil)
        base ||= Seek::Config.nels_api_url
        @access_token = access_token
        @base = RestClient::Resource.new(base)
      end

      def sanitise_storage_path(file_path)
        file_path.chomp('/')
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

      def dataset_types
        response = perform('sbi/datasettypes', :get)
        newHash = {}
        response['data'].each { |x| newHash[x['name']] = x['id'] }
        newHash
      end

      def create_dataset(project_id, datasettype, name, description)
        perform("v2/sbi/projects/#{project_id}/datasets/", :post,
                body: { datasettypeid: datasettype.to_i, name: name, description: description })
      end

      # Checks if there is a metadata file associated with the given dataset->subtype
      # NeLS responds 404 if no metadata exists, and 302 if it does
      def check_metadata_exists(project_id, dataset_id, subtype_name)
        perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/metadata/do", :post,
                body: { method: 'seek_metadata_exist' })['state']
      end

      def get_metadata(project_id, dataset_id, subtype_name)
        response = perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/metadata",
                           :get, skip_parse: true, raw_response: true)
        file_name = Mechanize::HTTP::ContentDispositionParser.parse(response.headers[:content_disposition]).try(:filename)
        tmp_file = Tempfile.new
        File.open(tmp_file.path, 'wb') { |f| f << response.to_str }

        [file_name, tmp_file.path]
      end

      def upload_metadata(project_id, dataset_id, subtype_name, file_path)
        perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/metadata", :post,
                body: IO.read(file_path),
                content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end

      def delete_metadata(project_id, dataset_id, subtype_name, _file_path)
        perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/metadata", :delete)
      end

      def sbi_storage_list(project_id, dataset_id, file_path)
        file_path = sanitise_storage_path(file_path)

        perform('/user/sbi-storage/do', :post,
                body: {
                  "method": 'list',
                  "payload": {
                    "path": file_path,
                    "project_id": project_id,
                    "dataset_id": dataset_id
                  }
                })['elements']
      end

      # UPLOAD FILE FLOW
      # 1. upload_get_reflink: get upload-reference-uri
      # 2. Use upload-reference-uri to upload file
      # 3. Upload file to retrieved URI
      # 4. Once the file is uploaded, trigger transfer to next storage area
      # 5. Return job-id, which can be used in upload_check_progress() to check progress
      def upload_file(project_id, dataset_id, subtype_name, path, file_name, file_path)
        path = sanitise_storage_path(path)
        file_path = sanitise_storage_path(file_path)

        Rails.logger.info("Starting upload of #{file_path}")

        # 1. Retrieve upload-reference-uri to upload the file to
        response = perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/data/do", :post,
                           body: {
                             "method": 'initiate_upload',
                             "payload": {
                               "location_in_sub_type": path,
                               "file_name": file_name
                             }
                           })

        upload_url = response['url']
        job_id = response['jobId']

        Rails.logger.info("Job ID: #{job_id} ; Upload URL: #{upload_url}")

        response = RestClient.post(upload_url, { file: File.new(file_path, 'r'), multipart: true }, { Accept: '*/*' })
        unless response.code == 200
          raise UploadError, "There was an error uploading the file #{file_path}, response was #{response.code}"
        end

        # Once upload is done, trigger NeLS transfer
        response = perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/data/do", :post,
                           body: {
                             "method": 'upload_done',
                             "payload": {
                               "job_id": job_id
                             }
                           })

        Rails.logger.info("upload_done response code: #{response.code}")
        job_state = 0
        while job_state != 101
          job_state, progress = upload_transfer_check_progress(project_id, dataset_id, subtype_name, job_id)
          Rails.logger.info("Waiting for transfer, Job state: #{job_state}; Completion: #{progress}")
          raise TransferError, 'There was an error with the transfer job after upload.' if job_state == 102

          sleep(0.2)
        end
      end

      # returns job_state, completion
      # state-enums: SUCCESS(101), FAILURE(102), SUBMITTED(100), PROCESSING(103);
      def upload_transfer_check_progress(project_id, dataset_id, subtype_name, job_id)
        response = perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/data/do", :post,
                           body: {
                             "method": 'job_state',
                             "payload": {
                               "job_id": job_id
                             }
                           })
        [response['state_id'], response['completion']]
      end

      # DOWNLOAD FILE FLOW
      # 1. fetch file to intermediate area
      # 2. Use given job-id to check progress of transfer
      # 3. Once status is 101, fetch download URI
      # 4. Use one-time use download-URI to download file
      def download_file(project_id, dataset_id, subtype_name, path, file_name)
        path = sanitise_storage_path(path)

        Rails.logger.info('Starting download file')

        response = perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/data/do", :post,
                           body: {
                             "method": 'initiate_download',
                             "payload": {
                               "location_in_sub_type": path,
                               "file_name": file_name
                             }
                           })
        job_id = response['jobId']
        Rails.logger.info("initiate_download, job id: #{job_id}")

        job_state = 0
        while job_state != 101
          job_state, progress = check_download_transfer_progress(project_id, dataset_id, subtype_name, job_id)
          raise TransferError, 'There was an problem with the transfer before download' if job_state == 102

          Rails.logger.info("Waiting for transfer, Job state: #{job_state}; Completion: #{progress}")
          sleep(0.25)
        end

        # Once the file has been transfered, request download-uri
        response = perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/data/do", :post,
                           body: {
                             "method": 'download_reference',
                             "payload": {
                               "job_id": job_id
                             }
                           })
        download_url = response['url']
        Rails.logger.info("Download url: #{download_url}")

        tmp_file = Tempfile.new
        URI.open(download_url) do |stream|
          File.open(tmp_file.path, 'wb') do |file|
            file.write(stream.read)
          end
        end
        [file_name, tmp_file.path]
      end

      def check_download_transfer_progress(project_id, dataset_id, subtype_name, job_id)
        response = perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/data/do", :post,
                           body: {
                             "method": 'job_state',
                             "payload": {
                               "job_id": job_id
                             }
                           })
        [response['state_id'], response['completion']]
      end

      def perform(path, method, opts = {})
        opts[:content_type] ||= :json
        opts[:Authorization] = "Bearer #{@access_token}"

        Rails.logger.debug("In perform, #{opts[:Authorization]}")
        body = opts.delete(:body)
        args = [method]
        if body
          body = body.to_json if opts[:content_type] == :json
          args << body
        end
        args << opts

        response = base[path].send(*args)

        return response if opts[:skip_parse] || response.empty?

        JSON.parse(response)
      end
    end
  end
end
