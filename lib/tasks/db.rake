require 'rubygems'
require 'rake'
require 'terrapin'

# This extends teh regular task, to tweak the schema.rb file and remove mysql specific elements. Since Rails 5 schema.rb is no
# longer db agnostic - see https://github.com/rails/rails/issues/26209
Rake::Task['db:schema:dump'].enhance do
  begin
    cmd = Terrapin::CommandLine.new("sed 's/\options.*,//' db/schema.rb > db/schema2.rb " \
      '&& mv db/schema2.rb db/schema.rb')
    cmd.run
  rescue StandardError => e
    puts "Failed to convert schema.rb to db agnostic - #{e.message}"
  end
end
