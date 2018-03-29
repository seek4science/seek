# Based on Relationship model from BioCatalogue codebase

# *****************************************************************************
# * BioCatalogue: app/models/relationship.rb
# * 
# * Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# * Institute (EMBL-EBI) and the University of Southampton
# * See license.txt for details
# *****************************************************************************


class Relationship < ActiveRecord::Base

  validates_presence_of :subject_id, :other_object_id
  
  belongs_to :subject , :polymorphic => true
  belongs_to :other_object, :polymorphic => true

  include Seek::Rdf::ReactToAssociatedChange
  update_rdf_on_change :subject


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
  def self.set_attributions(resource, attributions_from_params, predicate = Relationship::ATTRIBUTED_TO)
    # added this branching on .nil? because of the danger of loosing all attributions for a model (for example) if due to an incomplete post request attributions is nil
    # the former code interpreted a nil parameter as an empty list => remove all attributions from an asset
    unless attributions_from_params.nil?

      unless attributions_from_params.instance_of? Array
         received_attributions = (attributions_from_params.blank? ? [] : ActiveSupport::JSON.decode(attributions_from_params))
      else
         received_attributions = (attributions_from_params.blank? ? [] : attributions_from_params)
      end

      # build a more convenient hash structure with attribution parameters
      # (this will be classified by resource type)
      new_attributions = {}
      received_attributions.each do |a|
        new_attributions[a[0]] ||= []
        new_attributions[a[0]] << a[1]
      end

      # --- Perform the full synchronisation of attributions ---

      # first delete any old attributions that are no longer valid
      resource.relationships.each do |a|
        if (a.predicate==predicate) && !(new_attributions["#{a.other_object_type}"] && new_attributions["#{a.other_object_type}"].include?(a.other_object_id))
          a.mark_for_destruction
        end
      end

      # attributions don't have any attributes to update, hence proceed straight to the final phase -
      # add any remaining new attributions
      new_attributions.each do |attributable_type, attributable_ids|
        attributable_ids.uniq.each do |attributable_id|
          resource.relationships.where(predicate: predicate,
                                       other_object_type: attributable_type,
                                       other_object_id: attributable_id).first_or_initialize
        end
      end
    end
  end
end
