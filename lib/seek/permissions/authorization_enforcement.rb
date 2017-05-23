# This file sets up enforcement for basic rules based on the 'can_edit?', 'can_view?', 'can_delete?', and 'can_manage?' methods
# It also provides macro style class methods for AR classes to describe common variations on the basic rules.

# 1. An instance of an AR class may not be destroyed unless instance.can_delete? returns true.
# 2. An instance of an AR class may not have its attributes/associations changed unless instance.can_edit? returns true.
# 3. An association may not be set to, or unset from, an instance unless instance.can_view? returns true.
#    for example.. @assay.investigation = @investigation is only permitted when @investigation.can_view? is true,
#    and when the original @assay.investigation.can_view? is true. This rule also applies to collections, so
#    @data_file.events = [@event] requires @event.can_view? (unless the collection already contained that event)
#    and any events removed by that action must also return true for can_view?

# can_manage? behaves identically to can_edit? but only for specific attributes/associations

# Note: Attempts to violate these rules don't always result in complete failure or exceptions.
#       Attempting to set @data_file.events = [@event] can be partially successful, removing/adding events which do
#       return true for can_view? while ignoring the rest.

module Seek
  module Permissions
    module AuthorizationEnforcement
      def self.included(ar)
        ar.const_get(:Base).class_eval { include BaseExtensions }
      end

      module BaseExtensions
        def self.included(base)
          base.extend ClassMethods
          base.before_save :changes_authorized?
          base.before_destroy :destroy_authorized?
        end

        private

        def changes_authorized?
          result = true
          if authorization_checks_enabled
            result = authorized_changes_to_attributes? &&
                     authorized_to_edit? &&
                     authorized_associations_for_action? &&
                     authorized_required_access_for_owner?
          end
          result
        end

        def authorization_checks_enabled
          !$authorization_checks_disabled && Seek::Config.authorization_checks_enabled
        end

        def destroy_authorized?
          result = true
          if authorization_checks_enabled
            unless can_delete?
              result = false
              errors.add(:base, "You are not authorized to destroy #{self.class.name.underscore.humanize}-#{id}")
            end
          end
          result
        end

        def authorized_changes_to_attributes?
          if self.class.respond_to?(:attributes_requiring_can_manage) && !self.class.attributes_requiring_can_manage.empty? && !can_manage?
            authorized_changes_requiring_manage?
          else
            true
          end
        end

        def authorized_to_edit?
          result = true
          unless safe_to_edit?
            result = false
            errors.add(:base,"You are not authorized to edit #{self.class.name.underscore.humanize}-#{id}")
          end
          result
        end

        def authorized_associations_for_action?
          result = true
          if self.class.respond_to?(:associations_and_actions_to_be_enforced)
            self.class.associations_and_actions_to_be_enforced.keys.each do |association|
              if self.respond_to?(association)
                action = self.class.associations_and_actions_to_be_enforced[association]
                auth_method = "can_#{self.class.associations_and_actions_to_be_enforced[association]}?"
                Array(self.send(association)).each do |item|
                  if item.respond_to?(auth_method) && !item.send(auth_method)
                    result = false
                    errors.add(:base,"You do not have permission to #{action} #{item.class.name.underscore.humanize}-#{item.id}")
                    break
                  end
                end
              end
            end
          end

          result
        end

        def authorized_required_access_for_owner?
          result = true
          if self.class.respond_to?(:associations_requiring_access_for_owner)
            enforced_associations = self.class.associations_requiring_access_for_owner.keys
            unless enforced_associations.empty?

              autosave_associations = self.class.reflect_on_all_autosave_associations.select do |reflection|
                enforced_associations.include?(reflection.name.to_s)
              end
              autosave_associations.each do |reflection|
                if associations = association_instance_get(reflection.name)
                  associations = Array(associations)
                  if associations.detect {|association| association.target.changed_for_autosave?}
                    action = self.class.associations_requiring_access_for_owner[reflection.name.to_s]
                    action_method = "can_#{action}?"
                    if self.respond_to?(action_method) && !self.send(action_method)
                      result = false
                      errors.add(:base,"You are not permitted to change #{reflection.name} on #{self.class.name.underscore.humanize}-#{id} without #{action} rights")
                      break
                    end
                  end
                end
              end
            end
          end

          result
        end

        def authorized_changes_requiring_manage?
          offending_attributes = changed & self.class.attributes_requiring_can_manage
          unless offending_attributes.empty?
            errors.add(:base,"You are not permitted to change #{offending_attributes.join(",")} attributes on #{self.class.name.underscore.humanize}-#{id} without manage rights")
          end
          offending_attributes.empty?
        end

        def safe_to_edit?
          not_requiring_edit = self.class.respond_to?(:attributes_not_requiring_edit) ? self.class.attributes_not_requiring_edit : []
          can_edit? || (changed - not_requiring_edit).empty?
        end
      end

      module ClassMethods
        def requires_can_manage(*attrs)
          self.class_attribute :attributes_requiring_can_manage unless self.respond_to?(:attributes_requiring_can_manage)
          self.attributes_requiring_can_manage ||= []
          self.attributes_requiring_can_manage = self.attributes_requiring_can_manage | attrs.map(&:to_s)
        end

        def does_not_require_can_edit(*attrs)
          self.class_attribute :attributes_not_requiring_edit unless self.respond_to?(:attributes_not_requiring_edit)
          self.attributes_not_requiring_edit ||= []
          self.attributes_not_requiring_edit = self.attributes_not_requiring_edit | attrs.map(&:to_s)
        end

        def enforce_authorization_on_association(association,action)
          self.class_attribute :associations_and_actions_to_be_enforced unless self.respond_to?(:associations_and_actions_to_be_enforced)
          self.associations_and_actions_to_be_enforced ||= {}
          self.associations_and_actions_to_be_enforced[association.to_s]=action.to_s
        end

        def enforce_required_access_for_owner(association,action)
          self.class_attribute :associations_requiring_access_for_owner unless self.respond_to?(:associations_requiring_access_for_owner)
          self.associations_requiring_access_for_owner ||= {}
          self.associations_requiring_access_for_owner[association.to_s]=action.to_s
        end
      end
    end
  end
end

class Object
  # Disables all authorization enforcement within the block passed to this method.
  def disable_authorization_checks
    saved = $authorization_checks_disabled
    $authorization_checks_disabled = true
    yield
  ensure
    $authorization_checks_disabled = saved
  end
end

ActiveRecord.module_eval do
  include Seek::Permissions::AuthorizationEnforcement
end
