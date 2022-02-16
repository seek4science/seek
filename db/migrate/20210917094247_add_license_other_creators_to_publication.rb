class AddLicenseOtherCreatorsToPublication < ActiveRecord::Migration[5.2]
  def change
    add_column :publications, :license, :string
    add_column :publications, :other_creators, :text
  end
end
