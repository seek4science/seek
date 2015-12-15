require 'uuid'

class NotifieeInfo < ActiveRecord::Base
  belongs_to :notifiee,:polymorphic=>true
  validates_presence_of :notifiee
    
  
  before_save :check_unique_key
  
  private 
  
  def check_unique_key
    if self.unique_key.nil? || self.unique_key.blank?
      self.unique_key = UUID.generate
    end
  end    
  
end