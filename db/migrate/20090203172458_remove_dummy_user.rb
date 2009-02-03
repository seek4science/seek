class RemoveDummyUser < ActiveRecord::Migration
  def self.up
    pers=Person.find(:all,:conditions=>{:is_dummy=>true}).each {|p| p.destroy}
    remove_column :people, :is_dummy
  end

  def self.down
    add_column :people, :is_dummy, :boolean, :default=>false
  end
end
