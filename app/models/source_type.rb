class SourceType < ApplicationRecord
  # belongs_to :source_attributes
  has_many :source_attributes, :dependent => :destroy
end
