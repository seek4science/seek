class LinkModelToTypeAndFormat < ActiveRecord::Migration
  def self.up
    remove_column :models,:model_type
    remove_column :models,:model_format
    add_column :models,:model_type_id,:integer
    add_column :models,:model_format_id,:integer
  end

  def self.down
    add_column :models,:model_type,:string
    add_column :models,:model_format,:string
    remove_column :models,:model_type_id
    remove_column :models,:model_format_id
  end
end
