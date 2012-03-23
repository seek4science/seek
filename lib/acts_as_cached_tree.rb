module ActsAsCachedTree
  def self.included klass
    klass.class_eval do
      acts_as_tree

      alias_method :calculate_ancestors, :ancestors
      has_and_belongs_to_many :descendants, :class_name=>self.name, :join_table=>"#{self.name.underscore}_descendants", :foreign_key=>"ancestor_id", :association_foreign_key=>"descendant_id"
      has_and_belongs_to_many :ancestors, :class_name=>self.name, :join_table=>"#{self.name.underscore}_descendants", :foreign_key=>"descendant_id", :association_foreign_key=>"ancestor_id"

      before_save :update_descendants_cache

      include InstanceMethods

    end
  end

  def update_descendants_cache
    disable_authorization_checks do
      if new_record?
        if parent_id
          self.ancestors = self.calculate_ancestors
        end
      else
        if parent_id_changed?
          ([self] + self.descendants).each {|obj| obj.ancestors = obj.calculate_ancestors}
        end
      end
    end
  end


  module InstanceMethods
    def has_children?
      return !children.empty?
    end
  end
end
