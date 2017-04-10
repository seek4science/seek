module WorkGroupsHelper
  def work_group_select_choices
    WorkGroup.all.map { |wg| [wg.project.title + ' at ' + wg.institution.title, wg.id] }
  end

  WorkGroupOption = Struct.new(:id, :institution_name)

  class ProjectType
    attr_reader :project_name, :options, :project, :editable
    attr_writer :options
    def initialize(project, editable)
      @project = project
      @project_name = project.title
      @options = []
      @editable = editable
    end

    def <<(option)
      @options << option
    end
  end

  def work_group_groups_for_selection(person)
    options = []
    last_project = nil
    # if current_user is project manager and not admin, load work_groups of projects he is in
    if project_administrator_logged_in? && !admin_logged_in? && !Seek::Config.is_virtualliver
      work_groups = current_user.person.projects.collect(&:work_groups).flatten.uniq
    else
      work_groups = WorkGroup.includes(:project, :institution)
    end

    work_groups = work_groups.to_a.select { |wg| wg.project.can_be_administered_by?(current_user) }

    work_groups |= person.work_groups

    work_groups = work_groups.sort do |a, b|
      x = a.project.title <=> b.project.title
      x = a.institution.title <=> b.institution.title if x.zero?
      x
    end

    work_groups.each do |wg|
      if last_project.nil? || last_project.project != wg.project
        options << last_project unless last_project.nil?
        last_project = ProjectType.new(wg.project, wg.project.can_be_administered_by?(current_user))
      end
      last_project << WorkGroupOption.new(wg.id, wg.institution.title)
    end

    options << last_project unless last_project.nil?

    options
  end
end
