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

      #See http://stackoverflow.com/questions/5569176/rails-accepts-nested-attributes-for-destroy-doesnt-work-unless-associations-are
      #accepts_nested_attributes_for doesn't properly handle _destroy unless the association has already been loaded.
      #
      # I haven't figured out what the underlying problem is, but line 360 in active_record/nested_attributes.rb seems like a good place to start.
      # Also, check out the definition of 'load_target' in AssociationCollection(line 352 of association_collection). It tosses out anything in
      # 'target' except for new records, so any 'existing records' in the unloaded @target array will be lost, even if they have modifications
      # for autosave (or are marked for destruction).
      #
      #This works around the problem by wrapping the #{association_name}_attributes= methods generated and loading the association forcibly.
      def self.accepts_nested_attributes_for_with_allow_destroy_bugfix *attr_names
        attr_names_copy = attr_names.dup #preserve the original unmodified args for the original method
        options = attr_names_copy.extract_options!
        accepts_nested_attributes_for_without_allow_destroy_bugfix *attr_names
        if options[:allow_destroy]
          attr_names_copy.each do |association_name|
            class_eval <<-EOS, __FILE__, __LINE__ + 1
              def #{association_name}_attributes_with_allow_destroy_bugfix=(*args)
                #{association_name}.send :load_target unless #{association_name}.loaded?
                self.#{association_name}_attributes_without_allow_destroy_bugfix = *args
              end
              alias_method_chain :#{association_name}_attributes=, :allow_destroy_bugfix
            EOS
          end
        end
      end

      def self.is_taggable?
        self.ancestors.include?(Seek::Taggable)
      end

      class_alias_method_chain :accepts_nested_attributes_for, :allow_destroy_bugfix

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
    is_downloadable? && Seek::Config.publish_button_enabled
  end

  def is_versioned?
    respond_to? :versions
  end

end

ActiveRecord::Base.class_eval do
  include ActiveRecordExtensions
end