require 'rubygems'
require 'rake'
require 'time'
require 'active_record/fixtures'



require 'csv'

namespace :seek do

  desc 'an alternative to the doc:seek task'
  task(:docs=>["doc:seek"])

  desc 'set age_unit to be week for Virtual Liver old specimens which use week as age unit'
  task(:update_age_unit => :environment) do
    DeprecatedSpecimen.all.each do |sp|
      sp.age_unit = "week" unless sp.age_unit
      disable_authorization_checks do
        sp.save!
      end
    end
  end

  desc 'updates the md5sum, and makes a local cache, for existing remote assets'
  task(:cache_remote_content_blobs=>:environment) do
    resources = Sop.all
    resources |= Model.all
    resources |= DataFile.all
    resources = resources.select { |r| r.content_blob && r.content_blob.data.nil? && r.content_blob.url && !r.projects.empty? }

    resources.each do |res|
      res.cache_remote_content_blob
    end
  end

  task(:tissue_and_cell_types=>:environment) do
    revert_fixtures_identify
    TissueAndCellType.delete_all
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "tissue_and_cell_types")
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
    ["Showcase HGF and Regeneration", "Showcase LPS and Inflammation", "Showcase Steatosis", "Showcase LIAM (Liver Image Analysis Based Model)"].each do |name|
      proj = Project.find_by_name name
      if proj and show_case
        proj.parent = show_case
        puts "#{proj.name} |has parent| #{show_case.name}"
        proj.save!
      else
        puts "Project #{name} or #{show_case.name} not found!"
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
      else
        puts "Project #{name} or #{project_mt.name} not found!"
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
      set_default_subscriptions  p
      disable_authorization_checks {p.save(:validate=>false)}
    end
  end
  
  desc "Creates background jobs to rebuild all authorization lookup table for all users."
  task(:repopulate_auth_lookup_tables=>:environment) do
    AuthLookupUpdateJob.new.add_items_to_queue nil,5.seconds.from_now,1
    User.all.each do |user|
      unless AuthLookupUpdateQueue.exists?(user)
        AuthLookupUpdateJob.new.add_items_to_queue user,5.seconds.from_now,1
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
      ReindexingJob.new.add_items_to_queue type.all, 5.seconds.from_now,2
    end
  end

  desc "Initialize background jobs for sending subscription periodic emails"
  task(:send_periodic_subscription_emails=>:environment) do
    SendPeriodicEmailsJob.create_initial_jobs
  end

  desc "Add new unit"
  task(:add_unit=>:environment) do
    puts "You are about to add new unit, please provide the following information. The one marked with * is mandatory"
    puts "(If you add time unit, please give the value of comment: time)"
    puts "title*:"
    title = STDIN.gets.chomp
    puts "symbol*:"
    symbol = STDIN.gets.chomp
    puts "comment:"
    comment = STDIN.gets.chomp
    puts "order position:"
    order = STDIN.gets.chomp
    #if order is provided, update the order of some current units before adding new unit
    if !order.blank?
      order = order.to_i
      units = Unit.all.select{|u| u.order >= order}
      units.each do |u|
         u.order += 1
         u.save
      end
    #otherwise take the last_order + 1
    else
      last_order = Unit.all.sort_by(&:order).last.order
      order =  last_order + 1
    end
    Unit.create(:title => title, :symbol => symbol, :order => order, :comment => comment)
    puts "New unit is added"
  end

  task(:clear_filestore_tmp => :environment) do
    FileUtils.rm_r(Dir["#{Seek::Config.temporary_filestore_path}/*"])
  end

  
  desc "warm authorization memcache"
  task :warm_memcache=> :environment do
    klasses = Seek::Util.persistent_classes.select { |klass| klass.reflect_on_association(:policy) }.reject { |klass| klass.name == 'Permission' || klass.name.match(/::Version$/) }
    items = klasses.map(&:all).flatten
    users = User.all.select(&:person)
    actions = Acts::Authorized::AUTHORIZATION_ACTIONS.map {|a| "can_#{a}?"}

    Rails.logger.silence do
      items.product(users).each do |i, u|
        actions.each do |a|
          i.send a, u
        end
      end
    end
  end

  desc "dump policy authorization caching"
  task :dump_policy_authorization_caching, [:filename] => :environment do |t, args|
    filename = args[:filename] ? args[:filename].to_s : 'cache_dump.yaml'

    klasses = Seek::Util.persistent_classes.select { |klass| klass.reflect_on_association(:policy) }.reject { |klass| klass.name == 'Permission' || klass.name.match(/::Version$/) }
    items = klasses.map(&:all).flatten.map(&:cache_key)
    people = User.all.map(&:person).compact.map(&:cache_key)
    actions = Acts::Authorized::AUTHORIZATION_ACTIONS.map {|action| "can_#{action}?"}
    auth_keys = people.product(actions, items).map(&:to_s)
    auth_hash = {}
    auth_keys.each_slice(150000) {|keys| auth_hash.merge! Rails.cache.read_multi(*keys)}
    puts "Printing"
    File.open(filename, 'w') do |f|
      f.print(YAML::dump(auth_hash))
    end
  end


  desc "load policy authorization caching"
  task :load_policy_authorization_caching,[:filename] => :environment do |t,args|
    filename = args[:filename] ? args[:filename].to_s : 'cache_dump.yaml'
    YAML.load(File.read(filename.to_s)).each_pair {|k,v| Rails.cache.write(k,v)}
  end

  desc("Synchronised the assay and technology types assigned to assays according to the current ontology, resolving any suggested types that have been added")
  task(:resynchronise_ontology_types=>[:environment,"tmp:create"]) do
    synchronizer = Seek::Ontologies::Synchronize.new
    synchronizer.synchronize_assay_types
    synchronizer.synchronize_technology_types
  end

  def set_projects_parent array, parent
    array.each do |proj|
      unless proj.nil?
        proj.parent = parent
        proj.save!
      end

    end
  end
  def set_default_subscriptions person
    person.projects.each do |proj|
      person.project_subscriptions.build :project => proj
    end
  end

end

