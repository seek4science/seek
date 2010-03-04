class BioportalMigrationGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.migration_template 'migration.rb', 'db/migrate', :migration_file_name => "bioportal_concept_migration"
    end
  end
end
