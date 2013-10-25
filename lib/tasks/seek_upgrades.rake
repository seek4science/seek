require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'
require 'fastercsv'


namespace :seek do

  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :reordering_authors_for_existing_publications,
            :cleanup_asset_versions_projects_duplication,
            :update_missing_content_types,
            :repopulate_auth_lookup_tables,
            :detect_web_page_content_blobs
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
  task(:upgrade=>[:environment,"db:migrate","tmp:clear","tmp:assets:clear"]) do
    
    solr=Seek::Config.solr_enabled

    Seek::Config.solr_enabled=false

    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr

    if (solr)
      Rake::Task["seek:reindex_all"].invoke
    end

    puts "Upgrade completed successfully"
  end


  task(:detect_web_page_content_blobs=>:environment) do

    blobs = ContentBlob.find(:all,:conditions=>"url IS NOT NULL")

    #skip JERM added assets (to avoid a problem with translucent pointing at a defunt repository that returns a html page)
    blobs = blobs.select{|blob| !blob.asset.nil? && !blob.asset.contributor.nil?}

    blobs.each do |blob|

      #to open up access to private method
      class << blob
        def detect_webpage
          check_url_content_type
        end
      end

      blob.detect_webpage
      puts "Checked #{blob.url} - is a webpage:#{blob.is_webpage?}"
      blob.save
    end
  end

  desc "removes the older duplicate create activity logs that were added for a short period due to a bug (this only affects versions between stable releases)"
  task(:remove_duplicate_activity_creates=>:environment) do
    ActivityLog.remove_duplicate_creates
  end

  task(:update_missing_content_types => :environment) do
    unknown = ContentBlob.all.select do |cb|
      !cb.asset.nil? && cb.human_content_type == "Unknown file type"
    end

    unknown.each do |cb|
      filename = cb.original_filename
      file_format = filename.split('.').last.try(:strip)
      possible_mime_types = cb.mime_types_for_extension file_format
      type = possible_mime_types.sort.first || "application/octet-stream"
      type = type.gsub("image/jpg","image/jpeg") unless type.nil?
      if type != "Unknown file type"
        cb.content_type = type
        cb.save
      end
    end

  end

  task(:update_first_letter_for_strain => :environment) do
    Strain.all.each do |strain|
      disable_authorization_checks{strain.save(false)}
    end
  end

  task(:reordering_authors_for_existing_publications=>:environment) do
    Publication.all.each do |publication|
      puts ("Processing publication #{publication.id}")

      non_seek_authors = publication.non_seek_authors
      seek_authors = publication.seek_authors
      projects = publication.projects
      projects = publication.contributor.person.projects if projects.empty?

      result = PublicationsController.new().fetch_pubmed_or_doi_result publication.pubmed_id, publication.doi

      original_authors = result.try(:authors).nil? ? [] : result.authors
      authors_with_right_orders = []
      original_authors.each do |author|
        seek_author_matches = []
        non_seek_author_matches = []

        #Get author by last name
        seek_author_matches = seek_authors.select{|seek_author| seek_author.last_name == author.last_name}
        non_seek_author_matches = non_seek_authors.select{|non_seek_author| non_seek_author.last_name == author.last_name}

        #If no results, try searching by normalised name, taken from grouped_pagination.rb
        if (seek_author_matches.size + non_seek_author_matches.size) < 1
          text = author.last_name
          #handle the characters that can't be handled through normalization
          %w[ØO].each do |s|
            text.gsub!(/[#{s[0..-2]}]/, s[-1..-1])
          end

          codepoints = text.mb_chars.normalize(:d).split(//u)
          ascii=codepoints.map(&:to_s).reject{|e| e.length > 1}.join

          seek_author_matches = seek_authors.select{|seek_author| seek_author.last_name == ascii}
          non_seek_author_matches = non_seek_authors.select{|non_seek_author| non_seek_author.last_name == ascii}
        end

        #If more than one result for seek_author_matches, filter by project
        if seek_author_matches.size > 1
          seek_author_project_matches = seek_author_matches.select{|p| p.member_of?(projects)}
          if seek_author_project_matches.size >= 1 #use this result unless it resulted in no matches
            seek_author_matches = seek_author_project_matches
          end
        end

        #If more than one result, filter by first initial
        if (seek_author_matches.size + non_seek_author_matches.size) > 1
          seek_author_first_and_last_name_matches = seek_author_matches.select{|p| p.first_name.at(0).upcase == author.first_name.at(0).upcase}
          non_seek_author_first_and_last_name_matches = non_seek_author_matches.select{|p| p.first_name.at(0).upcase == author.first_name.at(0).upcase}
          if (seek_author_first_and_last_name_matches.size + non_seek_author_first_and_last_name_matches.size) >= 1  #use this result unless it resulted in no matches
            seek_author_matches = seek_author_first_and_last_name_matches
            non_seek_author_matches = non_seek_author_first_and_last_name_matches
          end
        end
        match = non_seek_author_matches.first
        match = seek_author_matches.first if match.nil?
        authors_with_right_orders << match unless match.nil?
      end

      if original_authors.size == authors_with_right_orders.size
        authors_with_right_orders.each_with_index do |author, index|
          publication.publication_author_orders.create(:author => author, :order => index)
        end
      else
        publication.creators.clear #get rid of author links
        publication.non_seek_authors.clear
        publication.publication_author_orders.clear
        PublicationsController.new().create_non_seek_authors(original_authors,publication)
      end
    end
  end

  task(:cleanup_asset_versions_projects_duplication=>:environment) do
     ['data_file','model','presentation','sop'].each do |asset_type|
       asset_versions_projects_table = [asset_type + '_versions', 'projects'].sort().join('_')
       sql1 = "SELECT * FROM #{asset_versions_projects_table} GROUP BY project_id,version_id"
       sql2 = "SELECT count(version_id) FROM #{asset_versions_projects_table} GROUP BY project_id,version_id"
       grouped_by_version_and_project = ActiveRecord::Base.connection.select_all(sql1)
       counted_by_version_and_project = ActiveRecord::Base.connection.select_all(sql2).collect{|c|c['count(version_id)'].to_i}
       counted_by_version_and_project.each_with_index do |count,index|
         if count > 1
           #delete all the records that meet condition
           project_id = grouped_by_version_and_project[index]['project_id'].to_i
           version_id = grouped_by_version_and_project[index]['version_id'].to_i
           condition = "project_id=#{project_id} AND version_id=#{version_id}"
           delete_sql = "DELETE FROM #{asset_versions_projects_table} WHERE #{condition}"
           ActiveRecord::Base.connection.delete(delete_sql)
           #insert one record
           insert_sql = "INSERT INTO #{asset_versions_projects_table} VALUES (#{project_id}, #{version_id})"
           ActiveRecord::Base.connection.insert(insert_sql)
         end
       end
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

end