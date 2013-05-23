#This file sets up enforcement for basic rules based on the 'can_edit?', 'can_view?', 'can_delete?', and 'can_manage?' methods
#It also provides macro style class methods for AR classes to describe common variations on the basic rules.

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
      def self.included ar
        ar.const_get(:Base).class_eval { include BaseExtensions }

      end

      module BaseExtensions
        def self.included base
          base.extend ClassMethods
          base.before_save :changes_authorized?
          base.before_destroy :destroy_authorized?
        end

        private

        def changes_authorized?
          result = true
          unless $authorization_checks_disabled
            result = authorized_changes_to_attributes? &&
                authorized_to_edit? &&
                authorized_associations_for_action? &&
                authorized_required_access_for_owner?
          end
          result
        end

        def destroy_authorized?
          result = true
          unless $authorization_checks_disabled
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
        def requires_can_manage *attrs
          self.class_attribute :attributes_requiring_can_manage unless self.respond_to?(:attributes_requiring_can_manage)
          self.attributes_requiring_can_manage ||= []
          self.attributes_requiring_can_manage = self.attributes_requiring_can_manage | attrs.map(&:to_s)
        end

        def does_not_require_can_edit *attrs
          self.class_attribute :attributes_not_requiring_edit unless self.respond_to?(:attributes_not_requiring_edit)
          self.attributes_not_requiring_edit ||= []
          self.attributes_not_requiring_edit = self.attributes_not_requiring_edit | attrs.map(&:to_s)
        end

        def enforce_authorization_on_association association,action
          self.class_attribute :associations_and_actions_to_be_enforced unless self.respond_to?(:associations_and_actions_to_be_enforced)
          self.associations_and_actions_to_be_enforced ||= {}
          self.associations_and_actions_to_be_enforced[association.to_s]=action.to_s
        end

        def enforce_required_access_for_owner association,action
          self.class_attribute :associations_requiring_access_for_owner unless self.respond_to?(:associations_requiring_access_for_owner)
          self.associations_requiring_access_for_owner ||= {}
          self.associations_requiring_access_for_owner[association.to_s]=action.to_s
        end
      end

    end
  end
end

class Object
  #Disables all authorization enforcement within the block passed to this method.
  def disable_authorization_checks
    saved = $authorization_checks_disabled
    $authorization_checks_disabled = true
    yield
  ensure
    $authorization_checks_disabled = saved
  end
end

