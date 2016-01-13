class AddRejectionReasonToProgramme < ActiveRecord::Migration
  def change
    add_column :programmes, :activation_rejection_reason, :text, default:nil
  end
end
