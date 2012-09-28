class PublicationAuthorOrder < ActiveRecord::Base
  belongs_to :publication
  belongs_to :author, :polymorphic => true
  validates_presence_of :publication
  validates_presence_of :order
end
