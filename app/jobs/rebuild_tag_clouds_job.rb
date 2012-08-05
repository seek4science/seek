class RebuildTagCloudsJob


  @@my_yaml = RebuildTagCloudsJob.new.to_yaml

  def perform
    keys = ["sidebar_tag_cloud","suggestions_for_tag","suggestions_for_expertise","suggestions_for_tool"]
    keys.each do |key|
      ApplicationController.new.expire_fragment key
    end
  end

  def self.exists?
    count!=0
  end

  def self.create_job priority=2,t=15.minutes.from_now
    Delayed::Job.enqueue(RebuildTagCloudsJob.new,priority,t) unless exists?
  end

  def self.count
    Delayed::Job.find(:all,:conditions=>['handler = ? AND locked_at IS ?',@@my_yaml,nil]).count
  end
end