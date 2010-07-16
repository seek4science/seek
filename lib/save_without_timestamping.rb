class ActiveRecord::Base
  def save_without_timestamping
    class << self
      def record_timestamps; false; end
    end
  
    truth = save
  
    class << self
      remove_method :record_timestamps
    end
    truth
  end
end