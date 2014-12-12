require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'

namespace :seek_stats do


  task(:activity=>:environment) do
    actions = ["download","create"]
    types = ["Model","Sop","DataFile"]

    actions.each do |action|
      types.each do |type|
        activity_for_action action,type
      end
    end

  end

  #filesizes and versions across projects
  task(:filesizes_and_versions => :environment) do
    types=[Model, Sop, Presentation, DataFile]

    types.each do |type|
      filename="#{Rails.root}/tmp/filesizes-and-versions-#{type.name}.csv"
      File.open(filename, "w") do |file|
        file << "type,id,created_at,filesize,content-type,version,project_id,project_name\n"
        type.find(:all,:order=>:created_at).each do |asset|
          file << "#{type.name}"
          file << ","
          file << asset.id
          file << ","
          file << %!"#{asset.created_at}"!
          file << ","
          blobs = asset.respond_to?(:content_blobs) ? asset.content_blobs : [asset.content_blob]
          size = blobs.compact.collect{|blob| blob.filesize}.compact.reduce(0,:+)
          c_types = blobs.compact.collect{|blob| blob.content_type}.join(", ")
          file << size
          file << ","
          file << %!"#{c_types}"!
          file << ","
          file << asset.version
          file << ","
          project = asset.projects.first
          file << project.id
          file << ","
          file << %!"#{project.title}"!
          file << "\n"
        end
      end
      puts "csv written to #{filename}"
    end

  end

  task(:downloaded_cross_project => :environment) do
    assets = Model.all | DataFile.all | Sop.all | Presentation.all

    puts "type, id, n downloads, n registered users,n downloads by reg users, n users from other projects,n downloads by other projects, n users from sysmo-db,n downloads by sysmo"
    sysmo_db = Project.find(12)
    assets.each do |asset|
      $stdout.flush
      logs = ActivityLog.where(action:"download",activity_loggable_type:asset.class.name,activity_loggable_id:asset.id).includes(:culprit)
      people = logs.collect{|l| l.culprit.try(:person)}.compact.uniq
      if people.count>0
        other_projects = people.select{|p| (p.projects & asset.projects).empty?}
        if other_projects.count>0
          sysmo_db_people = other_projects.select{|p| p.projects.include?(sysmo_db)}
          sysmo_db_n = sysmo_db_people.count
          downloads_by_reg = logs.select{|l| !l.culprit.nil?}.count
          downloads_by_other_proj = logs.select{|l| other_projects.include?(l.culprit.try(:person))}.count
          downloads_by_sysmo = logs.select{|l| sysmo_db_people.include?(l.culprit.try(:person))}.count
          puts "#{asset.class.name},#{asset.id},#{logs.count},#{people.count},#{downloads_by_reg},#{other_projects.count},#{downloads_by_other_proj},#{sysmo_db_n},#{downloads_by_sysmo}"
        end
      end
    end
  end

  desc "Create retrospective ActivityLog entries for the creation of Runs and Sweeps."
  task(:retrospectively_log_run_and_sweep_creation => :environment) do
    email_setting = Seek::Config.email_enabled
    # Disable timestamps so we can set the log entry time to the same time that the run/sweep was created, rather than the current time
    ActiveRecord::Base.record_timestamps = false

    begin
      # Disabling email is the only way to prevent an email job being created when an activity log is saved
      Seek::Config.email_enabled = false
      # Log single runs (not part of a sweep)
      TavernaPlayer::Run.where(:sweep_id => nil).all.each do |run|
        unless ActivityLog.where(:activity_loggable_id => run.id, :activity_loggable_type => 'TavernaPlayer::Run', :action => 'create').exists?
          ActivityLog.create(:activity_loggable => run, :action => 'create', :culprit => run.contributor,
                             :referenced => run.workflow, :user_agent => 'script', :created_at => run.created_at,
                             :updated_at => run.created_at, :controller_name => 'runs')
          puts "Logged creation of Run #{run.id}"
        else
          puts "Skipping Run #{run.id} (log entry exists)"
        end
      end

      # Log sweeps
      Sweep.all.each do |sweep|
        unless ActivityLog.where(:activity_loggable_id => sweep.id, :activity_loggable_type => 'Sweep', :action => 'create').exists?
          ActivityLog.create(:activity_loggable => sweep, :action => 'create', :culprit => sweep.contributor,
                             :referenced => sweep.workflow, :user_agent => 'script', :created_at => sweep.created_at,
                             :updated_at => sweep.created_at, :controller_name => 'sweeps')
          puts "Logged creation of Sweep #{sweep.id}"
        else
          puts "Skipping Sweep #{sweep.id} (log entry exists)"
        end
      end
    ensure

      ActiveRecord::Base.record_timestamps = true
      Seek::Config.email_enabled = email_setting
    end

    puts "Done"
  end

  task(:top_of_the_pops=>:environment) do
    [DataFile,Sop,Model,Presentation].each do |type|
      sorted = type.all.sort_by(&:view_count).reverse[0..9]
      puts "Top views for #{type}"
      sorted.each do |item|
        puts "id:#{item.id} - title:#{item.title} - views:#{item.view_count}"
      end

      sorted = type.all.sort_by(&:download_count).reverse[0..9]
      puts "Top downloads for #{type}"
      sorted.each do |item|
        puts "id:#{item.id} - title:#{item.title} - views:#{item.download_count}"
      end
      puts "------------------------------------------------------------"

    end
  end

  #things linked to publications


  def activity_for_action action,type=nil,controller_name=nil

    conditions = {:action=>action,:activity_loggable_type=>type,:controller_name=>controller_name}
    conditions = conditions.delete_if{|k,v| v.nil?}

    filename="#{Rails.root}/tmp/activity-#{action}-#{type || "all"}.csv"
    logs = ActivityLog.where(conditions).order(:created_at)
    File.open(filename, "w") do |file|
      file << "date,month,type,id,controller,action,project_id,project_name,culprit_project_matches"
      logs.each do |log|
        file << %!"#{log.created_at}"!
        file << ","
        file << %!"#{Date::MONTHNAMES[log.created_at.month]} #{log.created_at.year}"!
        file << ","
        file << log.activity_loggable_type
        file << ","
        file << log.activity_loggable_id
        file << ","
        file << log.controller_name
        file << ","
        file << action
        file << ","
        project = !log.activity_loggable.nil? && log.activity_loggable.respond_to?(:projects) ? log.activity_loggable.projects.first : nil
        if project
          file << project.id
          file << ","
          file << %!"#{project.title}"!

        else
          file <<%!"",""!
        end
        file << ","
        culprit = log.culprit
        if culprit && culprit.person
          file << culprit.person.projects.include?(project)
        else
          file << "false"
        end

        file << "\n"
      end
    end

    puts "csv written to #{filename}"
  end

end