class Asset < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  belongs_to :resource, :polymorphic => true
  belongs_to :project
  
  belongs_to :policy

  # TODO
  # add all required validations here

  # checks if c_utor is the owner of this asset
  def owner?(c_utor)
    case self.contributor_type
      when "User"
        return (self.contributor_id == c_utor.id && self.contributor_type == c_utor.class.name)
      # TODO some new types of "contributors" may be added at some point - this is to cater for that in future
      # when "Network"
      #   return self.contributor.owner?(c_utor.id) if self.contributor_type.to_s
    else
      # unknown type of contributor - definitely not the owner 
      return false
    end
  end
end
