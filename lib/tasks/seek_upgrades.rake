#encoding: utf-8
require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'


namespace :seek do

  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :repopulate_auth_lookup_tables,
            :move_asset_files,
            :remove_converted_pdf_and_txt_files_from_asset_store,
            :clear_send_email_jobs,
            :reencode_settings_table_using_psych,
            :reencode_delayedjobs_table_using_psych
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

  task(:move_asset_files=>:environment) do
    oldpath=File.join(Rails.root,"filestore","content_blobs",Rails.env.downcase)
    newpath = Seek::Config.asset_filestore_path
    puts "Moving asset files from:\n\t#{oldpath}\nto:\n\t#{newpath}"
    FileUtils.mkdir_p newpath
    if File.exists? oldpath
      FileUtils.mv Dir.glob("#{oldpath}/*"),newpath
      puts "You can now safely remove #{oldpath}"
    else
      puts "The old asset location #{oldpath} doesn't exist, nothing to do"
    end
  end

  task(:remove_converted_pdf_and_txt_files_from_asset_store=>:environment) do
    FileUtils.rm Dir.glob(File.join(Seek::Config.asset_filestore_path,"*.pdf"))
    FileUtils.rm Dir.glob(File.join(Seek::Config.asset_filestore_path,"*.txt"))
  end

  task(:clear_send_email_jobs=>:environment) do
    Delayed::Job.where(["handler like ?","%SendPeriodicEmailsJob%"]).destroy_all
  end

  desc("Ruby 1.9.3 uses psych engine while some older versions use syck. Some encoded value using syck can not be decoded by psych")
  task(:reencode_settings_table_using_psych=>:environment) do
    puts "reencode settings table using psych"
    temp = YAML::ENGINE.yamler
    YAML::ENGINE.yamler = 'syck'
    settings = Settings.all
    YAML::ENGINE.yamler = temp
    settings.each do |var, value|
      Settings.send "#{var}=", value
    end
  end

  desc("Ruby 1.9.3 uses psych engine while some older versions use syck.")
  task(:reencode_delayedjobs_table_using_psych=>:environment) do
    puts "reencode delayedjobs table using psych"
    jobs = Delayed::Job.all
    jobs.each do |job|
      handler = job.handler
      job.handler = YAML::load(handler).to_yaml
      job.save
    end
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
end