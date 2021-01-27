class GitAnnotation < ApplicationRecord
  belongs_to :git_version
  belongs_to :contributor, class_name: 'Person'

  before_validation :assign_contributor

  def assign_contributor
    self.contributor ||= User.current_user&.person
  end
end
