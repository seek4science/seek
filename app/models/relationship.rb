# Based on Relationship model from BioCatalogue codebase

# *****************************************************************************
# * BioCatalogue: app/models/relationship.rb
# * 
# * Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# * Institute (EMBL-EBI) and the University of Southampton
# * See license.txt for details
# *****************************************************************************


class Relationship < ActiveRecord::Base
  validates_presence_of :subject_id, :object_id
  
  belongs_to :subject , :polymorphic => true
  belongs_to :object, :polymorphic => true
  
  
  # **********************************************************************
  # A set of constants to define the predicates which are currently in use
  
  ATTRIBUTED_TO = "attributed_to"
  CREDITED_FOR = "credited_for"
  RELATED_TO_PUBLICATION = "related_to_publication"
  
  # **********************************************************************
  
  
  # this method is to be invoked on create / update of resources to create OR
  # synchronise any attributions that should be attached to the resource;
  # it will make sure that if some attributions are to have the same data as
  # before, then these will not get deleted (and re-created afterwards, but
  # will be kept intact in first place)
  def self.create_or_update_attributions(resource, attributions_from_params, predicate = Relationship::ATTRIBUTED_TO)
    unless attributions_from_params.instance_of? Array
       received_attributions = (attributions_from_params.blank? ? [] : ActiveSupport::JSON.decode(attributions_from_params))
    else
       received_attributions = (attributions_from_params.blank? ? [] : attributions_from_params)
    end

    # build a more convenient hash structure with attribution parameters
    # (this will be classified by resource type)
    new_attributions = {}
    received_attributions.each do |a|
      new_attributions[a[0]] = [] unless new_attributions[a[0]]
      new_attributions[a[0]] << a[1]
    end

    # --- Perform the full synchronisation of attributions ---
    
    # first delete any old attributions that are no longer valid
    changes_made = false
    resource.relationships.each do |a|
      if (a.predicate==predicate) && !(new_attributions["#{a.object_type}"] && new_attributions["#{a.object_type}"].include?(a.object_id))
        a.destroy
        changes_made = true
      end
    end
    # this is required to leave the association of "resource" with its attributions in the correct state; otherwise exception is thrown
    resource.reload if changes_made
    
    # attributions don't have any attributes to update, hence proceed straight to the final phase -
    # add any remaining new attributions
    new_attributions.each_key do |attributable_type|
      new_attributions["#{attributable_type}"].each do |attributable_id|
        unless (found = Relationship.find(:first, :conditions => { :subject_type => resource.class.name, :subject_id => resource.id, :predicate => Relationship::ATTRIBUTED_TO, :object_type => attributable_type, :object_id => attributable_id }))
          Relationship.create(:subject_type => resource.class.name, :subject_id => resource.id, :predicate => predicate, :object_type => attributable_type, :object_id => attributable_id)
        end
      end
    end
    
    # --- Synchronisation is Finished ---
    
  end
end
