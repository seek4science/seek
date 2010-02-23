class AssayClass < ActiveRecord::Base
  has_many :assay_types
  has_many :technology_types
end
