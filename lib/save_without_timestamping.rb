class ActiveRecord::Base
  def save_without_timestamping
    class << self
      def record_timestamps; false; end
    end
  
    save
  
    class << self
      remove_method :record_timestamps
    end
  end
end