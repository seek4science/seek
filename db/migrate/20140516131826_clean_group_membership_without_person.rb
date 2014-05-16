class CleanGroupMembershipWithoutPerson < ActiveRecord::Migration
  def up
    sql = "DELETE FROM group_memberships WHERE person_id IS NULL;"
    ActiveRecord::Base.connection.execute(sql)
  end

  def down
  end
end
