
module Stu
  module Acts
    module Ontology
      
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_ontology
          has_and_belongs_to_many :children, :class_name=>self.class_name,:join_table=>"#{self.class_name.pluralize.underscore}_edges",:foreign_key=>"parent_id",:association_foreign_key=>"child_id"
          has_and_belongs_to_many :parents, :class_name=>self.class_name,:join_table=>"#{self.class_name.pluralize.underscore}_edges",:foreign_key=>"child_id",:association_foreign_key=>"parent_id"

          extend Stu::Acts::Ontology::SingletonMethods
          include Stu::Acts::Ontology::InstanceMethods
        end

      end

      module SingletonMethods

        def to_tree
          roots=[]
          all=self.find(:all,:include=>:parents)
          all.each do |o|
            roots << o if o.parents.empty?
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