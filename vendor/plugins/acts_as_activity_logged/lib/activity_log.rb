class ActivityLog < ActiveRecord::Base
  
  belongs_to :activity_loggable, :polymorphic => true
  belongs_to :referenced, :polymorphic => true
  belongs_to :culprit, :polymorphic => true
  
  serialize :data

  alias the_culprit culprit
  def culprit(options="nil")
    options.to_sym == :value ? 
      ((defined? l_klass.models[:culprit] && defined? l_klass.models[:culprit][:method]) ?
        the_culprit.send(l_klass.models[:culprit][:method].to_s) :
        "You must set a :method in the options to use this") : 
      the_culprit
  rescue
    return nil
  end
  
  alias the_referenced referenced
  def referenced(options="nil")
    options.to_sym == :value ? 
      ((defined? l_klass.models[:referenced] && defined? l_klass.models[:referenced][:method]) ?
        the_referenced.send(l_klass.models[:referenced][:method].to_s) :
        "You must set a :method in the options to use this") :
        the_referenced
  rescue
    return nil
  end

  alias the_activity_loggable activity_loggable
  def activity_loggable(options="nil")
    options.to_sym == :value ? 
      ((defined? l_klass.models[:activity_loggable] && defined? l_klass.models[:activity_loggable][:method]) ?
        the_activity_loggable.send(l_klass.models[:activity_loggable][:method].to_s) :
        "You must set a :method in the options to use this") :
        the_activity_loggable
  rescue
    return nil
  end
  
  def self.latest(limit=5)
    self.find(:all, :limit => limit)
  end
  
  # options are :culprit, :referenced, :activity_loggable, :limit
  def self.find_with(options={})
    limit = (options.delete(:limit) || 10)
    order = options.delete(:order)
    if options.keys.include? :additional
      additionals = options[:additional].is_a?(Array) ? options[:additional] : [options[:additional]]
    end
    options.delete(:additional)
    conditions = self.build_sql_conditional_for(options)
    conditions << (conditions ? " AND " : "") << additionals.join(" #{@operator || "AND"} ") if additionals
    self.find(:all, :conditions => conditions, :limit => limit, :order => order)
  end

private
  def self.build_sql_conditional_for(options={})
    conditions = []
    @operator = options.delete(:operator)
    options.each do |key, value|
      conditions << self.send(:sanitize_sql, ["#{key.to_s}_id IN (?)", value])
    end
    return conditions.join(" #{@operator || "AND"} ")
  end

  def l_klass
    Object.const_get(self.activity_loggable_type.to_s)
  end
  
  def r_klass
    Object.const_get(self.referenced_type.to_s)
  end
  
  def c_klass
    Object.const_get(self.culprit_type.to_s)
  end
end