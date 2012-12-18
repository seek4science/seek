class AssetsCreator < ActiveRecord::Base
  
  belongs_to :asset, :polymorphic => true
  belongs_to :creator, :class_name => 'Person'
  
  def self.add_or_update_creator_list(resource, creator_params)
    # added this branching on .nil? because of the danger of loosing all creators for a model (for example) if due to an incomplete post request creator_params is nil
    # the former code interpreted a nil parameter as an empty list => remove all creators from an asset
    unless creator_params.nil?
      received_creators = (creator_params.blank? ? [] : ActiveSupport::JSON.decode(creator_params)).uniq
      existing_creators = resource.creators

      received_creator_ids = received_creators.collect {|i| i[1]}

      existing_creator_ids = existing_creators.collect {|i| i.id}

      ids_to_add = received_creator_ids - existing_creator_ids
      ids_to_remove = existing_creator_ids - received_creator_ids

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
    end

    #resource.reload if changes_made
  end
end
