module BioInd
  module FairData
    class DataSet < Base

      def title
        "Dataset: #{identifier}"
      end

      def content_url
        find_annotation_value(@schema.contentUrl.to_s) || resource_uri
      end

    end
  end
end
