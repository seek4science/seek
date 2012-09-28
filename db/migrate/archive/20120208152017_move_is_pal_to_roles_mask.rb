class MoveIsPalToRolesMask < ActiveRecord::Migration
  class Person < ActiveRecord::Base
      ROLES = %w[admin pal]

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
      Person.find(:all, :conditions => ['is_pal=?', true]).each do |person|
        person.add_roles ['pal']
        person.save!
      end
    end

    def self.down
      Person.find(:all, :conditions => ['is_pal=?', true]).each do |person|
        person.remove_roles ['pal']
        person.save!
      end
    end
  end
