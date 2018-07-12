class ChangeUserContributorsToPerson < ActiveRecord::Migration
  def up
    types = Seek::Util.authorized_types.select{|t| t.attribute_names.include?('contributor_type')}
    types.each do |type|
      # the update could potentially be done in one update & join, but would be different for each database type
      sql = "SELECT #{type.table_name}.id, users.person_id FROM #{type.table_name} LEFT JOIN users ON users.id = contributor_id WHERE #{type.table_name}.contributor_type = 'User';"
      ActiveRecord::Base.connection.select_all(sql).each do |record|
        id = record['id']
        person_id = record['person_id']
        sql = "UPDATE #{type.table_name} SET contributor_id = #{person_id}, contributor_type='Person' WHERE id = #{id}"
        ActiveRecord::Base.connection.execute(sql)
      end
    end
  end

  def down
    # not reversible
  end
end
