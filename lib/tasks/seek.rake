require 'rubygems'
require 'rake'
require 'active_record/fixtures'



namespace :seek do

  desc 'an alternative to the doc:seek task'
  task(:docs=>["doc:seek"])

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

  #reverts to use pre-2.3.4 id generation to keep generated ID's consistent
  def revert_fixtures_identify
    def Fixtures.identify(label)
      label.to_s.hash.abs
    end
  end

  desc "Subscribes users to the items they would normally be subscribed to by default"
  #Run this after the subscriptions, and all subscribable classes have had their tables created by migrations
  #You can also run it any time you want to force everyone to subscribe to something they would be subscribed to by default
  task :create_default_subscriptions => :environment do
    People.each do |p|
      p.set_default_subscriptions
      disable_authorization_checks {p.save(false)}
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

  private

  def send_subscription_mails logs, frequency
    Person.scoped(:include => :subscriptions).select{|p|p.receive_notifications?}.each do |person|
      activity_logs = person.subscriptions.scoped(:include => :subscribable).select{|s|s.frequency == frequency}.collect do |sub|
         logs.select{|log|log.activity_loggable.try(:can_view?, person.user) and log.activity_loggable.subscribable? and log.activity_loggable.subscribers_are_notified_of?(log.action) and log.activity_loggable == sub.subscribable}
      end.flatten(1)
      SubMailer.deliver_send_digest_subscription person, activity_logs unless activity_logs.blank?
    end
  end

end
