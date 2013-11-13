require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'


namespace :seek do

  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :update_admin_assigned_roles,
            :update_top_level_assay_type_titles,
            :repopulate_auth_lookup_tables
  ]

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade=>[:environment,"db:migrate","db:sessions:clear","tmp:clear","tmp:assets:clear"]) do
    
    solr=Seek::Config.solr_enabled

    Seek::Config.solr_enabled=false

    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr

    if (solr)
      Rake::Task["seek:reindex_all"].invoke
    end

    puts "Upgrade completed successfully"
  end

  task(:update_admin_assigned_roles=>:environment) do
    Person.where("roles_mask > 0").each do |p|
      if p.admin_defined_role_projects.empty?
        roles = []
        (p.role_names & Person::PROJECT_DEPENDENT_ROLES).each do |role|
          puts "Updating #{p.name} for - '#{role}' - adding to #{p.projects.count} projects"
          roles << [role,p.projects]
        end
        unless roles.empty?
          Person.record_timestamps = false
          begin
            p.roles = roles
            p.save!
          rescue Exception=>e
            puts "Error saving #{p.name} - #{p.id}: #{e.message}"
          ensure
            Person.record_timestamps = true
          end
        end

      end

    end
  end

  task(:update_top_level_assay_type_titles=>:environment) do
    exp_id = AssayType.experimental_assay_type_id
    assay_type = AssayType.find(exp_id)
    assay_type.title="generic experimental assay"
    assay_type.save!

    mod_id = AssayType.modelling_assay_type_id
    assay_type = AssayType.find(mod_id)
    assay_type.title="generic modelling analysis"
    assay_type.save!
  end

end
