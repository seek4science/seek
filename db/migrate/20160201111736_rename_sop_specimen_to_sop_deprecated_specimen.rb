class RenameSopSpecimenToSopDeprecatedSpecimen < ActiveRecord::Migration
  def change
    rename_table :sop_specimens, :sop_deprecated_specimens
  end

end
