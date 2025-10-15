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

      def find_closest_matching_sample_type(person, property_ids = additional_metadata_annotations.collect { |annotation| annotation[0] })
        candidates = SampleType.includes(:sample_attributes).authorized_for(:view, person).collect do |sample_type|
          sample_type_property_ids = sample_type.sample_attributes.collect(&:pid).compact_blank
          intersection = (property_ids & sample_type_property_ids)
          difference = (property_ids | sample_type_property_ids) - intersection
          emt = nil if intersection.empty?
          [intersection.length, difference.length, sample_type]
        end.sort_by do |x|
          # order by the number of properties matched coming top, but downgraded by the number of differences
          [-x[0], x[1]]
        end

        candidates.first&.last
      end

      def find_exact_matching_sample_type(person)
        property_ids = all_additional_potential_annotation_predicates
        property_ids |= [@schema.title.to_s, @schema.description.to_s]
        sample_type = find_closest_matching_sample_type(person, property_ids)
        return unless sample_type && sample_type.sample_attributes.count == property_ids.count

        sample_type
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
