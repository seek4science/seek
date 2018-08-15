class AddDeletetedContributorField < ActiveRecord::Migration
  def up
    table_names.each do |table_name|
      add_column table_name, :deleted_contributor, :string, default: nil
    end
  end

  def down
    table_names.each do |table_name|
      remove_column table_name, :deleted_contributor
    end
  end

  private

  def table_names
    types.collect{|t| t.table_name.to_sym}
  end

  def types
    [Assay, DataFile, Document, Event, Investigation, Model, Presentation, Publication, Sample, Sop, Strain, Study] +
        [DataFile::Version, Document::Version, Model::Version, Presentation::Version, Sop::Version]
  end
end
