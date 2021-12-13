require 'rest-client'
require 'uri'

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
      
      def create_dataset(projectid, datasettype, name, description)
        perform("v2/sbi/projects/"+projectid+"/datasets/", :post,
          body: {datasettypeid:datasettype.to_i,name:name,description:description})
      end

      def upload_metadata(file)
        ## TODO: start job to send data
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

        response = base[path].send(*args)

        puts response

        return response if opts[:skip_parse]

        JSON.parse(response) unless response.empty?
      end

    end
  end
end
