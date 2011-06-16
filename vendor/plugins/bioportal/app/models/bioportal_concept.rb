class BioportalConcept < ActiveRecord::Base
  include BioPortal::RestAPI

  belongs_to :conceptable,:polymorphic=>true

  before_save :check_cached_concept

  def get_concept options={}
    options[:refresh]||=false
    
    refresh=options.delete(:refresh)
    
    concept=nil
    concept = YAML::load(cached_concept_yaml) unless (refresh || cached_concept_yaml.nil?)
    unless concept      
      concept = super(self.ontology_version_id,self.concept_uri,options)      
      update_attribute(:cached_concept_yaml, concept.to_yaml)
    end
      
    concept
  end

  def get_ontology options={}
    get_ontology_details self.ontology_version_id,options
  end

  #the base url is defined by the associated class - this overrides the method in the RestAPI mixin
  def bioportal_base_rest_url
    conceptable.bioportal_base_rest_url
  end

  protected

  #invoked before_save, and if the ontology_id, ontology_version_id or concept_uri has changed then the cached concept will be cleared
  def check_cached_concept
    changed_fields = changes.keys
    
    if !(changed_fields & ["ontology_id","ontology_version_id","concept_uri"]).empty?
      self.cached_concept_yaml=nil
    end
  end
end
