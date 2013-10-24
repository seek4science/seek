module Seek
  module Roles

    ROLES = %w[admin pal project_manager asset_manager gatekeeper]
    PROJECT_DEPENDENT_ROLES = %w[pal project_manager asset_manager gatekeeper]

    def self.included(base)
      raise "Only People can have roles" unless base==Person

      base.extend(ClassMethods)
      ROLES.each do |role|
        eval <<-END_EVAL
            def is_#{role}?(project=nil)
              role_names.include?('#{role}') && roles(project).include?('#{role}')
            end

            def is_#{role}=(flag_and_project)
              flag_and_project = Array(flag_and_project)
              flag = flag_and_project[0]
              projects = flag_and_project[1]
              if flag
                add_roles [['#{role}',projects]]
              else
                remove_roles [['#{role}',projects]]
              end
            end
        END_EVAL
      end
      base.class_eval do
        requires_can_manage :roles_mask
        has_many :admin_defined_role_projects
      end

    end

    module ClassMethods

      def is_project_dependent_role? role
        PROJECT_DEPENDENT_ROLES.include?(role)
      end

      def mask_for_role(role)
        2**ROLES.index(role)
      end

      ROLES.each do |role|
        eval <<-END_EVAL
          def #{role}s
            self.all.select(&:is_#{role}?)
          end
          def mask_for_#{role}
            self.mask_for_role('#{role}')
          end
        END_EVAL
      end
    end

    def mask_for_role(role)
      self.class.mask_for_role(role)
    end


    def roles=(roles)
      #TODO a bit heavy handed, but works for the moment
      self.roles_mask=0
      self.admin_defined_role_projects.destroy_all

      add_roles(roles)
    end

    #fetch the roles assigned for this project
    def roles(project=nil)
      project_id = (project.is_a?(Project)) ? project.id : project.to_i
      role_names.select do |role_name|
        if self.class.is_project_dependent_role?(role_name)
          if project_id.nil?
            false
          else
            mask = mask_for_role(role_name)
            !self.admin_defined_role_projects.where(project_id: project_id,role_mask: mask).empty?
          end
        else
          true
        end
      end
    end

    def role_names
      ROLES.reject do |r|
        ((roles_mask || 0) & mask_for_role(r)).zero?
      end
    end

    #adds roles for projects, roles is an array, and each element is an array containing the role name and project(s)
    def add_roles roles
      new_mask = self.roles_mask || 0
      roles.each do |role_details|
        rolename = role_details[0]
        project_ids = Array(role_details[1]).collect{|p| p.is_a?(Project) ? p.id : p.to_i}
        mask = mask_for_role(rolename)
        if self.class.is_project_dependent_role?(rolename)
          current_projects_ids = self.admin_defined_role_projects.where(role_mask: mask).collect{|r|r.project.id}

          (project_ids - current_projects_ids).each do |project_id|
            self.admin_defined_role_projects << AdminDefinedRoleProject.new(project_id: project_id, role_mask: mask)
          end
        end
        new_mask += mask if (new_mask & mask).zero?
      end
      self.roles_mask = new_mask
    end

    def remove_roles roles
      new_mask = self.roles_mask
      roles.each do |role_details|
        rolename = role_details[0]
        project_ids = Array(role_details[1]).collect{|p| p.is_a?(Project) ? p.id : p.to_i}
        mask = mask_for_role(rolename)
        if self.class.is_project_dependent_role?(rolename)
          current_projects_ids = self.admin_defined_role_projects.where(role_mask: mask).collect{|r|r.project.id}
          project_ids.each do |project_id|
            AdminDefinedRoleProject.where(project_id: project_id,role_mask: mask, person_id: self.id).destroy_all
          end
          new_mask -= mask if (current_projects_ids - project_ids).empty?
        else
          new_mask -= mask
        end
      end
      self.roles_mask = new_mask
    end

    def is_gatekeeper_of? item
      is_gatekeeper? && !(item.projects & projects).empty?
    end

    def is_asset_manager_of? item
      is_asset_manager? && !(item.projects & projects).empty?
    end

  end
end