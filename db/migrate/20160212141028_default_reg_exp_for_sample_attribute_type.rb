class DefaultRegExpForSampleAttributeType < ActiveRecord::Migration
  def up
    change_column_default :sample_attribute_types,:regexp,'.*'
  end

  def down
    change_column_default :sample_attribute_types,:regexp,nil
  end
end
