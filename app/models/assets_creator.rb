class AssetsCreator < ActiveRecord::Base
  
  belongs_to :asset, :polymorphic => true
  belongs_to :creator, :class_name => 'Person'
  
  def self.add_or_update_creator_list(resource, creator_params)
    recieved_creators = (creator_params.blank? ? [] : ActiveSupport::JSON.decode(creator_params)).uniq
    existing_creators = resource.creators
    
    recieved_creator_ids = recieved_creators.collect {|i| i[1]}
    
    existing_creator_ids = existing_creators.collect {|i| i.id}
    
    ids_to_add = recieved_creator_ids - existing_creator_ids
    ids_to_remove = existing_creator_ids - recieved_creator_ids
    
    #changes_made = false
    
    #Remove any creators in the database but not in the list
    ids_to_remove.each do |i|
      #Get the Person object to remove. (this is much faster than doing find_by_id)
      creator_to_remove = existing_creators.select {|a| a.id == i}.first
      resource.creators.delete(creator_to_remove)
      #changes_made = true
    end
    
    #Add any new creators
    ids_to_add.each do |i|
      resource.creators << Person.find_by_id(i)
      #changes_made = true
    end

    #resource.reload if changes_made
  end
end
