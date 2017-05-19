require 'rest-client'
require 'uri'

module Nels
  module Rest
    class DummyClient
      BASE = 'https://test-fe.cbu.uib.no/nels-api'

      attr_reader :base, :access_token

      def initialize(access_token, base = BASE)
        @access_token = access_token
        @base = RestClient::Resource.new(base)
      end

      def user_info
        { name: 'Finn', id: 1 }.with_indifferent_access
      end

      def projects
        [{id: 1123122, name: 'seek_pilot1'},
         {id: 1123123, name: 'seek_pilot2'}].map(&:with_indifferent_access)
      end

      def datasets(project_id)
        [{id: project_id * 10 + 1, name: "dataset-#{project_id}-1"},
         {id: project_id * 10 + 2, name: "dataset-#{project_id}-2"}].map(&:with_indifferent_access)
      end

      def data(project_id, dataset_id)
        [{id: dataset_id * 10 + 1, name: "data-#{project_id}-#{dataset_id}-1"},
         {id: dataset_id * 10 + 2, name: "data-#{project_id}-#{dataset_id}-2"}].map(&:with_indifferent_access)
      end

    end
  end
end
