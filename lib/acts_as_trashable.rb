# Copyright (c) 2010 Brian Durand
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
#                                  distribute, sublicense, and/or sell copies of the Software, and to
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
#
# https://github.com/bdurand/acts_as_trashable

require 'active_record'
require 'active_support/all'

module ActsAsTrashable
  
  autoload :TrashRecord, File.expand_path('../acts_as_trashable/trash_record', __FILE__)
  
  def self.included (base)
    base.extend(ActsMethods)
  end
  
  module ActsMethods
    # Class method that injects the trash behavior into the class.
    def acts_as_trashable
      extend ClassMethods
      include InstanceMethods
      alias_method_chain :destroy, :trash
    end
  end
  
  module ClassMethods
    # Empty the trash for this class of all entries older than the specified maximum age in seconds.
    def empty_trash (max_age)
      TrashRecord.empty_trash(max_age, :only => self)
    end
    
    # Restore a particular entry by id from the trash into an object in memory. The record will not be saved.
    def restore_trash (id)
      trash = TrashRecord.find_trash(self, id)
      return trash.restore if trash
    end
    
    # Restore a particular entry by id from the trash, save it, and delete the trash entry.
    def restore_trash! (id)
      trash = TrashRecord.find_trash(self, id)
      return trash.restore! if trash
    end
  end
  
  module InstanceMethods
    def destroy_with_trash
      return destroy_without_trash if @acts_as_trashable_disabled
      TrashRecord.transaction do
        trash = TrashRecord.new(self)
        trash.save!
        return destroy_without_trash
      end
    end
    
    # Call this method to temporarily disable the trash feature within a block.
    def disable_trash
      save_val = @acts_as_trashable_disabled
      begin
        @acts_as_trashable_disabled = true
        yield if block_given?
      ensure
        @acts_as_trashable_disabled = save_val
      end
    end
  end
  
end

ActiveRecord::Base.send(:include, ActsAsTrashable)
