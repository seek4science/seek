require 'rest-client'
require 'uri'

module Nels
  module Rest
    class DummyClient
      attr_reader :access_token

      def initialize(access_token, base = nil)
        @access_token = access_token
      end

      def user_info
        { name: 'Finn', id: 1 }.with_indifferent_access
      end

      def projects
        JSON.parse '[{"id":1123122,"name":"seek_pilot1","description":"Seek pilot project 1","contact_person":"Kidane M. Tekle","creation_date":"2017-05-17T22:00:00Z"},{"id":1123123,"name":"seek_pilot2","description":"Second pilot project for seek","contact_person":"Kidane M. Tekle","creation_date":"2017-05-17T22:00:00Z"}]'
      end

      def datasets(project_id)
        if project_id == 1123122
          JSON.parse '[{"creation_date":"2017-05-17T22:00:00Z","owner_name":"","description":"test","id":1123528,"name":"Illumina-sequencing-dataset","type":"Illumina_seq_data"},{"creation_date":"2017-05-17T22:00:00Z","owner_name":"","description":"test","id":1123527,"name":"proteomics-dataset","type":"Proteomics_data"}]'
        else
          JSON.parse '[{"creation_date":"2017-05-17T22:00:00Z","owner_name":"","description":"test","id":1123530,"name":"ds3","type":"Microarray_Methylation_data"},{"creation_date":"2017-05-17T22:00:00Z","owner_name":"","description":"test","id":1123529,"name":"microarray-methylation","type":"Microarray_Methylation_data"}]'
        end
      end

      def dataset(project_id, dataset_id)
        if project_id == 1123122
          if dataset_id == 1123528
            JSON.parse '{"creation_date":"2017-05-17T22:00:00Z","id":1123528,"name":"Illumina-sequencing-dataset","type":"Illumina_seq_data","owner_name":"","description":"test","subtypes":[{"type":"analysis","size":0},{"type":"reads","size":0}]}'
          else
            JSON.parse '{"creation_date":"2017-05-17T22:00:00Z","id":1123527,"name":"proteomics-dataset","type":"Proteomics_data","owner_name":"","description":"test","subtypes":[{"type":"Processed","size":0},{"type":"Raw","size":94353},{"type":"Results","size":0}]}'
          end
        else
          if dataset_id == 1123530
            JSON.parse '{"creation_date":"2017-05-17T22:00:00Z","id":1123530,"name":"ds3","type":"Microarray_Methylation_data","owner_name":"","description":"test","subtypes":[{"type":"Analysis","size":0},{"type":"Images","size":0},{"type":"Intensities","size":0}]}'
          else
            JSON.parse '{"creation_date":"2017-05-17T22:00:00Z","id":1123529,"name":"microarray-methylation","type":"Microarray_Methylation_data","owner_name":"","description":"test","subtypes":[{"type":"Analysis","size":0},{"type":"Images","size":0},{"type":"Intensities","size":0}]}'
          end
        end
      end

      def persistent_url(project_id, dataset_id, subtype)
        "https://test-fe.cbu.uib.no/nels/pages/sbi/sbi.xhtml?ref=#{Base64.encode64([project_id, dataset_id, subtype].join('')).chomp("=\n")}"
      end

      def sample_metadata(reference)
        File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'FASTQPaired.xlsx'))
      end

      ## TODO: Adding new function to cover the needs for the new dataset
      def datasettypes
        JSON.parse '["MOCK_DATA","Microarray_Methylation_data","454_seq_data","AB_SOLiD_NGS_data","Track","test-lxx","fea","illumina-test-kp","xia-test-18-03","Illumina_seq_data","Sanger_seq_data","Molecular_Dynamics_data","Proteomics_data","Microarray_Gene_Expression_data","Illimuna seq data 2","hello","wei-test","xia-test-20-03"]'
      end      
      def create_dataset(project_id, datasettype, name, description)
        ## TODO: start job to send data
      end
      def upload_metadata(project_id, dataset_id, subtype_name, file_path)
        ## TODO: start job to send data
      end
    end
  end
end
