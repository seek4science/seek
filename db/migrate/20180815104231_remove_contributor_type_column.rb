# frozen_string_literal: true

class RemoveContributorTypeColumn < ActiveRecord::Migration
  def up
    types.each do |type|
      remove_column type.table_name.to_sym, :contributor_type
    end
  end

  def down
    types.each do |type|
      add_column type.table_name.to_sym, :contributor_type, :string
      ActiveRecord::Base.connection.execute("UPDATE #{type.table_name} SET contributor_type = 'Person'")
    end
  end

  private

  def types
    [DataFile, Document, Event, Investigation, Model, Presentation, Publication, Sample, Sop, Strain, Study] +
      [DataFile::Version, Document::Version, Model::Version, Presentation::Version, Sop::Version]
  end
end
