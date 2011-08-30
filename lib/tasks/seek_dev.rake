require 'rubygems'
require 'rake'
require 'active_record/fixtures'

namespace :seek_dev do
  desc 'A simple task for quickly setting up a project and institution, and assigned the first user to it. This is useful for quickly setting up the database when testing. Need to create a default user before running this task'
  task(:initial_membership=>:environment) do
    p=Person.first
    raise Exception.new "Need to register a person first" if p.nil? || p.user.nil?

    User.with_current_user p.user do
      project=Project.new :title=>"Project X"
      institution=Institution.new :title=>"The Institute"
      project.save!
      institution.projects << project
      institution.save!
      p.update_attributes({"work_group_ids"=>["#{project.work_groups.first.id}"]})
    end
    
  end

  desc 'finds duplicate create activity records for the same item'
  task(:duplicate_creates=>:environment) do
    duplicates = ActivityLog.find(:all,
                                  :select=>"id,created_at,activity_loggable_type,activity_loggable_id,action,count(activity_loggable_id+activity_loggable_type) as dup_count",
                                  :conditions=>"action='create' and controller_name!='sessions'",
                                  :group=>"activity_loggable_type,activity_loggable_id having dup_count>1"
    )
    if !duplicates.empty?
      puts "Found duplicates:"
      duplicates.each do |duplicate|
        matches = ActivityLog.find(:all,:conditions=>{:activity_loggable_id=>duplicate.activity_loggable_id,:activity_loggable_type=>duplicate.activity_loggable_type,:action=>"create"},:order=>"created_at ASC")
        puts "ID:#{duplicate.id}\tLoggable ID:#{duplicate.activity_loggable_id}\tLoggable Type:#{duplicate.activity_loggable_type}\tCount:#{matches.count}\tCreated ats:#{matches.collect{|m| m.created_at}.join(", ")}"
      end
    else
      puts "No duplicates found"
    end
  end

end