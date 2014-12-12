module Seek
  class ActivityStats   
    
    #the time periods to be tested
    PERIODS={"daily"=>1.day.ago,"weekly"=>1.week.ago,"monthly"=>1.month.ago,"six_monthly"=>6.month.ago,"yearly"=>1.year.ago}
    
    #the item types to include
    INCLUDED_TYPES=["Sop","Model","Publication","DataFile","Assay","Study","Investigation","Presentation"]
    
    def initialize
      create_attributes
      
      logs = ActivityLog.where(["(action = ? or action = ?)","create","download"])
      logs.each do |log|
        next unless INCLUDED_TYPES.include?(log.activity_loggable_type)
        action=""      
        case log.action
          when "create"
          action="created"
          when "download"
          action="downloaded"
        end      
        
        PERIODS.keys.each do |period_key|
          if log.created_at > PERIODS[period_key]
            attribute="@#{period_key}_#{log.activity_loggable_type.downcase.pluralize}_#{action}"          
            eval("#{attribute} += 1")
          end
        end
        
      end    
    end

    def six_monthly_users
      distinct_culprits_since 6.month.ago
    end
    
    def monthly_users
      distinct_culprits_since 1.month.ago
    end
    
    def weekly_users
      distinct_culprits_since 1.week.ago
    end
    
    def alltime_users
      distinct_culprits_since
    end
    
    def daily_users
      distinct_culprits_since 1.day.ago
    end 
    
    def yearly_users
      distinct_culprits_since 1.year.ago
    end

    private  
    
    def create_attributes
      ["created","downloaded"].each do |action|
        PERIODS.keys.each do |period|
          INCLUDED_TYPES.each do |type|
            attribute="#{period}_#{type.downcase.pluralize}_#{action}"
            self.class.class_eval { attr_accessor attribute.intern }
            instance_variable_set "@#{attribute}".intern, 0
          end
        end        
      end
    end  
    
    def distinct_culprits_since time=500.years.ago
      ActivityLog.where(["created_at > ?",time]).select("distinct culprit_id").count
    end

  end
end