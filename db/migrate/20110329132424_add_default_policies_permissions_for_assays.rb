class AddDefaultPoliciesPermissionsForAssays < ActiveRecord::Migration
  class Policy < ActiveRecord::Base
  end
  class Assay < ActiveRecord::Base
    belongs_to :policy, :class_name => 'AddDefaultPoliciesPermissionsForAssays::Policy'
    # Returns all pals tied to the assay. This is based on the assay's investigation's project,
    # the person's role in that project, and the is_pal field of person.
    def assay_pals
      #Gets all the roles, gets their names, and then uses the first one containing 'pal', case insensitive
      pal_role_name = connection.select_all("SELECT name FROM roles").collect { |role| role["name"] }.find { |role| / pal/i =~ role }
      logger.info "Using #{pal_role_name} as pal role, if this is incorrect, the wrong default permissions will be generated"
      connection.select_all <<-SQL
        SELECT people.id AS person_id
        FROM group_memberships_roles
          INNER JOIN group_memberships ON group_memberships_roles.group_membership_id = group_memberships.id
          INNER JOIN roles ON group_memberships_roles.role_id = roles.id
          INNER JOIN people ON group_memberships.person_id = people.id
          INNER JOIN work_groups ON group_memberships.work_group_id = work_groups.id
          INNER JOIN investigations ON investigations.project_id = work_groups.project_id
          INNER JOIN studies ON investigations.id = studies.investigation_id
          INNER JOIN assays ON studies.id = assays.study_id
        WHERE people.is_pal = 1 AND roles.name = "#{pal_role_name}" AND assays.id = #{self.id}
      SQL
    end
  end

  def self.up
    Assay.all.each do |assay|
      unless assay.policy
        assay_pals = assay.assay_pals
        #The policy allows any sysmo user (someone who is registered and assigned to a project) to view the assays.
        policy     = assay.create_policy({:access_type => 2, :sharing_scope => 2, :name => 'default for isa migration', :use_custom_sharing => !assay_pals.empty?})

        #If there are any pals in the assay's project, they get manage rights by default.
        assay_pals.each do |pal|
          now = Time.now.to_s(:db)
          execute "INSERT into permissions (contributor_type, contributor_id, policy_id, access_type, created_at, updated_at) VALUES ('Person', #{pal["person_id"]}, #{policy.id}, 4, '#{now}', '#{now}')"
        end

        #neccessary so that the foreign key in assay.policy_id gets saved
        assay.save
      end
    end
  end

  def self.down
  end
end
