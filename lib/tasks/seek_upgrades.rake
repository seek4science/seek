require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'

namespace :seek do
  
  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[:environment,:compounds, :measured_items, :units, :upgrade_tags, :remove_duplicate_activity_creates, :update_sharing_scope]

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade=>[:environment,"db:migrate","tmp:clear","tmp:assets:clear"]) do
    
    solr=Seek::Config.solr_enabled

    Seek::Config.solr_enabled=false

    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr

    begin
      Rake::Task["solr:reindex"].invoke if solr
    rescue 
      puts "Reindexing failed - maybe solr isn't running?' - Error: #{$!}."
      puts "If not You should start solr and run rake solr:reindex manually"
    end

    puts "Upgrade completed successfully"
  end

  desc 'required to upgrade to 0.12.2 - converts all tags from acts_as_taggable to use acts_as_annotatable'
  task(:upgrade_tags=>:environment) do
    include ActsAsTaggableOn

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
            annotation_attribute.save!
          else
            tagger = taggable if tagger.nil? && attribute!="tag"
            unless tagger.nil?
              matches = Annotation.for_annotatable(taggable.class.name, taggable.id).with_attribute_name(attribute).by_source(tagger.class.name, tagger.id)
              matches = matches.select { |m| m.value == text_value }
              if matches.empty?
                annotation = Annotation.new :source=>tagger, :annotatable=>taggable, :value=>text_value, :attribute_name=>attribute
                disable_authorization_checks { annotation.save! }
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

  desc "removes the older duplicate create activity logs that were added for a short period due to a bug (this only affects versions between stable releases)"
  task(:remove_duplicate_activity_creates=>:environment) do
    ActivityLog.remove_duplicate_creates
  end

    #Update the sharing_scope in the policies table, because of removing CUSTOM_PERMISSIONS_ONLY and ALL_REGISTERED_USERS scopes
  task(:update_sharing_scope=>:environment) do
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

end