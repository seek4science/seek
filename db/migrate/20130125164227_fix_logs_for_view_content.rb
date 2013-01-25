class FixLogsForViewContent < ActiveRecord::Migration
  class ActivityLog < ActiveRecord::Base ;end

  def self.up
    to_fix = ActivityLog.find(:all,:conditions=>{:action=>"download",:controller_name=>"content_blobs"})
    to_fix.each do |log|
      log.action="inline_view"
      class << log
        def record_timestamps
          false
        end
      end
      log.save
    end
  end

  def self.down
    to_undo = ActivityLog.find(:all,:conditions=>{:action=>"inline_view",:controller_name=>"content_blobs"})
    to_undo.each do |log|
      log.action="download"
      class << log
        def record_timestamps
          false
        end
      end
      log.save
    end
  end
end
