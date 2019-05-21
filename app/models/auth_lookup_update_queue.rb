class AuthLookupUpdateQueue < ApplicationRecord
  belongs_to :item, :polymorphic=>:true

  def self.exists?(item)
    if item.nil?
      !AuthLookupUpdateQueue.where(["item_id IS ? AND item_type IS ?",nil,nil]).first.nil?
    else
      !AuthLookupUpdateQueue.where(:item_id=>item.id,:item_type=>item.class.name).first.nil?
    end

  end

end
