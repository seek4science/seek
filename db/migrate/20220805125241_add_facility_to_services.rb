class AddFacilityToServices < ActiveRecord::Migration[6.1]
  def change
    add_reference :services, :facility, foreign_key: true
  end
end
