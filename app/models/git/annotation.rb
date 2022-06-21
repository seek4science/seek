module Git
  class Annotation < ApplicationRecord
    belongs_to :git_version, inverse_of: :git_annotations, class_name: 'Git::Version'
    belongs_to :contributor, class_name: 'Person'

    before_validation :assign_contributor

    validates :key, uniqueness: { scope: [:git_version_id, :path, :value] }
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
end
