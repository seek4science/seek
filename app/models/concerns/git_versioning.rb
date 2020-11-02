module GitVersioning
  extend ActiveSupport::Concern

  included do
    has_many :git_versions, class_name: '::Version', as: :resource, dependent: :destroy
    has_one :git_repository, as: :resource
  end

  def latest_git_version
    git_versions.last
  end

  delegate :git_base, :file_contents, :object, :commit, :tree, :trees,:blobs, to: :latest_git_version
end
