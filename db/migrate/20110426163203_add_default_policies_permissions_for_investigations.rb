class AddDefaultPoliciesPermissionsForInvestigations < ActiveRecord::Migration
  class Policy < ActiveRecord::Base
  end
  class Project < ActiveRecord::Base
  end
  class Investigation < ActiveRecord::Base
    belongs_to :policy, :class_name => 'AddDefaultPoliciesPermissionsForInvestigations::Policy'
    belongs_to :project
  end

  def self.up
    Investigation.all.each do |investigation|
      unless investigation.policy
        #The policy allows any sysmo user (someone who is registered and assigned to a project) to view the studies.
        policy = investigation.create_policy({:access_type => 2, :sharing_scope => 2, :name => 'default for isa migration', :use_custom_sharing => true})
        now = Time.now.to_s(:db)
        execute "INSERT into permissions (contributor_type, contributor_id, policy_id, access_type, created_at, updated_at) VALUES ('Project', #{investigation.project_id}, #{policy.id}, 4, '#{now}', '#{now}')"

        #neccessary so that the foreign key in study.policy_id gets saved
        investigation.save
      end
    end
  end

  def self.down
  end
end
