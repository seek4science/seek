module Seek
  module Ontologies
    # Assay related tasks related to the assay and technology types that are read from an ontology
    module AssayOntologyTypes
      extend ActiveSupport::Concern

      included do
        belongs_to :suggested_assay_type
        belongs_to :suggested_technology_type
      end

      # provides either the label of a suggested type, or if missing the label from the ontology
      def assay_type_label
        suggested_assay_type.try(:label) || assay_type_reader.class_hierarchy.hash_by_uri[assay_type_uri].try(:label)
      end

      # provides either the label of a suggested type, or if missing the label from the ontology
      def technology_type_label
        suggested_technology_type.try(:label) || technology_type_reader.class_hierarchy.hash_by_uri[technology_type_uri].try(:label)
      end

      def assay_type_reader
        if is_modelling?
          Seek::Ontologies::ModellingAnalysisTypeReader.instance
        else
          Seek::Ontologies::AssayTypeReader.instance
        end
      end

      def technology_type_reader
        Seek::Ontologies::TechnologyTypeReader.instance
      end

      def assay_type_uri=(uri)
        suggested_type_uri_assignment(uri, 'assay_type') || super
      end

      def technology_type_uri=(uri)
        suggested_type_uri_assignment(uri, 'technology_type') || super
      end

      def suggested_type_uri_assignment(uri, type)
        suggested_key = "suggested_#{type}"
        if uri && uri.start_with?(suggested_key)
          id = uri.split(':')[1]
          suggested = suggested_key.classify.constantize.find(id)
          send("#{suggested_key}=", suggested)
          send("#{type}_uri=", suggested.ontology_uri)
          true
        else
          false
        end
      end

      def default_assay_and_technology_type
        self.use_default_assay_type_uri! unless assay_type_uri
        if is_modelling?
          self.technology_type_uri = nil
        else
          self.use_default_technology_type_uri! unless technology_type_uri
        end
      end

      def default_assay_type_uri
        assay_type_reader.default_parent_class_uri.try(:to_s)
      end

      def default_technology_type_uri
        technology_type_reader.default_parent_class_uri.try(:to_s)
      end

      def use_default_assay_type_uri!
        self.assay_type_uri = default_assay_type_uri
      end

      def use_default_technology_type_uri!
        if is_modelling?
          self.technology_type_uri = nil
        else
          self.technology_type_uri = default_technology_type_uri
        end
      end

      def valid_assay_type_uri?(uri = assay_type_uri)
        !assay_type_reader.class_hierarchy.hash_by_uri[uri].nil?
      end

      def valid_technology_type_uri?(uri = technology_type_uri)
        if is_modelling?
          uri.nil?
        else
          !technology_type_reader.class_hierarchy.hash_by_uri[uri].nil?
        end
      end

      # returns the label if it is an unrecognised suggested label, otherwise return nil
      def suggested_assay_type_label
        label = self[:assay_type_label]
        return nil unless label
        return label unless assay_type_reader.class_hierarchy.hash_by_label[label.downcase]
      end

      # returns the label if it is an unrecognised suggested label, otherwise return nil
      def suggested_technology_type_label
        label = self[:technology_type_label]
        return nil if self.is_modelling?
        return nil unless label
        return label unless technology_type_reader.class_hierarchy.hash_by_label[label.downcase]
      end
    end
  end
end
