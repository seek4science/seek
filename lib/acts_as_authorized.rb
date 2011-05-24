module Acts #:nodoc:
  module Authorized #:nodoc:
    def self.included(mod)
      mod.extend(ClassMethods)
      mod.before_destroy :delete_authorized?
      mod.before_update :changes_authorized?
    end

    def authorization_supported?
      self.class.authorization_supported?
    end

    def contributor_credited?
      false
    end

    def can_perform? action, user=nil
      user ? send("can_#{action}?", user) : send("can_#{action}?")
    end

    def publish!
      if can_manage?
        policy.access_type=Policy::ACCESSIBLE
        policy.sharing_scope=Policy::EVERYONE
        policy.save
      else
        false
      end
    end

    def is_published?
      #FIXME: a temporary work-around for the lack of ability to use can_download? as a non logged in user (passing nil defaults to User.current_user)
      Authorization.is_authorized? "download",nil,self,nil
    end

    AUTHORIZATION_ACTIONS = [:view, :edit, :download, :delete, :manage]
    AUTHORIZATION_ACTIONS.each do |action|
      define_method "can_#{action}?" do
        true
      end
    end

    def attributes_requiring_can_edit
      attributes.keys.map(&:to_sym) - (try_block{attributes_not_requiring_can_edit} || [])
    end

    def changes_requiring_can_edit
      changed_attributes.dup.delete_if {|key,v| !attributes_requiring_can_edit.include? key.to_sym}
    end

    def attributes_requiring_can_manage()
      []
    end

    def changes_requiring_can_manage
      changed_attributes.dup.delete_if {|key,v| !attributes_requiring_can_manage.include? key.to_sym}
    end

    def changes_authorized?
      $authorization_checks_disabled or changes_requiring_can_edit.empty? || can_edit? and changes_requiring_can_manage.empty? || can_manage?
    end

    def delete_authorized?
      $authorization_checks_disabled or can_delete?
    end

    module ClassMethods
      def acts_as_authorized
        belongs_to :contributor, :polymorphic => true  unless method_defined? :contributor
        after_initialize :contributor_or_default_if_new

        does_not_require_can_edit :uuid, :first_letter
        #checks a policy exists, and if missing resorts to using a private policy
        after_initialize :policy_or_default_if_new

        belongs_to :project  unless method_defined? :project

        belongs_to :policy, :autosave => true

        class_eval do
          extend Acts::Authorized::SingletonMethods
        end
        include Acts::Authorized::InstanceMethods

      end

      def standard_attribute_requires_can_manage *attrs
        unless defined? :attributes_requiring_can_manage
          cattr_accessor :attributes_requiring_can_manage
          self.attributes_requiring_can_manage = attrs
        else
          attributes_requiring_can_manage.concat attrs
        end
      end

      #does not require can_edit isn't the best name..
      #really the meaning is that changing the listed
      #attributes doesn't count as 'editing'
      def does_not_require_can_edit *attrs
        unless defined? attributes_not_requiring_can_edit
          cattr_accessor :attributes_not_requiring_can_edit
          self.attributes_not_requiring_can_edit = attrs
        else
          attributes_not_requiring_can_edit.concat attrs
        end
      end

      #requires can_manage really means that 'changing these attributes counts as trying to manage'
      def requires_can_manage *attrs
        standard_attribute_requires_can_manage *attrs
      end

      def authorization_supported?
        include?(Acts::Authorized::InstanceMethods)
      end
    end

    module SingletonMethods
    end

    module InstanceMethods
      def contributor_credited?
        true
      end

      def default_policy
        Policy.default
      end

      def policy_or_default
        if self.policy.nil?
          self.policy = default_policy
        end
      end

      def policy_or_default_if_new
        if self.new_record?
          policy_or_default
        end
      end

      def default_contributor
        User.current_user
      end

      def contributor_or_default_if_new
        if self.new_record? && contributor.nil?
          self.contributor = default_contributor
        end
      end

      AUTHORIZATION_ACTIONS.each do |action|
        define_method "can_#{action}?" do |*args|
          user = args[0] || User.current_user
          new_record? or Authorization.is_authorized? action.to_s, nil, self, user
        end
      end

      #returns a list of the people that can manage this file
      #which will be the contributor, and those that have manage permissions
      def managers
        #FIXME: how to handle projects as contributors - return all people or just specific people (pals or other role)?
        people=[]
        unless self.contributor.nil?
          people << self.contributor.person if self.contributor.kind_of?(User)
          people << self.contributor if self.contributor.kind_of?(Person)
        end

        self.policy.permissions.each do |perm|
          unless perm.contributor.nil? || perm.access_type!=Policy::MANAGING
            people << (perm.contributor) if perm.contributor.kind_of?(Person)
            people << (perm.contributor.person) if perm.contributor.kind_of?(User)
          end
        end
        people.uniq
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Acts::Authorized
end

module OnlyWritesVisible

  def concat_with_ignore_invisible *args
    args = flatten_deeper(args).select {|record| record.can_view?} unless $authorization_checks_disabled
    concat_without_ignore_invisible *args
  end

  def delete_with_ignore_invisible *args
    args = flatten_deeper(args).select {|record| record.can_view?} unless $authorization_checks_disabled
    delete_without_ignore_invisible *args
  end

  def self.included base
    base.class_eval do
      alias_method_chain :concat, :ignore_invisible
      alias_method :<<, :concat
      alias_method :push, :concat

      alias_method_chain :delete, :ignore_invisible
    end
  end
end

ActiveRecord::Associations::AssociationCollection.class_eval do
  include OnlyWritesVisible
end

class Object
  def disable_authorization_checks
    saved = $authorization_checks_disabled
    $authorization_checks_disabled = true
    yield ensure $authorization_checks_disabled = saved
  end
end

