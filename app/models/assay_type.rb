class AssayType < ActiveRecord::Base
  belongs_to :parent_assay_type, :class_name=>"AssayType"
  has_many :child_assay_types, :class_name=>"AssayType",:foreign_key=>"parent_assay_type_id"
end
