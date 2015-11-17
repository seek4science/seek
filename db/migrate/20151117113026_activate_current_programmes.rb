class ActivateCurrentProgrammes < ActiveRecord::Migration
  def up
    Programme.update_all(is_activated:true)
  end

  def down
    Programme.update_all(is_activated:false)
  end
end
