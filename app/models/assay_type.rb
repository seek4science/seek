class AssayType < ActiveRecord::Base
  
  has_and_belongs_to_many :children, :class_name=>"AssayType",:join_table=>"assay_types_edges",:foreign_key=>"parent_id",:association_foreign_key=>"child_id"
  has_and_belongs_to_many :parents, :class_name=>"AssayType",:join_table=>"assay_types_edges",:foreign_key=>"child_id",:association_foreign_key=>"parent_id"

end
