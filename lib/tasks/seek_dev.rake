# frozen_string_literal: true

require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'benchmark'

include SysMODB::SpreadsheetExtractor

namespace :seek_dev do
  task(check_auth_lookup: :environment) do
    output = STDOUT
    Seek::Util.authorized_types.each do |type|
      puts "Checking #{type.name.pluralize}"
      puts
      output.puts type.name
      users = User.all + [nil]
      type.find_each do |item|
        users.each do |user|
          user_id = user.nil? ? 0 : user.id
          %w[view edit download manage delete].each do |action|
            lookup = item.lookup_for(action, user_id)
            actual = item.authorized_for_action(user, action)
            next if lookup == actual
            output.puts "  #{type.name} #{item.id} - User #{user_id}"
            output.puts "    Lookup said: #{lookup}"
            output.puts "    Expected: #{actual}"
          end
        end
        print '.'
      end
      puts
    end

    output.rewind
    puts output.read
  end

  task(:dump_controlled_vocab, [:id] => :environment) do |_t, args|
    vocab = SampleControlledVocab.find(args.id)
    json = { title: vocab.title, description: vocab.description, ols_root_term_uri: vocab.ols_root_term_uri,
             source_ontology: vocab.source_ontology, terms: [] }
    vocab.sample_controlled_vocab_terms.each do |term|
      json[:terms] << { label: term.label, iri: term.iri, parent_iri: term.parent_iri }
    end
    File.open("cv-dump-#{args.id}.json", 'w') do |f|
      f.write(JSON.pretty_generate(json))
    end
  end

  task(dump_auth_lookup: :environment) do
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
    puts 'Hashes:'
    puts JSON.pretty_generate(hashes).gsub(':', ' =>')
    puts
    puts 'Done'
  end

  task(benchmark_auth_lookup: :environment) do
    start_time = Time.now
    puts "Benchmarking!"
    puts "Auth lookup enabled: #{Seek::Config.auth_lookup_enabled}"
    u = User.first
    u2 = User.last
    Seek::Util.authorized_types.each do |type|
      puts "#{type.name} (#{type.count}):"
      b = Benchmark.measure do
        puts "\tAnon view: #{Benchmark.measure { 100.times { type.authorized_for('view') } } }"
        puts "\tAnon edit: #{Benchmark.measure { 100.times { type.authorized_for('edit') } } }"
        puts "\tUser edit: #{Benchmark.measure { 100.times { type.authorized_for('edit', u) } } }"
        puts "\tUser view: #{Benchmark.measure { 100.times { type.authorized_for('view', u2) } } }"
        puts "\tUser manage: #{Benchmark.measure { 100.times { type.authorized_for('manage', u2) } } }"
        puts "\tUser delete: #{Benchmark.measure { 100.times { type.authorized_for('delete', u) } } }"
      end
      puts "Total #{b}"
      puts
    end

    seconds = Time.now - start_time
    puts "Done - #{seconds}s elapsed"
  end

  task(initial_membership: :environment) do
    p = Person.first
    raise Exception, 'Need to register a person first' if p.nil? || p.user.nil?

    User.with_current_user p.user do
      project = Project.new title: 'Project X'
      institution = Institution.new title: 'The Institute'
      project.save!
      institution.projects << project
      institution.save!
      p.update_attributes('work_group_ids' => [project.work_groups.first.id.to_s])
    end
  end

  task(random_projects: :environment) do
    (0...50).to_a.each do
      title = ('A'..'Z').to_a[rand(26)] + UUID.generate
      p = Project.create title: title
      p.save!
    end
  end

  task list_public_assets: :environment do
    [Investigation, Study, Assay, DataFile, Model, Sop, Publication].each do |assets|
      assets.find_each do |asset|
        puts "#{asset.title} - #{asset.id}" if asset.can_view?
      end
    end
  end

  task :add_covid_map_people, [:path, :project_id, :admin_user_id] => :environment do |_t, args|
    path = args.path
    project_id = args.project_id
    admin_user = args.admin_user_id
    user = User.find(admin_user)
    project = Project.find(project_id)
    raise "Wrong project" unless project.title == "COVID-19 Disease Map" #sanity check

    puts "Using CSV at #{path}"
    errors = []
    added = 0
    associated = 0
    CSV.foreach(path) do |row|
      name = row[0]&.strip
      email = row[1]&.strip
      institution_id = row[2].strip
      expertise = row[3]
      first, last = name.split(' ',2)

      puts "Processing #{name}"

      User.with_current_user(user) do
        if (RFC822::EMAIL =~ email) && first
          person = Person.where(email:email).first
          unless person
            puts "creating profile for #{name}"
            person = Person.new(first_name: first,last_name: last,email: email)
            person.expertise = expertise if expertise
            if person.valid?
              person.save!
              added +=1
            else
              person = nil
              errors << ["person invalid", row]
            end
          end
          unless person.nil? || person.member_of?(project)
            institution = Institution.find_by_id(institution_id)
            if institution
              puts "adding #{name} to #{institution.title}"
              person.add_to_project_and_institution(project, institution)
              person.save!
              associated+=1
            else
              errors << ["institution not found",row]
            end
          else
            if person
              puts "#{name} already in project"
            end
          end
        else
          errors << ["bad email or no first name",row]
        end
      end
    end
    puts "Errors:" unless errors.empty?
    errors.each do |error|
      puts error[0]
      puts error[1].inspect
      puts "---------------"
    end
    puts "#{added} people added"
    puts "#{associated} linked to project"
  end

  task :add_people_from_spreadsheet, [:path] => :environment do |_t, args|
    path = args.path
    file = open(path)
    csv = spreadsheet_to_csv(file)
    CSV.parse(csv) do |row|
      firstname = row[0].strip
      next if firstname == 'first'
      lastname = row[1].strip
      email = row[2].strip
      project_id = row[3].strip
      institution_id = row[4].strip
      pp "Checking for #{firstname} #{lastname}"
      matches = Person.where(first_name: firstname, last_name: lastname)
      if matches.empty?
        puts "Preparing to add person #{firstname} #{lastname} with email #{email}"
        person = Person.new first_name: firstname, last_name: lastname, email: email
      else
        puts "A person already exists with firstname and lastname #{firstname},#{lastname} respectively, skipping"
        next
      end
      project = Project.find_by_id(project_id)
      if project.nil?
        pp "No project found for id #{project_id}, skipping #{person.name}"
        next
      end
      institution = Institution.find_by_id(institution_id)
      if institution.nil?
        pp "No institution found for id #{institution_id}, skipping #{person.name}"
        next
      end
      person.add_to_project_and_institution(project, institution)
      begin
        person.save!
        puts "#{person.name} successfully added"
      rescue Exception => e
        puts "Error adding #{person.name}"
        puts e
      end
    end
  end

  task strains_to_csv: :environment do
    CSV.open(Rails.root.join('strains.csv'), 'w+', force_quotes: true, write_headers: true, headers: ['id', 'title', 'organism_id', 'organism_ncbi', 'parent_id', 'provider id', 'provider name', 'synonym', 'comment', 'genotypes', 'phenotypes', 'project_ids', 'assay_ids']) do |csv|
      Strain.all.each do |strain|
        row = [strain.id, strain.title, strain.organism_id, strain.organism.try(:ncbi_id), strain.parent_id, strain.provider_id, strain.provider_name, strain.synonym, strain.comment]
        row += [strain.genotype_info, strain.phenotype_info, strain.projects.collect(&:id).join(','), strain.assays.collect(&:id).join(',')]
        csv << row
      end
    end
  end

  task find_unused_images: :environment do
    root = File.join(Rails.root, 'app', 'assets', 'images')
    query = File.join(root, '**', '*')
    files = Dir.glob(query).collect { |p| p.gsub(root + '/', '') }
    files = files.reject { |p| p.start_with?('famfamfam', 'crystal_project', 'file_icons') }
    files = files.sort
    dictionary_image_files = Seek::ImageFileDictionary.instance.image_files
    CSV.open(Rails.root.join('image-usage.csv'), 'w+', force_quotes: true, write_headers: true, headers: ['image', 'in dictionary', 'found with grep']) do |csv|
      bar = ProgressBar.new(files.count)
      files.each do |file|
        row = [file]
        if dictionary_image_files.include?(file)
          row << '1'
          row << '-'
        else
          row << '0'
          cmd = "grep -r '#{file}' app lib config vendor/assets/"
          result = `#{cmd}`
          row << if result.blank?
                   '0'
                 else
                   '1'
                 end
        end
        csv << row
        bar.increment!
      end
    end
  end

  task find_duplicate_users_by_name_match: :environment do
    File.delete("./log/duplicate_users.log") if File.exist?("./log/duplicate_users.log")
    output = File.open( "./log/duplicate_users.log","w" )
    duplicated_users = Person.select(:first_name,:last_name).group(:first_name,:last_name).having("count(*)>1")
    #pp duplicated_users
    duplicated_users.each do |duplicated_user|
      matches = Person.where(first_name: duplicated_user.first_name, last_name: duplicated_user.last_name)
      puts duplicated_user.first_name+" "+duplicated_user.last_name+"("+matches.size.to_s+")"
      output << duplicated_user.first_name+" "+duplicated_user.last_name+"("+matches.size.to_s+")"+"\n"
      matches.each do |match|
        puts "ID "+ match.id.to_s+":"+ match.email
        output << "ID "+ match.id.to_s+":"+ match.email+"\n"
      end
      output << "\n"
    end
    output.close
  end

  task find_publications_without_publication_types: :environment do
     base_url = "https://fairdomhub.org/"
     #base_url = "https://0.0.0.0:3002/"
    File.delete("./log/publications_without_publication_types.log") if File.exist?("./log/publications_without_publication_types.log")
    output = File.open( "./log/publications_without_publication_types.log","w" )
     pj_has_pubs = Project.all.select { |p| p.publications.size > 0 }
     pj_has_pubs_without_type = pj_has_pubs.select{|p| p.publications.map(&:publication_type_id).any?{ |e| e.nil? } }
      pp pj_has_pubs.map(&:id)
      pp pj_has_pubs_without_type.map(&:id)
      pj_has_pubs_without_type.each do |project|
        pp "====================="
        pp project.title + '('+base_url+"projects/"+project.id.to_s+ ')'
        output << "====================="+"\n"
        output << "Project:"+ project.title+"\n"
        output << base_url+"projects/"+project.id.to_s+"\n"
        output << "====================="+"\n"
        project.publications.each do |publication|
          if  publication.publication_type_id.blank?
            pp base_url+"publications/"+publication.id.to_s
            output << base_url+"publications/"+publication.id.to_s+"\n"
          end
        end
        output << "\n"
      end
    output.close
  end

  task make_ontology_study_cmt: :environment do
    cmt = CustomMetadataType.new(title: 'Study Ontology CMT', supported_type:'Study')
    cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'name', required:true, sample_attribute_type: SampleAttributeType.where(title:'String').first)
    cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'ontology',
                                                                  required:true,
                                                                  sample_attribute_type:SampleAttributeType.where(title:'Controlled Vocabulary').first,
                                                                  sample_controlled_vocab: SampleControlledVocab.find(4))
    cmt.save!
  end

  task report_missing_related_items_routes: :environment do
    Seek::RelatedItems::RELATABLE_TYPES.each do |type|
      klass = type.constantize
      methods = klass.related_type_methods
      methods.each_key do |assoc|
        x = Rails.application.routes.url_helpers.send("#{type.underscore}_#{assoc.pluralize.underscore}_path", 1) rescue nil
        puts "Missing! #{type.underscore}_#{assoc.pluralize.underscore}_path" if x.nil?
      end
    end
  end

  task rebuild_csl_style_list: :environment do
    File.write(Seek::Citations.style_dictionary_path, Seek::Citations.generate_style_pairs.to_yaml)
  end
end
