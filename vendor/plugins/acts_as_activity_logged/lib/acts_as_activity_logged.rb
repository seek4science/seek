# Copyright (c) 2006 New Bamboo
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# Modified in October 2008 by Sergejs Aleksejevs for work on
# myExperiment (www.myexperiment.org)
#
# Modifications:
# 1) migration made compatible with Rails 1.2.6 (as well as Rails 2.0);
# 2) changed the way the actual ActivityLog entry is created;
# 3) "activity_loggable" now always is the current instance of the model,
#    that is => "self" in the context of this module;
# 4) introduced filtering of events to log, so the module will accept
#    an additional parameter (":check_log_allowed => true") indicating
#    that a callback method ("self.log_allowed()") within the
#    model is available, running which would return a boolean result,
#    used to decide if this event is to be logged or not based on the current
#    state of the model.
# 5) polymorphic associations in the models are now treated better and cleaner when
#    logging the events - for "culprit" and "referenced"
# 6) if the exception is thrown during logging a particular event, it is caught
#    and added to regular error log ("logger.error") - incomplete entry in ActivityLog
#    table is created in this case


module NewBamboo #:nodoc:
  module Acts #:nodoc:
    # Specify this act if you want changes to your model to be saved in an
    # activity_logs table.
    #
    #   class Post < ActiveRecord::Base
    #     acts_as_activity_logged
    #   end
    module ActivityLogged #:nodoc:
      CALLBACKS = [:activity_log_create, :activity_log_update, :activity_log_destroy]

      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end

      module ClassMethods
        # == Configuration options
        #
        # * <tt>delay_after_create</tt> - No logging on a model until X time afterwards
        #   
        #   e.g. acts_as_activity_logged :delay_after_create => 15.seconds
        #   
        # * <tt>:models => :culprit</tt> - Activity Log calls this method to determine who did the activity.
        # * <tt>:models => :referenced</tt> - Activity Log calls this method to determine what the activity was done on.
        #   
        #   e.g. acts_as_activity_logged :models => { :culprit => { :method => :name }
        #
        # - culprit: The object that did the activity
        # - referenced: The object that the activity was done to
        #
        # * <tt>check_log_allowed</tt> - "True" to enable event filtering. When enabled, the plugin will assume that the model calling the plugin implements "log_allowed(action_name)" callback which returns a boolean value allowing / denying to record a particular event for that model.
        #
        def acts_as_activity_logged(options = {})
          # don't allow multiple calls
          return if self.included_modules.include?(NewBamboo::Acts::ActivityLogged::InstanceMethods)

          include NewBamboo::Acts::ActivityLogged::InstanceMethods
          
          
          
          class_eval do
            extend NewBamboo::Acts::ActivityLogged::SingletonMethods
            has_many :activity_logs, :as => :activity_loggable
            
            # Logging delay after a create
            cattr_accessor :delay_after_create            
            self.delay_after_create = options.delete(:delay_after_create)
            self.delay_after_create = 0.seconds if self.delay_after_create.nil?
            
            cattr_accessor :loggables
            self.loggables = {}
            self.loggables = options.delete(:loggables)
            
            cattr_accessor :userstamp
            self.userstamp = options.delete(:timestamp)
            
            cattr_accessor :check_log_allowed
            self.check_log_allowed = options.delete(:check_log_allowed)
            self.check_log_allowed = false if self.check_log_allowed.nil?
            
            after_create :activity_log_create
            after_update :activity_log_update
            after_destroy :activity_log_destroy
          end
        end
      end
    
      module InstanceMethods
        attr_accessor :skip_log
        
        private        
        # Creates a new record in the activity_logs table if applicable
        def activity_log_create
          write_activity_log(:create)
          raise Exception.new "Shouldn't be calling activity_log_create"
        end

        def activity_log_update
          write_activity_log(:update)
        end

        def activity_log_destroy
          write_activity_log(:destroy)
        end
        
        # This writes the activity log, but if the :delay_after_create option is set, it will only write
        # the log if the time given by :delay_after_create has passed since the object was created. If
        # the object does not have a created_at attribute this switch will be ignored
        def write_activity_log(action = :update)
          begin
            # explicitly switch on timestamping for event log
            previous_record_timestamps = ActivityLog.record_timestamps
            ActivityLog.record_timestamps = true
            
            # make sure that no logging is done within :delay_after_create time;
            # if no waiting required && if the filtering not required, write the log straight away
            if (self.respond_to?(:created_at) && !self.created_at.nil? && Time.now > self.delay_after_create.since(self.created_at)) || action == :create || self.created_at.nil?
              write_log = (self.check_log_allowed ? self.log_allowed(action.to_s) : true)
              if write_log
                set_culprit
                set_referenced
                log_entry = ActivityLog.new(:action => action.to_s, :referenced => @referenced, :activity_loggable => self, :culprit => @culprit)
                log_entry.save
              end
            end
            
            ActivityLog.record_timestamps = previous_record_timestamps
          rescue Exception => e
            # something went wrong - exception was thrown
            al = ActivityLog.new(:action => action.to_s, :activity_loggable => self)
            al.save
            
            logger.error "\nERROR: acts_as_activity_logged - write_activity_log()"
            logger.error "an incomplete log entry in ActivityLog table was still made - ID = #{al.id}"
            logger.error "action: #{action.to_s}; activity_loggable: #{self.to_s}"
            logger.error "exception caught:\n" + e.to_s + "\n"
          end
          return true
        end

        # If the userstamp option is given, call User.current_user(supplied by the userstamp plugin) 
        # otherwise use the models user method.
        # http://delynnberry.com/projects/userstamp/
        def set_culprit
          if !loggables.nil? && loggables.has_key?(:culprit) && loggables[:culprit].has_key?(:model)
            @culprit = (self.userstamp ? User.current_user : eval(loggables[:culprit][:model].to_s))
            puts "((((((((((((((((((((((((((((((((" + @culprit.class.name
          end
        end
        
        def set_referenced
          if !loggables.nil? && loggables.has_key?(:referenced) && loggables[:referenced].has_key?(:model)
            @referenced = eval(loggables[:referenced][:model].to_s)
          end
        end

        # Alias any existing callback methods
        CALLBACKS.each do |attr_name| 
          alias_method "orig_#{attr_name}".to_sym, attr_name
        end
        
        def empty_callback() end #:nodoc:

      end # InstanceMethods
      
      module SingletonMethods

      end
    end
  end
end