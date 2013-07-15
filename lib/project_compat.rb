module ProjectCompat
  def self.included(klass)
    klass.class_eval do
      join_table_name = [table_name, 'projects'].sort.join('_')
      has_and_belongs_to_many :projects, :join_table => "#{join_table_name}",
                              :before_add => :react_to_project_addition ,
                              :before_remove => :react_to_project_removal


    end
  end

  def react_to_project_addition project
    SetSubscriptionsForItemJob.create_job(self.class.name, self.id, [project.id]) if (!self.new_record? && self.subscribable?)
    self.update_rdf_on_associated_change(project) if self.respond_to?(:update_rdf_on_associated_change)
  end

  def react_to_project_removal project
    RemoveSubscriptionsForItemJob.create_job(self.class.name, self.id, [project.id]) if self.subscribable?
    self.create_rdf_generation_job(true) if self.respond_to?(:create_rdf_generation_job)
  end
end