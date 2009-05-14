# To change this template, choose Tools | Templates
# and open the template in the editor.
require 'active_record/fixtures'

class DefaultDataMigration < ActiveRecord::Migration

  def self.up
    down
    table_name=model_class_name.pluralize.underscore
    puts "tablename=#{table_name}, directory='#{self.default_data_directory}"
    Fixtures.create_fixtures(self.default_data_directory, table_name)
  end

  def self.down
    eval("#{model_class_name}.delete_all")
  end

  def self.default_data_directory
    File.join(RAILS_ROOT, "config/default_data" )
  end

  
end
