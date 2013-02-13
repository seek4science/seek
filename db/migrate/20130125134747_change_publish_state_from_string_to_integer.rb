class ChangePublishStateFromStringToInteger < ActiveRecord::Migration
  def self.up
    change_column :resource_publish_logs, :publish_state, :integer
  end

  def self.down
    change_column :resource_publish_logs, :publish_state, :string
  end
end
