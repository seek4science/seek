
module ActiveRecordExtensions

  def defines_own_avatar?
    respond_to?(:avatar)
  end

  def use_mime_type_for_avatar?
    false
  end

  def avatar_key
    thing = self
    thing = thing.parent if thing.class.name.include?("::Version")
    return nil if thing.use_mime_type_for_avatar? || thing.defines_own_avatar?
    "#{thing.class.name.underscore}_avatar"
  end
  
end

ActiveRecord::Base.class_eval do
  include ActiveRecordExtensions
end