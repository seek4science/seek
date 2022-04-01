class RoleType < ApplicationRecord
  has_many :roles
  has_many :people, through: :roles

  def self.system
    where(scope: nil)
  end

  def self.programme
    where(scope: 'Programme')
  end

  def self.project
    where(scope: 'Project')
  end
end
