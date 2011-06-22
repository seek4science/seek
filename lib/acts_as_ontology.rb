
module Stu
  module Acts
    module Ontology
      
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_ontology
          has_and_belongs_to_many :children, :class_name=>self.name,:join_table=>"#{self.name.pluralize.underscore}_edges",:foreign_key=>"parent_id",:association_foreign_key=>"child_id"
          has_and_belongs_to_many :parents, :class_name=>self.name,:join_table=>"#{self.name.pluralize.underscore}_edges",:foreign_key=>"child_id",:association_foreign_key=>"parent_id"

          extend Stu::Acts::Ontology::SingletonMethods
          include Stu::Acts::Ontology::InstanceMethods
        end
      end

      module SingletonMethods
        def to_tree root_id=nil
          roots=[]
          if (root_id)
            roots << self.find(root_id)
          else            
            all=self.find(:all,:include=>:parents)
            all.each do |o|
              roots << o if o.parents.empty?
            end
          end          
          return roots
        end
      end

      module InstanceMethods
        def has_children?
          return !children.empty?
        end

        def has_parents?
          return !parents.empty?
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Stu::Acts::Ontology
end