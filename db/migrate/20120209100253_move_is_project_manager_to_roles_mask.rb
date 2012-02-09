class MoveIsProjectManagerToRolesMask < ActiveRecord::Migration
  class Person < ActiveRecord::Base
      ROLES = %w[admin pal project_manager]

      def roles=(roles)
        self.roles_mask = (roles & ROLES).map { |r| 2**ROLES.index(r) }.sum
      end

      def roles
        ROLES.reject do |r|
          ((roles_mask || 0) & 2**ROLES.index(r)).zero?
        end
      end

      def add_roles roles
        add_roles = roles - (roles & self.roles)
        self.roles_mask = self.roles_mask.to_i + ((add_roles & ROLES).map { |r| 2**ROLES.index(r) }.sum)
      end

      def remove_roles roles
        remove_roles = roles & self.roles
        self.roles_mask = self.roles_mask.to_i - ((remove_roles & ROLES).map { |r| 2**ROLES.index(r) }.sum)
      end
    end

    def self.up
      Person.find(:all, :conditions => ['is_project_manager=?', true]).each do |person|
        person.add_roles ['project_manager']
        person.save!
      end
    end

    def self.down
      Person.find(:all, :conditions => ['is_project_manager=?', true]).each do |person|
        person.remove_roles ['project_manager']
        person.save!
      end
    end
end
