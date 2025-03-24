class ChangeWhiteAndBlackList < ActiveRecord::Migration[6.1]
  def change
    rename_column :policies, :use_blacklist, :use_denylist
    rename_column :policies, :use_whitelist, :use_allowlist
  end
end
