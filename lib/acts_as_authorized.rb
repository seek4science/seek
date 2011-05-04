module Acts #:nodoc:
  module Authorized #:nodoc:
    def self.included(mod)
      mod.extend(ClassMethods)
      mod.before_destroy :can_delete?
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

    AUTHORIZATION_ACTIONS = [:view, :edit, :download, :delete, :manage]
    AUTHORIZATION_ACTIONS.each do |action|
      define_method "can_#{action}?" do
        true
      end
    end

    def can_edit_attributes() attributes.keys.map(&:to_sym) end
    def changes_requiring_can_edit
      changed_attributes.dup.delete_if {|key,v| !can_edit_attributes.include? key.to_sym}
    end

    def can_manage_attributes() [] end
    def changes_requiring_can_manage
      changed_attributes.dup.delete_if {|key,v| !can_manage_attributes.include? key.to_sym}
    end

    def changes_authorized?
      (changes_requiring_can_edit.empty? || can_edit?) and (changes_requiring_can_manage.empty? || can_manage?)
    end

    module ClassMethods
      def acts_as_authorized
        belongs_to :contributor, :polymorphic => true

        #checks a policy exists, and if missing resorts to using a private policy
        before_save :policy_or_default

        belongs_to :project

        belongs_to :policy

        class_eval do
          extend Acts::Authorized::SingletonMethods
        end
        include Acts::Authorized::InstanceMethods

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

      def can_edit_attributes
        super - [:uuid, :first_letter]
      end

      def policy_or_default
        if self.policy.nil?
          self.policy = Policy.private_policy
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
        people=[]
        people << self.contributor.person unless self.contributor.nil?
        self.policy.permissions.each do |perm|
          people << (perm.contributor) if perm.contributor.kind_of?(Person) && perm.access_type==Policy::MANAGING
        end
        people.uniq
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Acts::Authorized
end