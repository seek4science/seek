class ProjectsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?
    return if record.contributor.nil?
    return if (value.projects - record.contributor.person.projects).empty?
    record.errors[attribute] << (options[:message] || 'must be associated with one of your projects.')
  end
end
