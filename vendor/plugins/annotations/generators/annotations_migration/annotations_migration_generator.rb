class AnnotationsMigrationGenerator < Rails::Generator::Base

  attr_accessor :version

  def initialize(*runtime_args)
    super(*runtime_args)
    if @args[0].nil?
      @version = "all"
    else
      @version = @args[0].downcase
    end
  end

  def manifest
    record do |m|
      if @version
        if @version == "all"
          Dir.chdir(File.join(File.dirname(__FILE__), "templates")) do
            Dir.glob("*.rb").each do |f|
              version = f.gsub(/.rb/, '').split('_')[1]
              m.migration_template "migration_#{version}.rb", 'db/migrate', { :migration_file_name => "annotations_migration_#{version}" }
              m.sleep 1   # So that the timestamps on the migration are not the same!
            end
          end
        else
          m.migration_template "migration_#{@version}.rb", 'db/migrate', { :migration_file_name => "annotations_migration_#{@version}" }
        end
      end
    end
  end

end
