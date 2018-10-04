# frozen_string_literal: true

class ChangeUserContributorsToPerson < ActiveRecord::Migration
  def up
    types.each do |type|
      sql = "SELECT #{type.table_name}.id, users.person_id FROM #{type.table_name} LEFT JOIN users ON users.id = contributor_id WHERE #{type.table_name}.contributor_type = 'User';"
      ActiveRecord::Base.connection.select_all(sql).each do |record|
        id = record['id']
        person_id = record['person_id']
        if person_id.blank?
          # where the contributor cannot be determined, the deleted_contributor field is updated
          sql = "UPDATE #{type.table_name} SET deleted_contributor = 'User:#{id}', contributor_id = NULL, contributor_type= NULL WHERE id = #{id}"
        else
          sql = "UPDATE #{type.table_name} SET contributor_id = #{person_id}, contributor_type = 'Person' WHERE id = #{id}"
        end
        ActiveRecord::Base.connection.execute(sql)
      end
    end
  end

  def down
    # not reversible
  end

  def types
    [DataFile, Document, Event, Investigation, Model, Presentation, Publication, Sample, Sop, Strain, Study] +
      [DataFile::Version, Document::Version, Model::Version, Presentation::Version, Sop::Version]
  end
end
