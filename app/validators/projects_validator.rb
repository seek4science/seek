class ProjectsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?
    return if record.contributor.nil?
    valid_projects = record.contributor.projects
    valid_projects += User.current_user.person.projects if User.current_user.try(:person)

    if options[:self]
      new_projects = record.project_additions
      return if (new_projects - valid_projects).empty? # Are all newly-associated projects part of the valid_projects set?
      record.errors[:base] << (options[:message] || 'Can only associate projects you are a member of.')
    else
      return if (value.projects - valid_projects).empty?
      record.errors[attribute] << (options[:message] || 'must be associated with one of your projects.')
    end
  end
end
