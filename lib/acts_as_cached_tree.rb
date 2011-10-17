module ActsAsCachedTree
  module CacheTree

    def self.included klass
      klass.class_eval do
        acts_as_tree

        has_and_belongs_to_many :descendants, :class_name=>self.name, :join_table=>"#{self.name.underscore}_descendants", :foreign_key=>"ancestor_id", :association_foreign_key=>"descendant_id"
        has_and_belongs_to_many :saved_ancestors, :class_name=>self.name, :join_table=>"#{self.name.underscore}_descendants", :foreign_key=>"descendant_id", :association_foreign_key=>"ancestor_id"

        #validates_presence_of :parent_id ,:message=>"project is required to be selected" if self.root

        attr_accessor :old_parent_id
        before_save { |record| record.update_descendants(record.old_parent_id, record.parent_id) }

        include InstanceMethods
      end
    end

    def update_descendants old_parent_id, new_parent_id

      if new_record?
        if root and new_parent_id
          self.saved_ancestors = self.ancestors
        end
      else
        unless new_parent_id == old_parent_id
          ([self] + self.descendants).each {|obj|obj.saved_ancestors = obj.ancestors}
        end
      end
    end


    module InstanceMethods
      def has_children?
        return !children.empty?
      end
    end

  end

end
