module Seek
  module Roles

    ROLES = %w[admin pal project_manager asset_manager gatekeeper]
    ROLES_MASK_FOR_ADMIN = 2**ROLES.index('admin')
    ROLES_MASK_FOR_PAL = 2**ROLES.index('pal')
    ROLES_MASK_FOR_PROJECT_MANAGER = 2**ROLES.index('project_manager')

    def self.included(mod)
      mod.extend(ClassMethods)
      ROLES.each do |role|
        eval <<-END_EVAL
            def is_#{role}?
              roles.include?('#{role}')
            end

            def is_#{role}
              roles.include?('#{role}')
            end

            def is_#{role}=(yes)
              if yes
                add_roles ['#{role}']
              else
                remove_roles ['#{role}']
              end
            end
        END_EVAL
      end
    end

    module ClassMethods
      ROLES.each do |role|
        eval <<-END_EVAL
          def #{role}s
            self.all.select(&:is_#{role}?)
          end
        END_EVAL
      end
    end

    #the roles defined within SEEK
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

    def is_gatekeeper_of? item
      is_gatekeeper? && !(item.projects & projects).empty?
    end

    def is_asset_manager_of? item
      is_asset_manager? && !(item.projects & projects).empty?
    end

  end
end