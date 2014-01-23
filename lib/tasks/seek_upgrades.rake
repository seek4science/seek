#encoding: utf-8
require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'


namespace :seek do

  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :update_admin_assigned_roles,
            :update_top_level_assay_type_titles,
            :repopulate_auth_lookup_tables,
            :repopulate_missing_publication_book_titles
  ]

  desc "Disassociates contributors and refreshes the list of publication authors from the doi/pubmed for all publications"
  task :reset_publication_authors=>[:environment] do
    disable_authorization_checks do
      Publication.all.each do |publication|
        publication.creators.clear #get rid of author links
        publication.publication_authors.clear

        #Query pubmed article to fetch authors
        result = nil
        pubmed_id = publication.pubmed_id
        doi = publication.doi
        if pubmed_id
          query = PubmedQuery.new("seek",Seek::Config.pubmed_api_email)
          result = query.fetch(pubmed_id)
        elsif doi
          query = DoiQuery.new(Seek::Config.crossref_api_email)
          result = query.fetch(doi)
        end
        unless result.nil?
          result.authors.each_with_index do |author, index|
            pa = PublicationAuthor.new()
            pa.publication = publication
            pa.first_name = author.first_name
            pa.last_name = author.last_name
            pa.author_index = index
            pa.save
          end
        end
      end
    end
  end

  desc "read publication authors from spreadsheet"
  task :read_publication_authors => [:environment] do
    FasterCSV.foreach("publication_authors.csv") do |row|
      next if row[0] == 'publication name'
      publication = Publication.find(row[1].match(/\d*$/).to_s.to_i)
      pa = publication.publication_authors.detect {|pa| pa.first_name == row[2] and pa.last_name == row[3]}
      if pa.nil?
        raise "Could not find #{row[2]} #{row[3]} for #{publication.title} id: #{publication.id}"
      end
      unless row[7] == "NO LINK"
        if !row[9].blank?
          person = Person.find(row[9].match(/\d*$/).to_s.to_i)
          raise "#{row[9]} did not resolve to a valid person" unless person
        elsif !row[6].blank?
          person = Person.find(row[6].match(/\d*$/).to_s.to_i) if !row[6].blank?
          raise "#{row[9]} did not resolve to a valid person" unless person
        end

        if person
          pa.person = person
          disable_authorization_checks {pa.save!}
        end
      end
    end
  end

  desc "guess publication authors and dump to a csv"
  task :guess_publication_authors_to_csv => [:environment] do
    FasterCSV.open("publication_authors.csv", "w") do |csv|
      Publication.all.each do |publication|
        publication.publication_authors.each do |author|
	  projects = publication.projects.empty? ? (publication.contributor.try(:person).try(:projects) || []) : publication.projects
          matches = []
          #Get author by last name
          last_name_matches = Person.find_all_by_last_name(author.last_name)
          matches = last_name_matches
          #If no results, try searching by normalised name, taken from grouped_pagination.rb
          if matches.size < 1
            text = author.last_name
            #handle the characters that can't be handled through normalization
            %w[ØO].each do |s|
              text.gsub!(/[#{s[0..-2]}]/, s[-1..-1])
            end

            codepoints = text.mb_chars.normalize(:d).split(//u)
            ascii=codepoints.map(&:to_s).reject { |e| e.length > 1 }.join

            last_name_matches = Person.find_all_by_last_name(ascii)
            matches = last_name_matches
          end

          #If more than one result, filter by project
          if matches.size > 1
            project_matches = matches.select { |p| p.member_of?(projects) }
            if project_matches.size >= 1 #use this result unless it resulted in no matches
              matches = project_matches
            end
          end

          #If more than one result, filter by first initial
          if matches.size > 1
            first_and_last_name_matches = matches.select { |p| p.first_name.at(0).upcase == author.first_name.at(0).upcase }
            if first_and_last_name_matches.size >= 1 #use this result unless it resulted in no matches
              matches = first_and_last_name_matches
            end
          end

          #Take the first match as the guess
          if match = matches.first
            csv << [publication.title, "seek.virtual-liver.de/publications/#{publication.id}", author.first_name, author.last_name, match.first_name, match.last_name, "seek.virtual-liver.de/people/#{match.id}"]
          else
            csv << [publication.title, "seek.virtual-liver.de/publications/#{publication.id}", author.first_name, author.last_name, nil, nil, nil]
          end
        end
      end
    end
  end

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade=>[:environment,"db:migrate","db:sessions:clear","tmp:clear","tmp:assets:clear"]) do
    
    solr=Seek::Config.solr_enabled

    Seek::Config.solr_enabled=false

    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr

    if (solr)
      Rake::Task["seek:reindex_all"].invoke
    end

    puts "Upgrade completed successfully"
  end

  task(:update_admin_assigned_roles=>:environment) do
    Person.where("roles_mask > 0").each do |p|
      if p.admin_defined_role_projects.empty?
        roles = []
        (p.role_names & Person::PROJECT_DEPENDENT_ROLES).each do |role|
          puts "Updating #{p.name} for - '#{role}' - adding to #{p.projects.count} projects"
          roles << [role,p.projects]
        end
        roles << ["admin"] if p.is_admin?
        unless roles.empty?
          Person.record_timestamps = false
          begin
            p.roles = roles
            disable_authorization_checks do
              p.save!
            end
          rescue Exception=>e
            puts "Error saving #{p.name} - #{p.id}: #{e.message}"
          ensure
            Person.record_timestamps = true
          end
        end
      end
    end
  end

  task(:clean_up_sop_specimens=>:environment) do
    broken = SopSpecimen.all.select{|ss| ss.sop.nil? || ss.specimen.nil?}
    disable_authorization_checks do
      broken.each{|b| b.destroy}
    end
  end

  task(:update_top_level_assay_type_titles=>:environment) do
    exp_id = AssayType.experimental_assay_type_id
    assay_type = AssayType.find(exp_id)
    assay_type.title="generic experimental assay"
    assay_type.save!

    mod_id = AssayType.modelling_assay_type_id
    assay_type = AssayType.find(mod_id)
    assay_type.title="generic modelling analysis"
    assay_type.save!
  end

  task(:repopulate_citation_for_publication=>:environment) do
    disable_authorization_checks do
      Publication.all.each do |publication|
        #Query pubmed article to fetch authors
        result = nil
        pubmed_id = publication.pubmed_id
        doi = publication.doi
        if pubmed_id
          query = PubmedQuery.new("seek",Seek::Config.pubmed_api_email)
          result = query.fetch(pubmed_id)
        elsif doi
          query = DoiQuery.new(Seek::Config.crossref_api_email)
          result = query.fetch(doi)
        end
        unless result.nil?
          publication.citation = result.citation
          publication.save
        end
      end
    end
  end
desc "pre-populate investigations with projects in VLN SEEK "
  task(:pre_populate_investigations => :environment) do
    #projects leaves will be associated with new created default investigation

    #Project A-G
    inv_projects_parents = Project.find(:all, :conditions => ["name REGEXP?", "^[A-Z][:]"])
    inv_projects = inv_projects_parents.map { |parent| parent.descendants }.flatten.select { |proj| proj.children.empty? }
    #show cases, "Showcase LIAM (Liver Image Analysis Based Model)" is excluded as there is no people involved in this project
    ["Showcase HGF and Regeneration", "Showcase LPS and Inflammation", "Showcase Steatosis"].each do |proj_name|
      inv_projects = inv_projects | [Project.find_by_name(proj_name)]
    end
    inv_projects.each do |proj|
      new_inv = Investigation.new :title => proj.name, :description => "Default investigation for project #{proj.name}"
      new_inv.projects = [proj]
      unless proj.project_coordinators.empty?
        new_inv.contributor = proj.project_coordinators.first.user
      end
      policy = Policy.new(:name => "default project and other projects policy for pre-populated investigation",
                          :sharing_scope => Policy::ALL_SYSMO_USERS,
                          :access_type => Policy::ACCESSIBLE )

      policy.permissions << Permission.new(:contributor => proj, :access_type => Policy::EDITING)

      new_inv.policy = policy
      new_inv.save!
      puts "Investigation '#{new_inv.title}' was created successfully!"
    end
  end

  desc "repopulate missing book titles for publications"
  task(:repopulate_missing_publication_book_titles => :environment) do
    disable_authorization_checks do
      Publication.all.select { |p| p.publication_type ==3 && p.journal.blank? }.each do |pub|
        if pub.doi
          query = DoiQuery.new(Seek::Config.crossref_api_email)
          result = query.fetch(pub.doi)
          unless result.nil? || !result.error.nil?
            pub.extract_doi_metadata(result)
            pub.save
          end
        end
      end
    end
  end

  desc "adds the term uri's to assay types"
    task :add_term_uris_to_assay_types=>:environment do
      #fix spelling error in earlier seed data
      type = AssayType.find_by_title("flux balanace analysis")
      unless type.nil?
        type.title = "flux balance analysis"
        type.save
      end

      yamlfile=File.join(Rails.root,"config","default_data","assay_types.yml")
      yaml=YAML.load_file(yamlfile)
      yaml.keys.each do |k|
        title = yaml[k]["title"]
        uri = yaml[k]["term_uri"]
        unless uri.nil?
          assay_type = AssayType.where(["lower(title)=?",title.downcase]).first

          unless assay_type.nil?
                assay_type.term_uri = uri
                assay_type.save
          end
        else
          puts "No uri defined for assaytype #{title} so skipping adding term"
        end

      end
    end

    desc "adds the term uri's to technology types"
    task :add_term_uris_to_technology_types=>:environment do
      yamlfile=File.join(Rails.root,"config","default_data","technology_types.yml")
      yaml=YAML.load_file(yamlfile)
      yaml.keys.each do |k|
        title = yaml[k]["title"]
        uri = yaml[k]["term_uri"]
        unless uri.nil?
          tech_type = TechnologyType.where(["lower(title)=?",title.downcase]).first
          unless tech_type.nil?
                tech_type.term_uri = uri
                tech_type.save
          end
        else
          puts "No uri defined for Technology Type #{title} so skipping adding term"
        end

      end
    end

    desc "content type of jpg is image/jpeg, instead of image/jpg"
    task(:correct_content_type_for_jpg=>:environment) do
      content_blobs = ContentBlob.find(:all, :conditions => ['content_type=?', 'image/jpg'])
      content_blobs.each do |cb|
        puts cb.original_filename
        cb.content_type = 'image/jpeg'
        cb.save
      end
    end

    desc "update jws online root to point to http://jjj.mib.ac.uk/"
    task(:update_jws_online_root => :environment) do
      Seek::Config.jws_online_root = 'http://jjj.mib.ac.uk/'
    end

end