class ProjectsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?
    return if record.contributor.nil?
    if options[:self]
      return if (value - record.contributor.projects).empty?
      record.errors[:base] << (options[:message] || 'Can only associate projects you are a member of.')
    else
      return if (value.projects - record.contributor.projects).empty?
      record.errors[attribute] << (options[:message] || 'must be associated with one of your projects.')
    end
  end
end
