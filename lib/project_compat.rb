module ProjectCompat
  def self.included(klass)
    klass.class_eval do
      attr_accessor :project

      join_table_name = [table_name, 'projects'].sort.join('_')
      has_and_belongs_to_many :projects, :join_table => "#{join_table_name}", :after_add => proc { |item, proj| item.update_project_attribute }, :after_remove => proc { |item, proj| item.update_project_attribute }

      after_initialize :set_project

      #this is done after saving, because belongs_to doesn't update the database unless save succeeds.
      #has_many will update the database as soon as projects= is called.
      before_save :update_projects_if_project_changed
    end
  end


    def update_projects_if_project_changed
      self.projects = projects_with_possible_fake_update
    end

    def projects_with_possible_fake_update
      if project == projects.first
        projects
      else
        [project].compact
      end
    end

    def project_id
      project.try :id
    end

    def project_id=(pid)
      self.project = Project.find(pid) unless pid.blank?
    end

    def update_project_attribute
      self.project = self.projects.first
    end

    def set_project
      self.project = self.projects.first unless self.project
    end
end