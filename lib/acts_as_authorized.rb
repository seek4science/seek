module Acts #:nodoc:
  module Authorized #:nodoc:
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    def authorization_supported?
      self.class.authorization_supported?
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
      # this method will take attributions' association and return a collection of resources,
      # to which the current resource is attributed

      def contributor_credited?
        true
      end

      def policy_or_default
        if self.policy.nil?
          self.policy = Policy.private_policy
        end
      end

      [:view, :edit, :download, :delete, :manage].each do |action|
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

      # def asset; return self; end
      # def resource; return self; end

    end
  end
end


ActiveRecord::Base.class_eval do
  include Acts::Authorized

  #I placed these here instead of active_record_extensions.rb because
  #they should only be used in conjunction with acts_as_authorized
  def contributor_credited?
    false
  end

  def can_perform? action, user=nil
    user ? send("can_#{action}?", user) : send("can_#{action}?")
  end


  def can_edit? user=nil
    true
  end

  def can_view? user=nil
    true
  end

  def can_download? user=nil
    true
  end

  def can_delete? user=nil
    true
  end

  def can_manage? user=nil
    true
  end

  validate_on_update :can_edit?
  before_destroy :can_delete?
end