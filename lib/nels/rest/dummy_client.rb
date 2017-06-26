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
        JSON.parse '[{"id":1123122,"name":"seek_pilot1"},{"id":1123123,"name":"seek_pilot2"}]'
      end

      def datasets(project_id)
        if project_id == 1123122
          JSON.parse '[{"id":1123528,"name":"Illumina-sequencing-dataset","type":"Illumina_seq_data"},{"id":1123527,"name":"proteomics-dataset","type":"Proteomics_data"}]'
        else
          JSON.parse '[{"id":1123530,"name":"ds3","type":"Microarray_Methylation_data"},{"id":1123529,"name":"microarray-methylation","type":"Microarray_Methylation_data"}]'
        end
      end

      def dataset(project_id, dataset_id)
        if project_id == 1123122
          if dataset_id == 1123528
            JSON.parse '{"id":1123528,"name":"Illumina-sequencing-dataset","type":"Illumina_seq_data","subtypes":["analysis","reads"]}'
          else
            JSON.parse '{"id":1123527,"name":"proteomics-dataset","type":"Proteomics_data","subtypes":["Processed","Raw","Results"]}'
          end
        else
          if dataset_id == 1123530
            JSON.parse '{"id":1123530,"name":"ds3","type":"Microarray_Methylation_data","subtypes":["Analysis","Images","Intensities"]}'
          else
            JSON.parse '{"id":1123529,"name":"microarray-methylation","type":"Microarray_Methylation_data","subtypes":["Analysis","Images","Intensities"]}'
          end
        end
      end

    end
  end
end
