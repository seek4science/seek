class Synonym < ActiveRecord::Base
  has_many :studied_factor_links, :as => :substance
  has_many :experimental_condition_links, :as => :substance
  belongs_to :substance, :polymorphic => true
  validates_presence_of :name, :substance
end

