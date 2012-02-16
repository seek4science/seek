class ProjectFolder < ActiveRecord::Base
  belongs_to :project
  belongs_to :parent,:class_name=>"ProjectFolder",:foreign_key=>:parent_id
  has_many :children,:class_name=>"ProjectFolder",:foreign_key=>:parent_id, :after_add=>:update_child

  validates_presence_of :project,:title

  def update_child child
    child.project = project
    child.parent = self
  end

end
