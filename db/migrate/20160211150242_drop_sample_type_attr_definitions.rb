class DropSampleTypeAttrDefinitions < ActiveRecord::Migration
  def up
    remove_column :sample_types, :attr_definitions
  end

  def down
    add_column :sample_types, :attr_definitions, :text
  end
end
