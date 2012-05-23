require 'rubygems'
require 'rake'
require 'time'
require 'active_record/fixtures'



require 'csv'
require 'fastercsv'

namespace :seek do

  desc 'an alternative to the doc:seek task'
  task(:docs=>["doc:seek"])

  desc 'move sample-sop relation from sample_sops to sample_assets'
  task(:copy_old_sample_sops => :environment) do
    SampleSop.all.each do |ss|
      disable_authorization_checks do
        SampleAsset.create! :sample_id => ss.sample_id,:asset_id => ss.sop_id,:asset_type => "Sop",:version => ss.sop_version
      end
    end
  end
  desc 'Images for model: moving id_image data to model_image'
  #This should be run before removing the id_image in models.
  #Before id_image was used which was the id of one content blob,
  #but now model_image(acts like avatar) is used instead.
  #what should be done is: create model_image according to the corresponding content_blob, and then copy the file to ModelImage.IMAGE_STORAGE_PATH(/filestore/model_images)
  task(:update_id_image_to_model_image=>:environment) do
    if Model::Version.first.respond_to? :id_image
      Model::Version.all.select(&:id_image).each do |mv|
        content_blob = ContentBlob.find mv.id_image
        model = Model.find mv.model_id
        file = ModPorter::UploadedFile.new :path=>content_blob.filepath, :filename=>content_blob.original_filename, :content_type=>content_blob.content_type
        model_image = ModelImage.new "image_file" => file
        model_image.model_id = mv.model_id
        model_image.original_content_type = content_blob.content_type
        model_image.original_filename = content_blob.original_filename

        model.model_image = model_image

        disable_authorization_checks {
          model_image.save!
          model.save!
          content_blob.destroy
        }
      end

    end

  end
  desc 'updates the md5sum, and makes a local cache, for existing remote assets'
  task(:cache_remote_content_blobs=>:environment) do
    resources = Sop.find(:all)
    resources |= Model.find(:all)
    resources |= DataFile.find(:all)
    resources = resources.select { |r| r.content_blob && r.content_blob.data.nil? && r.content_blob.url && !r.projects.empty? }

    resources.each do |res|
      res.cache_remote_content_blob
    end
  end

  task(:tissue_and_cell_types=>:environment) do
    revert_fixtures_identify
    TissueAndCellType.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "tissue_and_cell_types")
  end




  desc "Create rebranded default help documents"
  task :rebrand_help_docs => :environment do
    template = ERB.new File.new("config/rebrand/help_documents.erb").read, nil, "%"
    File.open("config/default_data/help/help_documents.yml", 'w') { |f| f.write template.result(binding) }
  end

  desc "The newer acts-as-taggable-on plugin is case insensitve. Older tags are case sensitive, leading to some odd behaviour. This task resolves the old tags"
  task :resolve_duplicate_tags=>:environment do
    tags=ActsAsTaggableOn::Tag.find :all
    skip_tags = []
    tags.each do |tag|
      unless skip_tags.include? tag
        matching = tags.select { |t| t.name.downcase.strip == tag.name.downcase.strip && t.id != tag.id }
        unless matching.empty?
          matching.each do |m|
            puts "#{m.name}(#{m.id}) - #{tag.name}(#{tag.id})"
            m.taggings.each do |tagging|
              unless tag.taggings.detect { |t| t.context==tagging.context && t.taggable==tagging.taggable }
                puts "Updating tagging #{tagging.id} to point to #{tag.name}:#{tag.id}"
                tagging.tag = tag
                tagging.save!
              else
                puts "Deleting duplicate tagging #{tagging.id}"
                tagging.delete
              end
            end
            m.delete
            skip_tags << m
          end
        end
      end
    end
  end

  desc "Overwrite footer layouts with generic, rebranded alternatives"
  task :rebrand_layouts do
    dir = 'config/rebrand/'
    #TODO: Change to select everything in config/rebrand/ except for help_documents.erb
    FileUtils.cp FileList["#{dir}/*"].exclude("#{dir}/help_documents.erb"), 'app/views/layouts/'
  end

  desc "Replace Sysmo specific files with rebranded alternatives"
  task :rebrand => [:rebrand_help_docs, :rebrand_layouts]

  desc "projects hierarchies only for existing Virtual Liver SEEK projects "
  task :projects_hierarchies =>:environment do
    root = Project.find_by_name "Virtual Liver"

    irreg_projects = [
        ctu = Project.find_by_name("CTUs"),
        show_case = Project.find_by_name("Show cases"),
        project_mt = Project.find_by_name("Project Management"),
        interleukin = Project.find_by_name("Interleukin-6 signalling"),
        pals = Project.find_by_name("PALs Team"),
        hepatosys = Project.find_by_name("HepatoSys")
    ].compact

    #root as parent
    reg_projects = Project.find(:all, :conditions=>["name REGEXP?", "^[A-Z][:]"])
    (irreg_projects + reg_projects).each do |proj|
      proj.parent = root
      puts "#{proj.name} |has parent|  #{root.name}"
      proj.save!
    end

    #ctus
    sub_ctus = Project.find(:all, :conditions=>["name REGEXP?", "^CTU[^s]"])
    sub_ctus.each do |proj|
      if ctu
        proj.parent = ctu
        puts "#{proj.name} |has parent|  #{ctu.name}"
        proj.save!
      end
    end
    #show cases
    ["HGF and Regeneration", "LPS and Inflammation", "Steatosis"].each do |name|
      proj = Project.find_by_name name
      if proj and show_case
        proj.parent = show_case
        puts "#{proj.name} |has parent| #{show_case.name}"
        proj.save!
      end
    end
    #project management
    ["Admin:Administration",
     "PtJ",
     "Virtual Liver Management Team",
     "Virtual Liver Scientific Advisory Board"].each do |name|
      proj = Project.find_by_name name
      if proj and project_mt
        proj.parent = project_mt
        puts "#{proj.name} |has parent| #{project_mt.name}"
        proj.save!
      end
    end
    #set parents for children of A-G,e.g.A,A1,A1.1
    reg_projects.each do |proj|
      init_char = proj.name[0].chr
      Project.find(:all, :conditions=>["name REGEXP?", "^#{init_char}[0-9][^.]"]).each do |sub_proj|
        if sub_proj
          sub_proj.parent = proj
          puts "#{sub_proj.name} |has parent| #{proj.name}"
          sub_proj.save!
          num = sub_proj.name[1].chr # get the second char of the name
          Project.find(:all, :conditions=>["name REGEXP?", "^#{init_char}[#{num}][.]"]).each { |sub_sub_proj|
            if sub_sub_proj
              sub_sub_proj.parent = sub_proj
              puts "#{sub_sub_proj.name} |has parent| #{sub_proj.name}"
              sub_sub_proj.save!
            end
          }
        end
      end
    end

    ######update work groups##############
    puts "update work groups,it may take some time..."
    disable_authorization_checks do
      Project.all.each do |proj|
        proj.institutions.each do |i|
          proj.parent.institutions << i unless proj.parent.nil? || proj.parent.institutions.include?(i)
        end
      end
    end

  end

  private

  desc "Subscribes users to the items they would normally be subscribed to by default"
  #Run this after the subscriptions, and all subscribable classes have had their tables created by migrations
  #You can also run it any time you want to force everyone to subscribe to something they would be subscribed to by default
  task :create_default_subscriptions => :environment do
    Person.all.each do |p|
      p.set_default_subscriptions
      disable_authorization_checks { p.save(false) }
    end
  end
  
  desc "Send mail daily to users"
  task :send_daily_subscription => :environment do
    send_subscription_mails ActivityLog.scoped(:include => :activity_loggable, :conditions => ['created_at=?', Date.yesterday]), 'daily'
  end

  desc "Send mail weekly to users"
  task :send_weekly_subscription => :environment do
    send_subscription_mails ActivityLog.scoped(:include => :activity_loggable, :conditions => ['created_at>=?', 7.days.ago]), 'weekly'
  end

  desc "Send mail monthly to users"
  task :send_monthly_subscription => :environment do
    send_subscription_mails ActivityLog.scoped(:include => :activity_loggable, :conditions => ['created_at>=?', 30.days.ago]), 'monthly'
  end
  
  desc "Clears out all the lookup tables, used to speed up authorization. Use with care as they can take a while to rebuild."
  task(:clear_auth_lookup_tables=>:environment) do
    Seek::Util.authorized_types.each do |type|
      type.clear_lookup_table
    end
  end

  desc "Creates background jobs to rebuild all authorization lookup table for all users."
  task(:repopulate_auth_lookup_tables=>:environment) do
    AuthLookupUpdateJob.add_items_to_queue nil,5.seconds.from_now,1
    User.all.each do |user|
      unless AuthLookupUpdateQueue.exists?(user)
        AuthLookupUpdateJob.add_items_to_queue user,5.seconds.from_now,1
      end
    end
  end

  desc "Rebuilds all authorization tables for a given user - you are prompted for a user id"
  task(:repopulate_auth_lookup_for_user=>:environment) do
    puts "Please provide the user id:"
    user_id = STDIN.gets.chomp
    user = user_id=="0" ? nil : User.find(user_id)
    Seek::Util.authorized_types.each do |type|
      table_name = type.lookup_table_name
      ActiveRecord::Base.connection.execute("delete from #{table_name} where user_id = #{user_id}")
      assets = type.all(:include=>:policy)
      c=0
      total=assets.count
      ActiveRecord::Base.transaction do
        assets.each do |asset|
          asset.update_lookup_table user
          c+=1
          puts "#{c} done out of #{total} for #{type.name}" if c%10==0
        end
      end
      count = ActiveRecord::Base.connection.select_one("select count(*) from #{table_name} where user_id = #{user_id}").values[0]
      puts "inserted #{count} records for #{type.name}"
      GC.start
    end
  end

  desc "Creates background jobs to reindex all searchable things"
  task(:reindex_all=>:environment) do
    Seek::Util.searchable_types.each do |type|
      ReindexingJob.add_items_to_queue type.all
    end
  end

  desc "warm authorization memcache"
  task :warm_memcache=> :environment do
    klasses = Seek::Util.persistent_classes.select { |klass| klass.reflect_on_association(:policy) }.reject { |klass| klass.name == 'Permission' || klass.name.match(/::Version$/) }
    items = klasses.map do |k|
      case k.class_name
        when "Assay"
          k.scoped :include => [:owner, {:policy => {:permissions => :contributor}}]
        else
          k.scoped :include => [:contributor, {:policy => {:permissions => :contributor}}]
      end
    end

    items = items.flatten
    total = items.count
    users = User.all.sort { |a, b| a.id <=> b.id }

    items.each_with_index do |i, index|
      users.each do |u|
        puts "Total: #{total}, now: #{index} for user: #{u.id}"
        Acts::Authorized::AUTHORIZATION_ACTIONS.each do |action|
          i.send "can_#{action}?", u
          puts action
        end
      end

      Acts::Authorized::AUTHORIZATION_ACTIONS.each do |action|
        i.send "can_#{action}?", nil
      end
    end

  end

  desc "dump policy authorization caching"
  task :dump_policy_authorization_caching, :filename, :needs => :environment do |t, args|
    if args[:filename]
      FasterCSV.open("#{args[:filename]}", "w") do |csv|
        users = User.all.select { |u| u.person }
        users << nil
        users.each do |user|
          Policy.all.each do |policy|
            Acts::Authorized::AUTHORIZATION_ACTIONS.each do |action|
              person_key = user ? user.person.cache_key : nil
              cache_key = "can_#{action}?#{policy.cache_key}#{person_key}"
              val = Rails.cache.read cache_key
              csv << [person_key, policy.cache_key, action, val]
            end
          end
        end
      end
    else
      puts "please specify the dump file name... e.g. rake seek:dump_policy_authorization_caching[filename]"
      raise
    end

  end


  desc "load policy authorization caching"
  task :load_policy_authorization_caching,:filename,:needs => :environment do |t,args|
    if args[:filename]
      FasterCSV.foreach("#{args[:filename]}") do |row|
        person_key = row[0]
        policy_key = row[1]
        action = row[2]
        val = row[3].blank? ? nil : row[3].to_sym
        raise "invalid authorization value, must be either :true, :false, or nil. value: #{val.inspect} person_key: #{person_key} policy_key: #{policy_key} action: #{action}" unless [:true, :false, nil].include? val
        Rails.cache.write "can_#{action}?#{policy_key}#{person_key}", val
        end
    else
        puts "please specify the load file name... e.g. rake seek:load_policy_authorization_caching[filename]"
        raise
    end
  end


  private

  def send_subscription_mails logs, frequency
    Person.scoped(:include => :subscriptions).select { |p| p.receive_notifications? }.each do |person|
      activity_logs = person.subscriptions.scoped(:include => :subscribable).select { |s| s.frequency == frequency }.collect do |sub|
        logs.select { |log| log.activity_loggable.try(:can_view?, person.user) and log.activity_loggable.subscribable? and log.activity_loggable.subscribers_are_notified_of?(log.action) and log.activity_loggable == sub.subscribable }
      end.flatten(1)
      SubMailer.deliver_send_digest_subscription person, activity_logs unless activity_logs.blank?
    end
  end

  def set_projects_parent array, parent
    array.each do |proj|
      unless proj.nil?
        proj.parent = parent
        proj.save!
      end

    end
  end
end

