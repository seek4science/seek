module Seek
  module Ontologies
    module SuggestedType
      extend ActiveSupport::Concern
      included do

        belongs_to :contributor, :class_name => "Person"
        belongs_to :parent,:class_name=>self.name

        # link_from: where the new assay type link was initiated, e.g. new assay type link at assay creation page,--> link_from = "assays".
        #or from admin page --> manage assay types
        attr_accessor :term_type

        validates_presence_of :label
        validates_uniqueness_of :label
        validate :label_not_defined_in_ontology
        before_validation :default_parent
      end

      def default_parent_uri
        base_ontology_reader.default_parent_class_uri.try(:to_s)
      end

      def label_not_defined_in_ontology
        errors[:base] << "#{self.humanize_term_type} type with label #{label} is already defined in ontology!" if self.class.base_ontology_labels.each(&:downcase).include?(label.downcase)
      end

      #the first parent that comes from the ontology
      def ontology_parent
        self.class.base_ontology_hash_by_uri[ontology_uri]
      end

      def descriptive_label
        comment = " - this is a new suggested term that specialises #{ontology_parent.try(:label)}"
        (self.label + content_tag("span",comment,:class=>"none_text")).html_safe
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
        super || ontology_parent
      end

      # before adding to ontology ang assigned a uri, returns its parent_uri
      def default_parent
        if ontology_uri.blank?
          raise Exception.new("#{self.class.name} #{label} has no default parent uri!") if default_parent_uri.blank?
          self.ontology_uri = default_parent_uri
        end
      end

      def children
        self.class.where(:parent_id => id).all
      end

      def assays
        #FIXME: find a better way of getting the id foreign key
        Assay.where("#{SuggestedAssayType.table_name.singularize}_id"=>id).all
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
          result = result | get_child_assays(child) unless child.children.empty?
        end
        return result
      end
    end
  end
end

