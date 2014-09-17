
class SuggestedAssayType < ActiveRecord::Base

  include Seek::Ontologies::SuggestedType

  def base_ontology_reader
     if @term_type == Seek::Ontologies::ModellingAnalysisTypeReader.instance.ontology_term_type
       Seek::Ontologies::ModellingAnalysisTypeReader.instance
     elsif @term_type.nil? || @term_type == Seek::Ontologies::AssayTypeReader.instance.ontology_term_type
       Seek::Ontologies::AssayTypeReader.instance
     end
  end


  def self.base_ontology_hash_by_label
    @base_hash_by_label ||= begin
      assay_type_hash = Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_label
      modelling_analysis_hash = Seek::Ontologies::ModellingAnalysisTypeReader.instance.class_hierarchy.hash_by_label
      assay_type_hash.merge modelling_analysis_hash
    end
  end

  def self.base_ontology_hash_by_uri
      @base_hash_by_uri ||= begin
        assay_type_hash = Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_uri
        modelling_analysis_hash = Seek::Ontologies::ModellingAnalysisTypeReader.instance.class_hierarchy.hash_by_uri
        assay_type_hash.merge modelling_analysis_hash
      end
  end

   def self.base_ontology_labels
       base_ontology_hash_by_label.keys
   end



  def self.all_term_types
    assay_type = Seek::Ontologies::AssayTypeReader.instance.ontology_term_type
    modelling_analysis_type = Seek::Ontologies::ModellingAnalysisTypeReader.instance.ontology_term_type
    [assay_type, modelling_analysis_type]
  end

  def term_type
    @term_type ||= ontology_parent.try(:term_type)
  end



  def self.uri_key_in_assay
      "assay_type_uri"
  end
end
  

