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
        if perform("seek/sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/metadata/do", :post,
          body: { method: 'exist'}) == 302
          return true
        else
          return false
        end
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
        ## TODO: start job to send data
        # perform("sbi/projects/#{project_id}/datasets/#{dataset_id}/#{subtype_name}/metadata", :post,
        #   body: { file: File.new(file_path)})
      end

      private

      def perform(path, method, opts = {})
        opts[:content_type] ||= :json
        opts[:Authorization] = "Bearer #{@access_token}"
        body = opts.delete(:body)
        args = [method]
        if body
          body = body.to_json if opts[:content_type] == :json
          args << body
        end
        args << opts

        # TODO: debugging logs, remove
        puts base
        puts path
        puts args

        # 404 and 302 exceptions have to be caught, as they are valid responses from NeLS
        begin
          response = base[path].send(*args)
        rescue RestClient::ResourceNotFound => err
          return 404
        rescue RestClient::Found => err
          return 302
        # rescue RestClient::MovedPermanently, #301
        #        RestClient::TemporaryRedirect #307
        #   puts "Other exception"
        #   return response
        end

        puts "response"
        puts response
        return response if opts[:skip_parse]

        JSON.parse(response) unless response.empty?
      end

    end
  end
end
