module ProjectCompat
  def self.included(klass)
    klass.class_eval do
      join_table_name = [table_name, 'projects'].sort.join('_')
      has_and_belongs_to_many :projects, :join_table => "#{join_table_name}",
                              :before_add => Proc.new{|item,project| SetSubscriptionsForItemJob.create_job(item.class.name, item.id, [project.id]) if (!item.new_record? && item.subscribable?)},
                              :before_remove => Proc.new{|item,project| RemoveSubscriptionsForItemJob.create_job(item.class.name, item.id, [project.id]) if item.subscribable?}
      if Project.is_hierarchical?
          def projects_and_ancestors
            self.projects.collect { |proj| [proj]+proj.ancestors }.flatten.uniq
          end

          def projects_and_descendants
            self.projects.collect { |proj| [proj]+proj.descendants }.flatten.uniq
          end
      end
    end
  end
end