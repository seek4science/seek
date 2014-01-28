class AddDefaultPoliciesPermissionsForStudies < ActiveRecord::Migration
  class Policy < ActiveRecord::Base
  end
  class Study < ActiveRecord::Base
    belongs_to :policy, :class_name => 'AddDefaultPoliciesPermissionsForStudies::Policy'
    # Returns all people tied to the study. This is based on the study's investigation's project,
    def project
      connection.select_one <<-SQL
        SELECT projects.id AS project_id
        FROM projects
          INNER JOIN investigations ON investigations.project_id = projects.id
          INNER JOIN studies ON investigations.id = studies.investigation_id
        WHERE studies.id = #{self.id}
      SQL
    end
  end

  def self.up
    Study.all.each do |study|
      unless study.policy
        #The policy allows any sysmo user (someone who is registered and assigned to a project) to view the studies.
        policy = study.create_policy({:access_type => 2, :sharing_scope => 2, :name => 'default for isa migration', :use_custom_sharing => true})
        now = Time.now.to_s(:db)
        execute "INSERT into permissions (contributor_type, contributor_id, policy_id, access_type, created_at, updated_at) VALUES ('Project', #{study.project["project_id"]}, #{policy.id}, 4, '#{now}', '#{now}')"

        #neccessary so that the foreign key in study.policy_id gets saved
        study.save
      end
    end
  end

  def self.down
  end
end
