require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'

namespace :seek do
  
  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
      :environment,
      :compounds,
      :measured_items,
      :units,
      :upgrade_tags,
      :refresh_organism_concepts,
      :remove_duplicate_activity_creates,
      :update_sharing_scope,
      #:create_default_subscriptions,
      :update_study_and_inv_contributors_and_permissions
  ]

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade=>[:environment,"db:migrate","tmp:clear","tmp:assets:clear"]) do
    
    solr=Seek::Config.solr_enabled

    Seek::Config.solr_enabled=false

    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr

    begin
      Rake::Task["sunspot:reindex"].invoke if solr
    rescue 
      puts "Reindexing failed - maybe solr isn't running?' - Error: #{$!}."
      puts "If not You should start solr and run rake sunspot:reindex manually"
    end

    puts "Upgrade completed successfully"
  end

  desc('updates the permissions to editable by project, and sets a suitable contributor')
  task(:update_study_and_inv_contributors_and_permissions=>:environment) do
    puts "Updating study and investigation contributors and default permissions"
    ActiveRecord::Base.record_timestamps = false

    Study.all.each do |study|
      if study.policy.permissions.count!=1
        puts "Study ID:#{study.id} has had its permissions changed and cannot be updated"
      else
        perm=study.policy.permissions.first
        perm.access_type = Policy::EDITING if perm.access_type==Policy::MANAGING
        disable_authorization_checks {perm.save}
        #add pals as managers
        study.projects.collect{|proj| proj.pals}.flatten.uniq.each do |pal|
          perm=Permission.new(:contributor=>pal,:policy=>study.policy,:access_type=>Policy::MANAGING)
          disable_authorization_checks {perm.save}
        end
      end
      study.contributor = determine_study_contributor(study) if study.contributor.nil?
      disable_authorization_checks {study.save}
    end

    Investigation.all.each do |investigation|
      if investigation.policy.permissions.count!=1
        puts "Investigation ID:#{investigation.id} has had its permissions changed and cannot be updated"
      else
        perm=investigation.policy.permissions.first
        perm.access_type = Policy::EDITING if perm.access_type==Policy::MANAGING
        disable_authorization_checks {perm.save}
        #add pals as managers
        investigation.projects.collect{|proj| proj.pals}.flatten.uniq.each do |pal|
          perm=Permission.new(:contributor=>pal,:policy=>investigation.policy,:access_type=>Policy::MANAGING)
          disable_authorization_checks {perm.save}
        end
      end
      investigation.contributor = determine_investigation_contributor(investigation) if investigation.contributor.nil?
      disable_authorization_checks {investigation.save}
    end
    
    ActiveRecord::Base.record_timestamps = true
  end

  desc 'required to upgrade to 1.0 - converts all tags from acts_as_taggable to use acts_as_annotatable'
  task(:upgrade_tags=>:environment) do
    include ActsAsTaggableOn

    puts "Upgrading tags"
    Tag.find(:all).each do |tag|

      text=tag.name
      text_value=TextValue.find_or_create_by_text(text)

      tag.taggings.each do |tagging|
        attribute = tagging.context
        attribute = "tool" if attribute=="tools"
        attribute = "tag" if attribute=="tags"
        if !attribute.nil? && attribute != "organism"
          tagger = tagging.tagger
          taggable=tagging.taggable
          if taggable.nil?
            #seed
            annotation_attribute = AnnotationValueSeed.new :value=>text_value, :attribute=>AnnotationAttribute.find_or_create_by_name(attribute)
            disable_authorization_checks { annotation_attribute.save }
          else
            tagger = taggable if tagger.nil? && attribute!="tag"
            unless tagger.nil?
              matches = Annotation.for_annotatable(taggable.class.name, taggable.id).with_attribute_name(attribute).by_source(tagger.class.name, tagger.id)
              matches = matches.select { |m| m.value == text_value }
              if matches.empty?
                annotation = Annotation.new :source=>tagger, :annotatable=>taggable, :value=>text_value, :attribute_name=>attribute
                disable_authorization_checks { annotation.save }
              end

            end
          end
        end
        tagging.destroy
      end
      tag.destroy
    end
    puts "Finished updating tags successfully"
  end

  desc "Subscribes users to the items they would normally be subscribed to by default"
  #Run this after the subscriptions, and all subscribable classes have had their tables created by migrations
  #You can also run it any time you want to force everyone to subscribe to something they would be subscribed to by default
  task :create_default_subscriptions => :environment do
    puts "Creating default subscriptions. This can take some time, please be patient"
    ActiveRecord::Base.record_timestamps = false
    Person.all.each do |p|
      puts "Updating subscriptions for Person #{p.id}"
      p.set_default_subscriptions
      disable_authorization_checks {p.save(false)}
    end
    ActiveRecord::Base.record_timestamps = true 
  end

  desc "removes the older duplicate create activity logs that were added for a short period due to a bug (this only affects versions between stable releases)"
  task(:remove_duplicate_activity_creates=>:environment) do
    ActivityLog.remove_duplicate_creates
  end

    #Update the sharing_scope in the policies table, because of removing CUSTOM_PERMISSIONS_ONLY and ALL_REGISTERED_USERS scopes
  task(:update_sharing_scope=>:environment) do
    puts "Updating general sharing scopes"
    # sharing_scope
    private_scope = 0
    custom_permissions_only_scope = 1
    all_sysmo_users_scope = 2
    all_registered_users_scope = 3
    every_one = 4

      #First, need to update the sharing_scope of publication_policy from 3 to 4
    policies = Policy.find(:all, :conditions => ["name = ? AND sharing_scope = ?", 'publication_policy', all_registered_users_scope])
    unless policies.nil?
      count = 0
      policies.each do |policy|
        policy.sharing_scope = every_one
        policy.save
        count += 1
      end
      puts "Done - #{count} publication_policies changed scope from ALL_REGISTERED_USERS to EVERYONE."
    else
      puts "Couldn't find any policies with ALL_REGISTERED_USERS scope and publication_policy"
    end

      #update  ALL_REGISTERED_USERS to ALL_SYSMO_USERS
    policies = Policy.find(:all, :conditions => ["sharing_scope = ?", all_registered_users_scope])
    unless policies.nil?
      count = 0
      policies.each do |policy|
        policy.sharing_scope = all_sysmo_users_scope
        policy.save
        count += 1
      end
      puts "Done - #{count} policies with ALL_REGISTERED_USERS scope changed to ALL_SYSMO_USERS scope."
    else
      puts "Couldn't find any policies with ALL_REGISTERED_USERS scope"
    end

      #update  CUSTOM_PERMISSIONS_ONLY to PRIVATE
    policies = Policy.find(:all, :conditions => ["sharing_scope = ?", custom_permissions_only_scope])
    unless policies.nil?
      count = 0
      policies.each do |policy|
        policy.sharing_scope = private_scope
        policy.save
        count += 1
      end
      puts "Done - #{count} policies with CUSTOM_PERMISSIONS_ONLY scope changed to PRIVATE scope."
    else
      puts "Couldn't find any policies with CUSTOM_PERMISSIONS_ONLY scope"
    end
  end

  private

  def determine_study_contributor study
    contributor = study.person_responsible
    unless contributor
      puts "No person responsible for Study #{study.id}, determining contributor from assays"
      if study.assays.blank?
        puts "No assays for this study. Using the first defined pal from project"
        contributor = study.projects.collect{|proj| proj.pals}.flatten.first
        puts "No pals found for Study #{study.id} - leaving contributor as unset (it will appear as JERM created)." if contributor.nil?
      else
        study.assays.sort_by(&:id).each do |assay|
          contributor = assay.contributor
          break unless contributor.nil?
        end
      end
    end
    puts "Determined contributor as #{contributor.try(:name) || 'nil'} for Study #{study.id}"
    contributor
  end

  def determine_investigation_contributor investigation
    contributor=nil
    investigation.studies.sort_by(&:id).each do |study|
      contributor=study.contributor
      break unless contributor.nil?
    end
    if contributor.nil?
      puts "Unable to determine contributor from study for Investigation #{investigation.id}, using a pal"
      contributor = investigation.projects.collect{|proj| proj.pals}.flatten.first
      puts "No pals found for Investigation - leaving contributor as unset (it will appear as JERM created)." if contributor.nil?
    end
    puts "Determined contributor as #{contributor.try(:name) || 'nil'} for Investigation #{investigation.id}"
    contributor
  end

end
