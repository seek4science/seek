require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'

namespace :seek do
  
  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :reindex_things,
            :reordering_authors_for_existing_publications
  ]

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade=>[:environment,"db:migrate","tmp:clear","tmp:assets:clear"]) do
    
    solr=Seek::Config.solr_enabled

    Seek::Config.solr_enabled=false

    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr

    puts "Upgrade completed successfully"
  end


  desc "removes the older duplicate create activity logs that were added for a short period due to a bug (this only affects versions between stable releases)"
  task(:remove_duplicate_activity_creates=>:environment) do
    ActivityLog.remove_duplicate_creates
  end

  task :reindex_things => :environment do
    #reindex_all task doesn't seem to work as part of the upgrade, because it doesn't successfully discover searchable types (possibly due to classes being in memory before the migration)
    ReindexingJob.add_items_to_queue DataFile.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Model.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Sop.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Publication.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Presentation.all, 5.seconds.from_now,2

    ReindexingJob.add_items_to_queue Assay.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Study.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Investigation.all, 5.seconds.from_now,2

    ReindexingJob.add_items_to_queue Person.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Project.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Specimen.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Sample.all, 5.seconds.from_now,2
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
end
