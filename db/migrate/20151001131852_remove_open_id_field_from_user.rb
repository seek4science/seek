class RemoveOpenIdFieldFromUser < ActiveRecord::Migration
  def up
    remove_column :users,:openid
  end

  def down
    add_column :users,:openid,:string
  end
end
