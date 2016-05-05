require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'colorize'
require 'benchmark'

include SysMODB::SpreadsheetExtractor

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
        matches = ActivityLog.where({:activity_loggable_id=>duplicate.activity_loggable_id,:activity_loggable_type=>duplicate.activity_loggable_type,:action=>"create"},:order=>"created_at ASC")
        puts "ID:#{duplicate.id}\tLoggable ID:#{duplicate.activity_loggable_id}\tLoggable Type:#{duplicate.activity_loggable_type}\tCount:#{matches.count}\tCreated ats:#{matches.collect{|m| m.created_at}.join(", ")}"
      end
    else
      puts "No duplicates found"
    end
  end

  desc 'create 50 randomly named unlinked projects'
  task(:random_projects=>:environment) do
    (0...50).to_a.each do
      title=("A".."Z").to_a[rand(26)]+UUID.generate
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

  task(:refresh_content_types => :environment) do

    ContentBlob.all.each do |cb|
      filename = cb.original_filename
      unless filename.nil?
        file_format = filename.split('.').last.try(:strip)
        possible_mime_types = cb.mime_types_for_extension file_format
        type = possible_mime_types.sort.first || "application/octet-stream"
        type = type.gsub("image/jpg","image/jpeg") unless type.nil?

        cb.content_type = type
        cb.save
      end
    end

  end

  desc "display contributor types"
  task(:contributor_types=>:environment) do
    types = Seek::Util.user_creatable_types.collect do |type|
      type.all.collect do |thing|
        if thing.respond_to?(:contributor)
          if !thing.contributor.nil?
            "#{type.name} - #{thing.contributor.class.name}"
          end
        else
          pp "No contributor for #{type}"
          nil
        end
      end.flatten.compact.uniq
    end.flatten.uniq
    pp types
  end

  desc "display user contributors without people"
  task(:contributors_without_people=>:environment) do
    matches = Seek::Util.user_creatable_types.collect do |type|
      type.all.select do |thing|
        thing.respond_to?(:contributor_type) && thing.contributor.is_a?(User) && thing.contributor.person.nil?
      end
    end.flatten
    pp "#{matches.size} items found with a user contributor and no person"
    matches.each do |match|
      pp "\t#{match.class.name} - #{match.id}"
    end

  end

  desc "Generate an XMI db/schema.xml file describing the current DB as seen by AR. Produces XMI 1.1 for UML 1.3 Rose Extended, viewable e.g. by StarUML"
  task :xmi => :environment do
    require 'uml_dumper.rb'
    File.open("doc/data_models/schema.xmi", "w") do |file|
      ActiveRecord::UmlDumper.dump(ActiveRecord::Base.connection, file)
    end
    puts "Done. Schema XMI created as doc/data_models/schema.xmi."
  end

  desc 'removes any data this is not authorized to viewed by the first User'
  task(:remove_private_data=>:environment) do
    sops        =Sop.all
    private_sops=sops.select { |s| !s.can_view? User.first }
    puts "#{private_sops.size} private Sops being removed"
    private_sops.each { |s| s.destroy }

    models        =Model.all
    private_models=models.select { |m| ! m.can_view? User.first }
    puts "#{private_models.size} private Models being removed"
    private_models.each { |m| m.destroy }

    data        =DataFile.all
    private_data=data.select { |d| !d.can_view? User.first }
    puts "#{private_data.size} private Data files being removed"
    private_data.each { |d| d.destroy }
  end

  desc "Dumps help documents and attachments/images"
  task :dump_help_docs => :environment do
    format_class = "YamlDb::Helper"
    dir = 'help_dump_tmp'
      #Clear path
    puts "Clearing existing backup directories"
    FileUtils.rm_r('config/default_data/help', :force => true)
    FileUtils.rm_r('config/default_data/help_images', :force => true)
    FileUtils.rm_r('db/help_dump_tmp/', :force => true)
      #Dump DB
    puts "Dumping database"
    SerializationHelper::Base.new(format_class.constantize).dump_to_dir dump_dir("/#{dir}")
      #Copy relevant yaml files
    puts "Copying files"
    FileUtils.mkdir('config/default_data/help') rescue ()
    FileUtils.copy('db/help_dump_tmp/help_documents.yml', 'config/default_data/help/')
    FileUtils.copy('db/help_dump_tmp/help_attachments.yml', 'config/default_data/help/')
    FileUtils.copy('db/help_dump_tmp/help_images.yml', 'config/default_data/help/')
    FileUtils.copy('db/help_dump_tmp/db_files.yml', 'config/default_data/help/')
      #Delete everything else
    puts "Cleaning up"
    FileUtils.rm_r('db/help_dump_tmp/')
      #Copy image folder
    puts "Copying images"
    FileUtils.mkdir('public/help_images') rescue ()
    FileUtils.cp_r('public/help_images', 'config/default_data/') rescue ()
  end

  desc "Dumps current compounds and synoymns to a yaml file for the seed process"
  task :dump_compounds_and_synonyms => :environment do
    format_class = "YamlDb::Helper"
    dir = 'compound_dump_tmp'
    puts "Dumping database"
    SerializationHelper::Base.new(format_class.constantize).dump_to_dir dump_dir("/#{dir}")
    puts "Copying compound and synonym files"
    FileUtils.copy("db/#{dir}/compounds.yml", 'config/default_data/')
    FileUtils.copy("db/#{dir}/synonyms.yml", 'config/default_data/')
    puts "Cleaning up"
    FileUtils.rm_r("db/#{dir}/")
  end


  desc "Gives project pals manage rights to their projects Investigation, Studies and Assays - this was a particular SysMO need"
  task :pals_manage_isa => :environment do
    Project.all.select{|p| !p.pals.empty?}.each do |project|
      pals = project.pals
      puts "Updating ISA for project #{project.title} for PALs #{pals.collect{|p|p.name}.join(", ")}"
      investigations = project.investigations
      studies = project.studies
      assays = project.assays
      (investigations | studies | assays).each do |isa|
        policy = isa.policy
        pals.each do |pal|
          if policy.permissions.select{|p| p.contributor==pal && p.access_type==Policy::MANAGING}.empty?
            policy.permissions << Permission.new(:contributor=>pal,:access_type=>Policy::MANAGING)
          end
        end
      end
      puts "\t#{assays.count} Assays updated, #{studies.count} Studies updated, #{investigations.count} Investigations updated"
    end
  end

  #quick way of setting up logins when setting up for, say a workshop
  #creates logins with the provided password, based on first initial-lastname
  #all lower case. John Smith would become jsmith It also activates them
  #it does this for all people without logins
  task :generate_logins, [:pwd] => :environment do |t,args|
    password = args.pwd
    Person.not_registered.each do |person|
      login = "#{person.first_name[0]}#{person.last_name}".downcase.gsub(' ','')
      person.create_user login: login, password: password, password_confirmation: password
      person.user.activate
    end
  end

  task :add_people_from_spreadsheet, [:path] => :environment do |t, args|
    path = args.path
    file = open(path)
    csv = spreadsheet_to_csv(file)
    CSV.parse(csv) do |row|
      firstname=row[0].strip
      next if firstname=="first"
      lastname=row[1].strip
      email=row[2].strip
      project_id=row[3].strip
      institution_id=row[4].strip
      pp "Checking for #{firstname} #{lastname}"
      matches = Person.where(:first_name => firstname, :last_name => lastname)
      unless matches.empty?
        puts "A person already exists with firstname and lastname #{firstname},#{lastname} respectively, skipping".red
        next
      else
        puts "Preparing to add person #{firstname} #{lastname} with email #{email}"
        person = Person.new :first_name => firstname, :last_name => lastname, :email => email
      end
      project = Project.find_by_id(project_id)
      if project.nil?
        pp "No project found for id #{project_id}, skipping #{person.name}".red
        next
      end
      institution = Institution.find_by_id(institution_id)
      if institution.nil?
        pp "No institution found for id #{institution_id}, skipping #{person.name}".red
        next
      end
      person.add_to_project_and_institution(project, institution)
      begin
        person.save!
        puts "#{person.name} successfully added".green
      rescue Exception => e
        puts "Error adding #{person.name}".red
        puts e
      end
    end
  end


  task :add_denbi_people_from_spreadsheet, [:path] => :environment do |t, args|
    path = args.path
    file = open(path)
    csv = spreadsheet_to_csv(file)
    project = Project.where(title: 'de.NBI summer school').first
    CSV.parse(csv) do |row|
      next if row[0].blank?
      firstname=row[0].strip
      next if firstname=="first_name"
      lastname=row[1].strip
      email=row[2].strip
      institution_title=row[3].strip
      country=row[4].strip

      pp "Checking for #{firstname} #{lastname}"
      person = Person.where(:first_name => firstname, :last_name => lastname).first
      unless person.nil?
        puts "A person already exists with firstname and lastname #{firstname},#{lastname} respectively, skipping".red
        next
      else
        puts "Preparing to add person #{firstname} #{lastname} with email #{email}"
        person = Person.create :first_name => firstname, :last_name => lastname, :email => email
        person.reload
      end

      institution = Institution.where(title: institution_title).first
      if institution.nil?
        pp "No institution found for title #{institution_title}, create new one".red
        institution = Institution.create :title => institution_title, :country => country
        institution.reload
      end
      person.add_to_project_and_institution(project, institution)
      begin
        person.save!
        puts "#{person.name} successfully added".green
      rescue Exception => e
        puts "Error adding #{person.name}".red
        puts e
      end
    end
  end

  desc "Benchmark data_file_auth_lookup"
  task :benchmark_lookup_table => :environment do
    data_file_step = 10000
    user_step = 500

    total_data_files = DataFile.count
    total_users = User.count

    user_count = 100
    while (user_count < total_users)
      data_file_count = 100
      while (data_file_count < total_data_files)
        bench = Benchmark.measure do
          users = User.all.take(user_count)
          table_name = DataFile.lookup_table_name
          assets = DataFile.all(:include => :policy).take(data_file_count)
          ActiveRecord::Base.transaction do
            users.each do |user|
              ActiveRecord::Base.connection.execute("delete from #{table_name} where user_id = #{user.id}")
              c=0
              assets.each do |asset|
                asset.update_lookup_table user
                c+=1
                puts "#{c} done out of #{data_file_count} for #{DataFile.name}" if c%100==0
              end
              #count = ActiveRecord::Base.connection.select_one("select count(*) from #{table_name} where user_id = #{user.id}").values[0]
              #puts "inserted #{count} records for #{DataFile.name}"
            end
          end
          GC.start
        end
        puts "Insert into csv performance result for #{data_file_count} data files on #{user_count} users"

        path = Rails.root.join('auth_lookup.csv')
        row = [data_file_count, bench.total, bench.real, bench.utime, bench.stime, user_count]
        if File.exists?(path)
          CSV.open(Rails.root.join('auth_lookup.csv'), "a") do |csv|
            csv << row
          end
        else
          CSV.open(Rails.root.join('auth_lookup.csv'), "a", :write_headers => true, :headers => ["number of items", "total(s)", "real(s)", "user time(s)", "system time(s)", "number of user"]) do |csv|
            csv << row
          end
        end
        data_file_count += data_file_step
      end
      user_count += user_step
    end
  end

  # after finishing benchmark, need to restart delayed jobs to remove the DataFileAuthLookupJob and get the normal jobs run.
  desc "Benchmark data_file_auth_lookup table with delayed jobs"
  task :benchmark_lookup_table_with_delayed_jobs => :environment do
    user_step = 1000
    total_users = User.count

    delayed_job_step = 1
    total_delayed_jobs = 1

    user_count = 100
    data_file_count = 100

    while (user_count <= total_users)
      delayed_job_count = 1
      while (delayed_job_count <= total_delayed_jobs)
        puts "Restart delayed jobs"
	      Seek::Workers.stop
	      Seek::Workers.start_data_file_auth_lookup_worker(delayed_job_count, data_file_count)
        Delayed::Job.destroy_all
        AuthLookupUpdateQueue.destroy_all
        #DataFile.clear_lookup_table
        users = User.all.take(user_count)
        bench = Benchmark.measure do
          puts "Start benchmark"
          DataFileAuthLookupJob.new(data_file_count).add_items_to_queue(users, 1.seconds.from_now, 1)
          #DataFileAuthLookupJob.new(data_file_count).add_items_to_queue(users.take(50), 1.seconds.from_now, 1)
          #DataFileAuthLookupJob.new(data_file_count).add_items_to_queue(users.drop(50), 1.seconds.from_now, 1)
          DataFileAuthLookupJob.new(data_file_count).perform
        end
        puts "Insert into csv performance result for #{user_count} users on #{delayed_job_count} delayed jobs"

        path = Rails.root.join('auth_lookup.csv')
        row = [user_count, bench.total, bench.real, bench.utime, bench.stime, delayed_job_count]
        if File.exists?(path)
          CSV.open(Rails.root.join('auth_lookup.csv'), "a") do |csv|
            csv << row
          end
        else
          CSV.open(Rails.root.join('auth_lookup.csv'), "a", :write_headers => true, :headers => [ "number of users", "total(s)", "real(s)", "user time(s)", "system time(s)", "number of delayed jobs"]) do |csv|
            csv << row
          end
        end
        delayed_job_count += delayed_job_step
      end
      user_count += user_step
    end
  end

end
