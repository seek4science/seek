class SetDefaultSubscriptions < ActiveRecord::Migration
  def self.up
    #FIXME: refactor to use sql, or at least not depend on app code
    Person.all.each {|p| User.with_current_user(p.user) {p.set_default_subscriptions; p.save!}}
  end

  def self.down
    #remove default subscriptions
  end
end
