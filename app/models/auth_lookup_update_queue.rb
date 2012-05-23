class AuthLookupUpdateQueue < ActiveRecord::Base
  belongs_to :item, :polymorphic=>:true

  def self.exists?(item)
    if item.nil?
      !AuthLookupUpdateQueue.find(:first,:conditions=>["item_id IS ? AND item_type IS ?",nil,nil]).nil?
    else
      !AuthLookupUpdateQueue.find(:first,:conditions=>{:item_id=>item.id,:item_type=>item.class.name}).nil?
    end

  end

end
