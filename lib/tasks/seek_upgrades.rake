require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'


namespace :seek do

  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :add_term_uris_to_assay_types,
            :add_term_uris_to_technology_types,
            :repopulate_auth_lookup_tables,
            :correct_content_type_for_jpg,
            :update_jws_online_root
  ]

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
      disable_authorization_checks{strain.save(:validate=>false)}
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

  desc "content type of jpg is image/jpeg, instead of image/jpg"
  task(:correct_content_type_for_jpg=>:environment) do
    content_blobs = ContentBlob.find(:all, :conditions => ['content_type=?', 'image/jpg'])
    content_blobs.each do |cb|
      cb.content_type = 'image/jpeg'
      cb.save
    end
  end

  desc "update jws online root to point to http://jjj.mib.ac.uk/"
  task(:update_jws_online_root => :environment) do
     Seek::Config.jws_online_root = 'http://jjj.mib.ac.uk/'
  end
end
