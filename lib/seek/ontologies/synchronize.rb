require 'colorize'
module Seek
  module Ontologies
    class Synchronize

      def initialize
        puts "clearing caches"
        Rails.cache.clear
      end

      def synchronize_technology_types
        synchronize_types "technology_type"
      end

      def synchronize_assay_types
        synchronize_types "assay_type"
      end

      #private

      def synchronize_types type

        Assay.record_timestamps = false

        #check for label in ontology
        found_suggested_types = get_suggested_types_found_in_ontology(type)

        puts "matching suggested #{type.pluralize} found in ontology: #{found_suggested_types.collect(&:label).join(", ")}"

        replace_suggested_types_with_ontology(found_suggested_types, type)

        update_assay_with_obselete_uris(type)

        Assay.record_timestamps = true

        nil
      end

      def update_assay_with_obselete_uris(type)
        assays_for_update = Assay.all.select do |assay|
          !assay.send("valid_#{type}_uri?")
        end

        #check all assay uri-s, for those that don't exist in ontology. This is unusual and uris shouldn't be removed
        #revert to top level uri - print warning
        puts "#{assays_for_update.count} assays found where the assay type no longer exists in the ontology"
        disable_authorization_checks do
          assays_for_update.each do |assay|
            assay.send("use_default_#{type}_uri!")
            assay.save
          end
        end
      end

      def replace_suggested_types_with_ontology(found_suggested_types, type)
        label_hash = type_labels_and_uri(type)
        disable_authorization_checks do
          found_suggested_types.each do |suggested_type|
            uri = label_hash[suggested_type.label.downcase]
            Assay.where("suggested_#{type}_id" => suggested_type.id).each do |assay|
              puts "updating assay: #{assay.id} with the new #{type} uri #{uri}"
              assay.send("#{type}_uri=", uri)
              assay.save
            end
            puts "destroying suggested type #{suggested_type.id} with label #{suggested_type.label}"
            suggested_type.destroy
          end
        end
      end

      def get_suggested_types_found_in_ontology(type)
        label_hash = type_labels_and_uri(type)

        found_suggested_types = get_types(type).select do |suggested_type|
          label_hash[suggested_type.label.downcase]
        end
      end

      def get_types(suffix)
        "suggested_#{suffix}".classify.constantize.all
      end

      def type_labels_and_uri type
        if type=="assay_type"
          hash = Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_label
          hash.merge!(Seek::Ontologies::ModellingAnalysisTypeReader.instance.class_hierarchy.hash_by_label)
        else
          hash = Seek::Ontologies::TechnologyTypeReader.instance.class_hierarchy.hash_by_label
        end

        #remove_suggested
        Hash[ hash.map do |k,v|
          [k,v.uri.to_s]
        end ]
      end

    end
  end

end