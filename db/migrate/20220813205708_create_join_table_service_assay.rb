class CreateJoinTableServiceAssay < ActiveRecord::Migration[6.1]
  def change
    create_join_table :services, :assays do |t|
      # t.index [:service_id, :assay_id]
      # t.index [:assay_id, :service_id]
    end
  end
end
