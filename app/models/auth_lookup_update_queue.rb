class AuthLookupUpdateQueue < ActiveRecord::Base
  belongs_to :item, :polymorphic=>:true

  def self.exists?(item)
    !AuthLookupUpdateQueue.find(:first,:conditions=>{:item_id=>item.id,:item_type=>item.class.name}).nil?
  end

end
