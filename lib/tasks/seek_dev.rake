require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'colorize'
require 'benchmark'

include SysMODB::SpreadsheetExtractor

namespace :seek_dev do


  task(:check_auth_lookup => :environment) do
    output = StringIO.new('')
    Seek::Util.authorized_types.each do |type|
      puts "Checking #{type.name.pluralize}"
      puts
      output.puts type.name
      users = User.all + [nil]
      type.find_each do |item|
        users.each do |user|
          user_id = user.nil? ? 0 : user.id
          ['view', 'edit', 'download', 'manage', 'delete'].each do |action|
            lookup = type.lookup_for_asset(action, user_id, item.id)
            actual = item.authorized_for_action(user, action)
            unless lookup == actual
              output.puts "  #{type.name} #{item.id} - User #{user_id}"
              output.puts "    Lookup said: #{lookup}"
              output.puts "    Expected: #{actual}"
            end
          end
        end
        print '.'
      end
      puts
    end

    output.rewind
    puts output.read
  end

  desc("Dump auth lookup tables")
  task(:dump_auth_lookup => :environment) do
    tables = Seek::Util.authorized_types.map(&:lookup_table_name)

    hashes = {}
    File.open('auth_lookup_dump.txt', 'w') do |f|
      f.write '{'
      tables.each_with_index do |table, i|
        puts "Dumping #{table} ..."
        array = ActiveRecord::Base.connection.execute("SELECT * FROM #{table}").each
        f.write "'#{table}' => "
        f.write array.inspect
        hashes[table] = array.hash
        f.write ',' unless i == (tables.length - 1)
      end
      f.write '}'
    end

    puts
    puts "Hashes:"
    puts JSON.pretty_generate(hashes).gsub(":", " =>")
    puts
    puts "Done"
  end

  desc 'A simple task for quickly setting up a project and institution, and assigned the first user to it. This is useful for quickly setting up the database when testing. Need to create a default user before running this task'
  task(:initial_membership => :environment) do
    p=Person.first
    raise Exception.new "Need to register a person first" if p.nil? || p.user.nil?

    User.with_current_user p.user do
      project=Project.new :title => "Project X"
      institution=Institution.new :title => "The Institute"
      project.save!
      institution.projects << project
      institution.save!
      p.update_attributes({"work_group_ids" => ["#{project.work_groups.first.id}"]})
    end
  end

  desc 'create 50 randomly named unlinked projects'
  task(:random_projects => :environment) do
    (0...50).to_a.each do
      title=("A".."Z").to_a[rand(26)]+UUID.generate
      p=Project.create :title => title
      p.save!
    end
  end

  desc "Lists all publicly available assets"
  task :list_public_assets => :environment do
    [Investigation, Study, Assay, DataFile, Model, Sop, Publication].each do |assets|
      assets.find_each do |asset|
        if asset.can_view?
          puts "#{asset.title} - #{asset.id}"
        end
      end
    end
  end


  task :add_people_from_spreadsheet, [:path] => :environment do |t, args|
    path = args.path
    file = open(path)
    csv = spreadsheet_to_csv(file)
    CSV.parse(csv) do |row|
      firstname=row[0].strip
      next if firstname=="first"
      lastname=row[1].strip
      email=row[2].strip
      project_id=row[3].strip
      institution_id=row[4].strip
      pp "Checking for #{firstname} #{lastname}"
      matches = Person.where(:first_name => firstname, :last_name => lastname)
      unless matches.empty?
        puts "A person already exists with firstname and lastname #{firstname},#{lastname} respectively, skipping".red
        next
      else
        puts "Preparing to add person #{firstname} #{lastname} with email #{email}"
        person = Person.new :first_name => firstname, :last_name => lastname, :email => email
      end
      project = Project.find_by_id(project_id)
      if project.nil?
        pp "No project found for id #{project_id}, skipping #{person.name}".red
        next
      end
      institution = Institution.find_by_id(institution_id)
      if institution.nil?
        pp "No institution found for id #{institution_id}, skipping #{person.name}".red
        next
      end
      person.add_to_project_and_institution(project, institution)
      begin
        person.save!
        puts "#{person.name} successfully added".green
      rescue Exception => e
        puts "Error adding #{person.name}".red
        puts e
      end
    end
  end

  task :strains_to_csv => :environment do

    CSV.open(Rails.root.join('strains.csv'), "w+", :force_quotes => true, :write_headers => true, :headers => ["id", "title", "organism_id", "organism_ncbi", "parent_id", "provider id", "provider name", "synonym", "comment", "genotypes", "phenotypes", "project_ids", "assay_ids"]) do |csv|
      Strain.all.each do |strain|
        row = [strain.id, strain.title, strain.organism_id, strain.organism.try(:ncbi_id), strain.parent_id, strain.provider_id, strain.provider_name, strain.synonym, strain.comment]
        row = row + [strain.genotype_info, strain.phenotype_info, strain.projects.collect(&:id).join(","), strain.assays.collect(&:id).join(",")]
        csv << row
      end
    end

  end

  task find_unused_images: :environment do
    root = File.join(Rails.root, 'app', 'assets', 'images')
    query = File.join(root, '**', '*')
    files = Dir.glob(query).collect { |p| p.gsub(root+"/", '') }
    files = files.select { |p| !(p.start_with?('famfamfam') || p.start_with?('crystal_project') || p.start_with?('file_icons')) }
    files = files.sort
    dictionary_image_files = Seek::ImageFileDictionary.instance.image_files
    CSV.open(Rails.root.join('image-usage.csv'), "w+", force_quotes: true, write_headers: true, headers: ['image', 'in dictionary', 'found with grep']) do |csv|
      bar = ProgressBar.new(files.count)
      files.each do |file|
        row = [file]
        if dictionary_image_files.include?(file)
          row << "1"
          row << "-"
        else
          row << "0"
          cmd = "grep -r '#{file}' app lib config vendor/assets/"
          result = `#{cmd}`
          if result.blank?
            row << "0"
          else
            row << "1"
          end
        end
        csv << row
        bar.increment!
      end
    end
  end
end

