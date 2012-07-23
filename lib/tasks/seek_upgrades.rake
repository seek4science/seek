require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'
require 'fastercsv'

namespace :seek do
  
  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :reset_publication_authors
  ]

  desc "Disassociates creators and refreshes the list of publication authors from the doi/pubmed for all publications"
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

  desc "guess publication authors and dump to a csv"
  task :guess_publication_authors_to_csv => [:environment] do
    FasterCSV.open("publication_authors.csv", "w") do |csv|
      Publication.all.each do |publication|
        publication.publication_authors.each do |author|
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
            csv << [publication.name, link_to(publication), author.first_name, author.last_name, link_to(author), match.first_name, match.last_name, link_to(match)]
          else
            csv << [publication.name, link_to(publication), author.first_name, author.last_name, link_to(author), nil, nil, nil]
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

    begin
      Rake::Task["sunspot:solr:reindex"].invoke if solr
    rescue 
      puts "Reindexing failed - maybe solr isn't running?' - Error: #{$!}."
      puts "If not You should start solr and run rake sunspot:reindex manually"
    end

    puts "Upgrade completed successfully"
  end


  desc "removes the older duplicate create activity logs that were added for a short period due to a bug (this only affects versions between stable releases)"
  task(:remove_duplicate_activity_creates=>:environment) do
    ActivityLog.remove_duplicate_creates
  end

end
