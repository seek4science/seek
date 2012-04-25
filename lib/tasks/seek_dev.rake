require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'

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
  task(:duplicate_activity_creates=>:environment) do
    duplicates = ActivityLog.duplicates("create")
    if duplicates.length>0
      puts "Found #{duplicates.length} duplicated entries:"
      duplicates.each do |duplicate|
        matches = ActivityLog.find(:all,:conditions=>{:activity_loggable_id=>duplicate.activity_loggable_id,:activity_loggable_type=>duplicate.activity_loggable_type,:action=>"create"},:order=>"created_at ASC")
        puts "ID:#{duplicate.id}\tLoggable ID:#{duplicate.activity_loggable_id}\tLoggable Type:#{duplicate.activity_loggable_type}\tCount:#{matches.count}\tCreated ats:#{matches.collect{|m| m.created_at}.join(", ")}"
      end
    else
      puts "No duplicates found"
    end
  end

  desc 'create 50 randomly named unlinked projects'
  task(:random_projects=>:environment) do
    (0...50).to_a.each do
      title=("A".."Z").to_a[rand(26)]+" #{UUIDTools::UUID.random_create.to_s}"
      p=Project.create :title=>title
      p.save!
    end
  end
  
  desc "Lists all publicly available assets"
  task :list_public_assets => :environment do
    [Investigation, Study, Assay, DataFile, Model, Sop, Publication].each do |assets|
      #  :logout
      assets.all.each do |asset|
        if asset.can_view?
          puts "#{asset.title} - #{asset.id}"
        end
      end
    end
  end

  desc "Generate an XMI db/schema.xml file describing the current DB as seen by AR. Produces XMI 1.1 for UML 1.3 Rose Extended, viewable e.g. by StarUML"
  task :xmi => :environment do
    require 'lib/uml_dumper.rb'
    File.open("doc/data_models/schema.xmi", "w") do |file|
      ActiveRecord::UmlDumper.dump(ActiveRecord::Base.connection, file)
    end
    puts "Done. Schema XMI created as doc/data_models/schema.xmi."
  end

  desc 'removes any data this is not authorized to viewed by the first User'
  task(:remove_private_data=>:environment) do
    sops        =Sop.find(:all)
    private_sops=sops.select { |s| !s.can_view? User.first }
    puts "#{private_sops.size} private Sops being removed"
    private_sops.each { |s| s.destroy }

    models        =Model.find(:all)
    private_models=models.select { |m| ! m.can_view? User.first }
    puts "#{private_models.size} private Models being removed"
    private_models.each { |m| m.destroy }

    data        =DataFile.find(:all)
    private_data=data.select { |d| !d.can_view? User.first }
    puts "#{private_data.size} private Data files being removed"
    private_data.each { |d| d.destroy }
  end



end