module Seek
  module ProjectAssociation
    def self.included(klass)
      klass.class_eval do

        @project_join_table ||= [table_name, 'projects'].sort.join('_')
        has_and_belongs_to_many :projects, join_table: @project_join_table,
                                           before_add: :react_to_project_addition,
                                           before_remove: :react_to_project_removal
        has_many :programmes, ->{ distinct }, through: :projects
        has_filter :project, :programme

        after_save -> { @project_additions = [] }

        validates :projects, presence: true, unless: proc { |object| object.is_a?(Strain) }

        def project_additions
          @project_additions ||= []
          @project_additions
        end

        def react_to_project_addition(project)
          project_additions << project
          SetSubscriptionsForItemJob.new(self, [project]).queue_job if persisted? && subscribable?
          update_rdf_on_associated_change(project) if self.respond_to?(:update_rdf_on_associated_change)
        end

        def react_to_project_removal(project)
          RemoveSubscriptionsForItemJob.new(self, [project]).queue_job if persisted? && subscribable?
          queue_rdf_generation(true) if self.respond_to?(:queue_rdf_generation)
        end

        def self.project_join_table
          @project_join_table
        end

        def self.filter_by_projects(projects)
          joins(:projects).where(project_join_table => { project_id: projects }).distinct
        end
      end
    end
  end
end
