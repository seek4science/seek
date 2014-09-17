class AddFundingDetailsToProgrammes < ActiveRecord::Migration
  def change
    add_column :programmes, :funding_details, :text
  end
end
