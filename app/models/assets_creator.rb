class AssetsCreator < ActiveRecord::Base
  
  belongs_to :asset, :polymorphic => true
  belongs_to :creator, :class_name => 'Person'

  include Seek::Rdf::ReactToAssociatedChange
  update_rdf_on_change :asset
  
  def self.add_or_update_creator_list(resource, creator_params)
    recieved_creators = (creator_params.blank? ? [] : ActiveSupport::JSON.decode(creator_params)).uniq
    existing_creators = resource.creators
    
    recieved_creator_ids = recieved_creators.collect {|i| i[1]}
    
    existing_creator_ids = existing_creators.collect {|i| i.id}
    
    ids_to_add = recieved_creator_ids - existing_creator_ids
    ids_to_remove = existing_creator_ids - recieved_creator_ids
    
    #Remove any creators in the database but not in the list
    ids_to_remove.each do |i|
      assets_creators = resource.assets_creators.select{|ac| ac.creator_id==i}
      assets_creators.each do |ac|
        ac.destroy
        resource.creators.delete(ac.creator)
      end
    end
    
    #Add any new creators
    ids_to_add.each do |i|
      resource.creators << Person.find_by_id(i)
    end
  end

end
