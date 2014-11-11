module Seek
  module Ontologies
    module SuggestedType
      extend ActiveSupport::Concern
      included do

        belongs_to :contributor, class_name: 'Person'
        belongs_to :parent, class_name: name

        attr_accessor :term_type

        validates_presence_of :label
        validates_uniqueness_of :label
        validate :label_not_defined_in_ontology
        validate :parent_cannot_be_self
      end

      def default_parent_uri
        base_ontology_reader.default_parent_class_uri.try(:to_s)
      end

      def label_not_defined_in_ontology
        errors[:base] << "#{humanize_term_type} type with label #{label} is already defined in ontology!" if label_exists_in_ontology?
      end

      def label_exists_in_ontology?
        ontology_readers.find do |reader|
          reader.label_exists?(label)
        end
      end

      def all_term_types
        ontology_readers.map do |reader|
          reader.ontology_term_type
        end
      end

      def parent_cannot_be_self
        errors[:base] << "#{humanize_term_type} type cannot define itself as a parent!" if parent == self
      end

      # the first parent that comes from the ontology
      def ontology_parent
        class_for_uri(ontology_uri)
      end

      def class_for_uri(uri)
        result = nil
        ontology_readers.detect do |reader|
          result = reader.class_for_uri(uri)
        end
        result
      end

      # traverse parents until an ontology_uri is found
      def ontology_uri
        super || self.class.find_by_id(parent_id).try(:ontology_uri)
      end

      def descriptive_label
        comment = " - this is a new suggested term that specialises #{ontology_parent.try(:label)}"
        (label + content_tag('span', comment, class: 'none_text')).html_safe
      end

      def humanize_term_type
        term_type.humanize.downcase if term_type
      end

      def destroy_errors
        return nil if can_destroy?
        error_messages = []
        type_name = humanize_term_type
        error_messages << "Unable to delete #{type_name} types with children." unless children.empty?
        error_messages << "Unable to delete #{type_name} type " \
                                          "due to reliance from #{assays.count} " \
                                          "existing #{type_name}." unless assays.empty?
        error_messages
      end

      # generated uri based on the id, e.g. suggested_assay_type:2
      def uri
        "#{uri_scheme}#{id}"
      end

      def parents
        Array(parent)
      end

      def parent
        super || ontology_parent
      end

      def children
        self.class.where('parent_id=? AND parent_id IS NOT NULL', id).all
      end

      def assays
        # FIXME: find a better way of getting the id foreign key
        Assay.where("#{self.class.table_name.singularize}_id" => id).all
      end

      def can_edit?
        contributor == User.current_user.try(:person) || User.admin_logged_in?
      end

      def can_destroy?
        User.admin_logged_in? && assays.empty? && children.empty?
      end

      def get_child_assays(suggested_type = self)
        result = suggested_type.assays
        suggested_type.children.each do |child|
          result = result | child.assays
          result = result | get_child_assays(child) unless child.children.empty?
        end
        result
      end

      def parent_uri=(uri)
        if uri
          if uri.start_with?(uri_scheme)
            self.parent_id = uri.gsub(uri_scheme, '').to_i
          else
            self.ontology_uri = uri
          end
        end
      end

      def uri_scheme
        "#{self.class.name.underscore}:"
      end

      def base_ontology_reader
        ontology_readers.detect do |reader|
          reader.ontology_term_type == @term_type
        end || ontology_readers[0]
      end
    end
  end
end
