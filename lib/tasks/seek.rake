require 'rubygems'
require 'rake'
require 'active_record/fixtures'



namespace :seek do

  desc 'an alternative to the doc:seek task'
  task(:docs=>["doc:seek"])

  desc 'set age_unit to be week for Virtual Liver old specimens which use week as age unit'
  task(:update_age_unit => :environment) do
    Specimen.all.each do |sp|
      sp.age_unit = "week" unless sp.age_unit
      disable_authorization_checks do
        sp.save!
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
        matching = tags.select{|t| t.name.downcase.strip == tag.name.downcase.strip && t.id != tag.id}
        unless matching.empty?
          matching.each do |m|
            puts "#{m.name}(#{m.id}) - #{tag.name}(#{tag.id})"
            m.taggings.each do |tagging|
              unless tag.taggings.detect{|t| t.context==tagging.context && t.taggable==tagging.taggable}
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

  private

  desc "Subscribes users to the items they would normally be subscribed to by default"
  #Run this after the subscriptions, and all subscribable classes have had their tables created by migrations
  #You can also run it any time you want to force everyone to subscribe to something they would be subscribed to by default
  task :create_default_subscriptions => :environment do
    People.each do |p|
      p.set_default_subscriptions
      disable_authorization_checks {p.save(:validate=>false)}
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
      ReindexingJob.add_items_to_queue type.all, 5.seconds.from_now,2
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
    FileUtils.rm_r(Dir['filestore/tmp/*'])
  end

end
