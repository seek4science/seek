module Seek
  module Ontologies
    module SuggestedType
      extend ActiveSupport::Concern
      included do
        alias_attribute :uuid, :uri
        acts_as_uniquely_identifiable

        belongs_to :contributor, :class_name => "Person"

        # link_from: where the new assay type link was initiated, e.g. new assay type link at assay creation page,--> link_from = "assays".
        #or from admin page --> manage assay types
        attr_accessor :term_type

        validates_presence_of :label, :uri
        validates_uniqueness_of :label, :uri
        validate :label_not_defined_in_ontology
        before_validation :default_parent
      end


      def default_parent_uri
        base_ontology_reader.default_parent_class_uri.try(:to_s)
      end

      def label_not_defined_in_ontology
        errors[:base] << "#{self.humanize_term_type} type with label #{label} is already defined in ontology!" if self.class.base_ontology_labels.each(&:downcase).include?(label.downcase)
      end

      #parent with valid uri
      def ontology_parent term=self
        return nil if term.nil?
        rdf_uri = RDF::URI.new term.parent_uri
        rdf_uri.valid? ? term.parent : ontology_parent(term.parent)
      end

      def descriptive_label
        comment = " - this is a new suggested term that specialises #{ontology_parent.try(:label)}"
        (self.label + content_tag("span",comment,:class=>"none_text")).html_safe
      end

      # its own valid uri or its parent with valid uri
      def ontology_uri
        rdf_uri = RDF::URI.new uri
        return rdf_uri.valid? ? rdf_uri.to_s : ontology_parent.try(:uri).try(:to_s)
      end

      def humanize_term_type
        term_type.humanize.downcase if term_type
      end

      def destroy_errors
        return nil if can_destroy?
        error_messages = []
        type_name = humanize_term_type
        error_messages << "Unable to delete #{type_name} types with children." if !children.empty?
        error_messages << "Unable to delete #{type_name} type " \
                                          "due to reliance from #{assays.count} " \
                                          "existing #{type_name}." if !assays.empty?
        error_messages
      end

      def parents
        Array(parent)
      end

      def parent
        self.class.base_ontology_hash_by_uri[parent_uri] || self.class.where(:uri => parent_uri).first
      end

      # before adding to ontology ang assigned a uri, returns its parent_uri
      def default_parent
        if parent_uri.blank?
          raise Exception.new("#{self.class.name} #{label} has no default parent uri!") if default_parent_uri.blank?
          self.parent_uri = default_parent_uri
        end
      end

      def children
        self.class.where(:parent_uri => uri).all
      end

      def assays
        Assay.where(assay_uri_type_key => uri).all
      end

      def assay_uri_type_key
        key = self.class.name.tableize.gsub("suggested_","").singularize+"_uri"
        key.to_sym
      end

      def can_edit?
        contributor==User.current_user.try(:person) || User.admin_logged_in?
      end

      def can_destroy?
        auth = User.admin_logged_in?
        auth && assays.count == 0 && children.empty?
      end


      def get_child_assays suggested_type=self
        result = suggested_type.assays
        suggested_type.children.each do |child|
          result = result | child.assays
          result = result | get_child_assays(child) if !child.children.empty?
        end
        return result
      end
    end
  end
end

