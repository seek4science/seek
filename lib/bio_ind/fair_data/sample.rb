module BioInd
  module FairData
    class Sample < Base
      alias assays children

      def child_class
        BioInd::FairData::Assay
      end

      def populate_seek_sample(seek_sample)
        sample_type = seek_sample.sample_type
        data = {}
        additional_metadata_annotations.each do |annotation|
          property = annotation[0]
          value = annotation[1]
          attribute = sample_type.sample_attributes.where(pid: property).first
          if attribute
            data[attribute.title] = value
          end
        end
        seek_sample.data = data
      end
    end
  end
end
