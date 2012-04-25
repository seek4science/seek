class AuthLookupUpdateQueue < ActiveRecord::Base
  belongs_to :item, :polymorphic=>:true

  def self.exists?(item)
    !AuthLookupUpdateQueue.find(:first,:conditions=>{:item=>item}).nil?
  end

end