#module Seek
#  module Permissions
#    module AuthorizationEnforcement
#      def self.included ar
#        ar.const_get(:Base).class_eval { include BaseExtensions }
#        ar.const_get(:Associations).module_eval { include OnlyWritesAuthorizedChanges }
#      end
#
#      module BaseExtensions
#        def self.included base
#          base.extend ClassMethods
#          base.before_destroy :delete_authorized?
#          base.before_save :changes_authorized?
#          base.class_inheritable_array :attributes_not_requiring_can_edit
#          base.class_inheritable_array :attributes_requiring_can_manage
#          base.class_eval {alias_method_chain :save!, :authorization_exception}
#        end
#
#        def save_with_authorization_exception! *args
#          if changes_authorized?
#            disable_authorization_checks {save_without_authorization_exception!}
#          else
#            raise "Authorization failed: #{errors.full_messages}"
#          end
#        end
#
#        # Implements rule 1 above. Used instead of using can_delete? directly,
#        # so that authorization enforcement can be disabled
#        def delete_authorized?
#          if $authorization_checks_disabled or can_delete?
#            true
#          else
#            errors[:base] << "Deleting #{self.class.name.underscore.humanize}-#{id} is not permitted"
#            false
#          end
#        end
#
#        def changes_authorized?
#          return true if $authorization_checks_disabled
#          return false if unauthorized_change_to_attributes?
#          return false if unauthorized_change_to_belongs_to?
#          return false if unauthorized_change_to_autosave?
#          true
#        end
#
#        #checks rule 2 for simple attributes
#        def unauthorized_change_to_attributes?
#          #changed includes the foreign keys of belongs_to associations. Since those are implemented by a different method, I filter them out here.
#          changed_attrs = changed - self.class.reflect_on_all_associations(:belongs_to).map(&:primary_key_name).map(&:to_s)
#          unless (changed_attrs - (attributes_not_requiring_can_edit || []).map(&:to_s)).empty? || can_edit?
#            errors[:base] << "You are not permitted to edit #{self.class.name.underscore.humanize}-#{id}"
#            return true
#          end
#          unless (changed_attrs & (attributes_requiring_can_manage || []).map(&:to_s)).empty? || can_manage?
#            errors[:base] << "You are not permitted to manage #{self.class.name.underscore.humanize}-#{id}"
#            return true
#          end
#          false
#        end
#
#        #checks rules 2 and 3 for belongs to associations
#        def unauthorized_change_to_belongs_to?
#          self.class.reflect_on_all_associations(:belongs_to).each do |reflection|
#            options = reflection.options.reverse_merge :required_access => :view, :required_access_to_owner => :edit
#            if changed.include? reflection.primary_key_name.to_s
#              unless !options[:required_access_to_owner] or can_perform? options[:required_access_to_owner]
#                errors[:base] << "You are not permitted to #{options[:required_access_to_owner]} #{self.class.name.underscore.humanize}-#{id}"
#                return true
#              end
#              unless !send(reflection.name) or !options[:required_access] or send(reflection.name).can_perform? options[:required_access]
#                errors.add reflection.primary_key_name.to_s, "must be a #{reflection.name.to_s.humanize} you can #{options[:required_access].to_s}"
#                return true
#              end
#              #TODO: need to check can_perform?(options[:required_access]) for the old value of the association as well.
#              #Tricky because of polymorphic belongs_to associations. You can get the old values of the id/type from the changes method.
#              #changes[reflection.primary_key_name].first, and changes["#{reflection.name}_type"].first
#            end
#          end
#          false
#        end
#
#        #rule 2 for changes to autosaved associations
#        def unauthorized_change_to_autosave?
#          self.class.reflect_on_all_autosave_associations.each do |reflection|
#            options = reflection.options.reverse_merge :required_access => :view, :required_access_to_owner => :edit
#            if targets = association_instance_get(reflection.name)
#              targets = [targets] unless reflection.collection?
#              if targets.detect { |record| record.changed_for_autosave? }
#                if options[:required_access_to_owner] and !can_perform?(options[:required_access_to_owner])
#                  errors[:base] << "You are not permitted to #{options[:required_access_to_owner]} #{self.class.name.underscore.humanize}-#{id}"
#                  return true
#                end
#              end
#            end
#          end
#          false
#        end
#
#        def touch
#          if changed?
#            super
#          else
#            disable_authorization_checks do
#              super
#            end
#          end
#        end
#
#        module ClassMethods
#          #does not require can_edit isn't the best name..
#          #really the meaning is that changing the listed
#          #attributes doesn't count as 'editing'
#          def does_not_require_can_edit *attrs
#            self.attributes_not_requiring_can_edit = attrs
#          end
#
#          #requires can_manage really means that 'changing these attributes counts as trying to manage'
#          def requires_can_manage *attrs
#            self.attributes_requiring_can_manage = attrs
#          end
#        end
#      end
#
#      #This module enforces Authorization rules by selectively ignoring attempts to write to the database via association proxies.
#      #By default 'view' access is required on the target record, and 'edit' access for the owner of the association.
#      #This can be customized by passing :required_access and/or :required_access_to_owner
#      #For example:
#      #class DataFile
#      #   has_and_belongs_to_many :assays, :required_access => :edit
#      #end
#      #This means that removing/adding assays with the association requires that you 'can_edit?' the assay. This option can be set to false for
#      #associations that do not want the default level of enforcement.
#      module OnlyWritesAuthorizedChanges
#        def self.included mod
#          mod.const_get(:AssociationCollection).class_eval { include AssociationCollectionExtensions }
#        end
#
#        #parent.association= updates the database instantly in certain cases, without triggering any callbacks or validations on the parent,
#        #so rules regarding those associations are enforced here, by ignoring inappropriate modifications.
#        #BelongsTo was deliberately excluded because changes to BelongTo associations never save until parent.save is called.
#        #TODO: has_one
#
#        module AssociationCollectionExtensions
#          def self.included base
#            base.class_eval do
#              alias_method_chain :concat, :ignore_unauthorized
#              alias_method :<<, :concat
#              alias_method :push, :concat
#
#              alias_method_chain :delete, :ignore_unauthorized
#            end
#          end
#
#          def concat_with_ignore_unauthorized *args
#            concat_without_ignore_unauthorized remove_unauthorized_changes(args)
#          end
#
#          def delete_with_ignore_unauthorized *args
#            delete_without_ignore_unauthorized remove_unauthorized_changes(args)
#          end
#
#          private
#          def remove_unauthorized_changes args
#            unless $authorization_checks_disabled
#              options = @reflection.options.reverse_merge :required_access => :view, :required_access_to_owner => :edit
#              args = [] if options[:required_access_to_owner] && !@owner.can_perform?(options[:required_access_to_owner])
#              args = flatten_deeper(args).select { |record| record.can_perform? options[:required_access] } if options[:required_access]
#            end
#            args
#          end
#
#        end
#      end
#
#    end
#  end
#end
#
#ActiveRecord::Associations::ClassMethods.module_eval do
#  valid_keys_for_has_many_association << :required_access
#  valid_keys_for_has_many_association << :required_access_to_owner
#  valid_keys_for_has_and_belongs_to_many_association << :required_access
#  valid_keys_for_has_and_belongs_to_many_association << :required_access_to_owner
#  valid_keys_for_belongs_to_association << :required_access
#  valid_keys_for_belongs_to_association << :required_access_to_owner
#end
#
#class Object
#  #Disables all authorization enforcement within the block passed to this method.
#  def disable_authorization_checks
#    saved = $authorization_checks_disabled
#    $authorization_checks_disabled = true
#    yield
#  ensure
#    $authorization_checks_disabled = saved
#  end
#end
