#allows the current
module Acts
  module Authorized
    module CodeBasedAuthorization
      def self.included klass
        klass.extend ClassMethods
        klass.class_eval do
          has_many :special_auth_codes, :as => :asset, :required_access_to_owner => :manage
          accepts_nested_attributes_for :special_auth_codes, :allow_destroy => true
        end
      end

      ACTIONS_AUTHORIZED_BY_TEMP_LINK = [:view, :download]

      ACTIONS_AUTHORIZED_BY_TEMP_LINK.each do |action|
        eval <<-END_EVAL
          def can_#{action}? user = User.current_user
            SpecialAuthCode.current_auth_code.try(:asset) == self or super
          end
        END_EVAL
      end

      module ClassMethods
        def all_authorized_for action, user=User.current_user, projects=nil
         authorized_asset = SpecialAuthCode.current_auth_code.try(:asset)
         super_authed_items = super action, user, projects

         if ACTIONS_AUTHORIZED_BY_TEMP_LINK.include?(action) && authorized_asset && items.include?(authorized_asset) && (projects.blank? || (asset.projects.include? & projects).any?)
           super_authed_items << authorized_asset unless super_authed_items.include?(authorized_asset)
         end

         super_authed_items
        end
      end

    end
  end
end