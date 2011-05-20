module ActiveRecordExtensions

  def self.included base
    base.class_eval do
      #if after_initialize() is not an instance method, then the after_initialize callbacks don't get run.
      #this changes the after_initialize class method used to define the callbacks, so that it will
      #define the instance method if it does not exist
      def self.after_initialize_with_ensure_base_exists *args
        define_method(:after_initialize) {} unless method_defined? :after_initialize
        after_initialize_without_ensure_base_exists *args
      end

      class_alias_method_chain :after_initialize, :ensure_base_exists
    end
  end

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

  def show_contributor_avatars?
    self.respond_to?(:contributor) || self.respond_to?(:creators)
  end

  def is_downloadable?
    respond_to?(:content_blob)
  end

  def is_publishable?
    #currently based upon the naive assumption that downloadable items are publishable, which is currently the case but may change.
    is_downloadable?
  end
  
end

ActiveRecord::Base.class_eval do
  include ActiveRecordExtensions
end