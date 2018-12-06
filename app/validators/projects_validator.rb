# This validator is to ensure resources are only connected to appropriate projects.
# "Appropriate projects" in this case, is the current user's projects + the original contributor's projects.
#
# It operates in two modes:
# 1. Validating a record's association is part of a related project.
#    For example, when creating a Study, making sure the Study's investigation is owned by ONE OF the current user's projects.
#
#         validates :investigation, projects: true
#
# 2. Validating a record's project associations directly.
#    For example, when creating an Investigation, making sure ALL Investigation's projects involve the current user.
#
#         validates :projects, projects: { self: true }
#
#    Note: In this mode, on update, only the NEWLY ADDED projects are validated
#
class ProjectsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if $authorization_checks_disabled
    return if value.nil?
    return if record.contributor.nil?
    # For new resources, only allow the contributor's CURRENT projects.
    # For updating existing resources, also allow former projects, otherwise projects will be unable to manage former members' resources.
    valid_projects = record.new_record? ? record.contributor.current_projects : record.contributor.projects
    valid_projects |= User.current_user.person.current_projects if User.current_user.try(:person)

    if options[:self]
      new_projects = record.project_additions
      return if (new_projects - valid_projects).empty? # Are ALL newly-associated projects part of the valid_projects set?
      record.errors[:base] << (options[:message] || 'Can only associate projects that you are an active member of.')
    else
      return unless (value.projects & valid_projects).empty? # Does the associated item belong to ANY of the valid_projects?
      record.errors[attribute] << (options[:message] || 'must be associated with one of your projects.')
    end
  end
end
