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
    work_groups = if project_administrator_logged_in? && !admin_logged_in? && !Seek::Config.is_virtualliver
                    current_user.person.projects.collect(&:work_groups).flatten.uniq
                  else
                    WorkGroup.includes(:project, :institution)
                  end

    work_groups = work_groups.to_a.select { |wg| wg.project.can_manage?(current_user) }

    work_groups |= person.work_groups

    work_groups = work_groups.sort do |a, b|
      x = a.project.title <=> b.project.title
      x = a.institution.title <=> b.institution.title if x.zero?
      x
    end

    work_groups.each do |wg|
      if last_project.nil? || last_project.project != wg.project
        options << last_project unless last_project.nil?
        last_project = ProjectType.new(wg.project, wg.project.can_manage?(current_user))
      end
      last_project << WorkGroupOption.new(wg.id, wg.institution.title)
    end

    options << last_project unless last_project.nil?

    options
  end

  def membership_list(memberships)
    memberships.collect do |membership|
      membership_link(membership)
    end.join(' ; ').html_safe
  end

  def membership_link(membership)
    project_link = link_to(membership.work_group.project.title, membership.work_group.project)
    institution_link = link_to(membership.work_group.institution.title, membership.work_group.institution)
    "#{project_link} (<small>#{institution_link}</small>)".html_safe
  end
end
