class GitAnnotation < ApplicationRecord
  belongs_to :git_version, inverse_of: :git_annotations
  belongs_to :contributor, class_name: 'Person'

  before_validation :assign_contributor
  validate :check_valid_path

  def assign_contributor
    self.contributor ||= User.current_user&.person
  end

  def check_valid_path
    unless git_version.file_exists?(path)
      errors.add(:path, 'not found in repository')
    end
  end
end
