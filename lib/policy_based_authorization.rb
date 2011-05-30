module Acts
  module Authorized
    module PolicyBasedAuthorization
      def self.included klass
        klass.extend ClassMethods
        klass.class_eval do
          belongs_to :contributor, :polymorphic => true unless method_defined? :contributor
          after_initialize :contributor_or_default_if_new

          #wrapped in try_block in case the AuthorizationEnforcement module has not been included into ActiveRecord.
          try_block { does_not_require_can_edit :uuid, :first_letter }

          #checks a policy exists, and if missing resorts to using a private policy
          after_initialize :policy_or_default_if_new

          belongs_to :project unless method_defined? :project

          belongs_to :policy, :required_access_to_owner => :manage, :autosave => true
        end
      end

      module ClassMethods
      end

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
        eval <<-END_EVAL
          def can_#{action}? user = User.current_user
            new_record? or Authorization.is_authorized? "#{action}", nil, self, user
          end
        END_EVAL
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