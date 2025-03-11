module Seek
  module FairDataStation
    class Sample < Base
      alias assays children

      def child_class
        Seek::FairDataStation::Assay
      end

      def seek_attributes
        super.except(:title, :description)
      end

      def detect_sample_type
        property_ids = additional_metadata_annotations.collect { |annotation| annotation[0] }
        # group sample_type_ids by the number of matching attributes
        groups = SampleAttribute.select(:sample_type_id).where(pid: property_ids).group(:sample_type_id).count

        #pick those with the max number of matches
        max = groups.values.max
        sample_type_ids = groups.filter {|id, matches| matches == max}.keys

        # pick the candidate that has the least number of mismatched attributes
        candidates = sample_type_ids.collect do |sample_type_id|
          sample_type = SampleType.find(sample_type_id)
          ids = sample_type.sample_attributes.collect(&:pid)
          score = (ids - property_ids).length
          [score, sample_type]
        end.sort_by { |x| x[0] }

        candidates.first&.last
      end

      def populate_seek_sample(seek_sample)
        sample_type = seek_sample.sample_type
        data = {}
        additional_metadata_annotations.each do |annotation|
          property = annotation[0]
          value = annotation[1]
          attribute = sample_type.sample_attributes.where(pid: property).first
          data[attribute.title] = value if attribute
        end
        data['Title'] = title
        data['Description'] = description
        seek_sample.data = data
      end

      def rdf_type_uri
        'http://jermontology.org/ontology/JERMOntology#Sample'
      end
    end
  end
end
