class OtherProjectFile < ApplicationRecord
  has_and_belongs_to_many :projects
  belongs_to :default_project_folders
end
