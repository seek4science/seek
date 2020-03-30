require 'rubygems'
require 'rake'


namespace :seek do
  desc "Update the publication citation style "

  task :change_pages_to_pp => :environment do
    Publication.where("citation LIKE '%pages%'").each do |t|
      puts t.citation
      t.update_column(:citation, t.citation.gsub("pages", "pp."))
      puts t.citation
    end

    Publication.where("citation LIKE '%Pages%'").each do |t|
      puts t.citation
      t.update_column(:citation, t.citation.gsub("Pages", "pp."))
      puts t.citation
    end

    Publication.where("citation LIKE '%page%'").each do |t|
      puts t.citation
      t.update_column(:citation, t.citation.gsub("page", "p."))
      puts t.citation
    end

    Publication.where("citation LIKE '%Page%'").each do |t|
      puts t.citation
      t.update_column(:citation, t.citation.gsub("Page", "p."))
      puts t.citation
    end

  end

  task :change_volume_to_vol => :environment do
    Publication.where("citation LIKE '%volume%'").each do |t|
      puts t.citation
      t.update_column(:citation, t.citation.gsub("volume", "vol."))
    end

    Publication.where("citation LIKE '%Volume%'").each do |t|
      puts t.citation
      t.update_column(:citation, t.citation.gsub("Volume", "vol."))
    end
    puts Publication.where("citation LIKE '%volume%'").count
  end

  task :remove_vol_pp_in_journal => :environment do
    Publication.where("citation LIKE '%vol.%' AND citation LIKE '%pp.%' AND publication_type_id=1").each do |t|
      parts = t.citation.split(',')

      parts.each do |part|
        if part.include? 'vol.'
          part.gsub!("vol. ", "")
        end
        if part.include? 'pp.'
          part.gsub!("pp. ", ":")
        end
        if part.include? 'p.'
          part.gsub!("p. ", ":")
        end
      end

      join = parts.join(',')
      remove_comma = join.slice!(0..(join.index(':') - 3)) + join.slice((join.index(':'))..-1)
      t.update_column(:citation, remove_comma)
      puts t.citation
    end
  end

  #run this task => bundle exec rake seek:refetch_metadata_with_doi

  task :refetch_metadata_with_doi => :environment do
  puts "Publications:" + Publication.count.to_s
  puts "Publications have DOI:" + Publication.where("doi IS NOT NULL").count.to_s
  Publication.where("doi IS NOT NULL").each do |t|
    unless (t.doi == "")
      before = t.citation
      t.extract_metadata(nil, t.doi)
      after = t.citation
      if (before != after)
        puts "ID:" + t.id.to_s
        puts "DOI:" + t.doi
        puts "before:" + before
        puts ("after:" + after+"\n")
        t.update_column(:citation, after)
      end
    end
  end
  end

  task :update_publications_authors_with_doi => :environment do
    log = Logger.new('./log/update_publication_authors_with_doi.log')
    log.level = Logger::INFO
    log.info "Publications:" + Publication.count.to_s
    log.info "Publications have DOI:" + Publication.where("doi IS NOT NULL").count.to_s
    Publication.where("doi IS NOT NULL").each_with_index  do |p, p_index|
      unless (p.doi == "")
        log.info (p_index+1).to_s+". ID:" +p.id.to_s+" DOI:"+p.doi+" authors_size("+p.publication_authors.size.to_s+")"+"\n"
        publication_authors_in_DB = p.publication_authors
        refected_publication_authors = p.fetch_pubmed_or_doi_result(nil, p.doi).nil? ?  nil : p.fetch_pubmed_or_doi_result(nil, p.doi).authors
        log.info refected_publication_authors.inspect
        if !refected_publication_authors.nil? && publication_authors_in_DB.size == refected_publication_authors.size
        publication_authors_in_DB.each_with_index  do |author, index|
            unless author.first_name == refected_publication_authors[index].first_name
              log.info(author.first_name+" "+author.last_name)
              author.update_column(:first_name, refected_publication_authors[index].first_name)
              log.info(author.first_name+" "+author.last_name)
            end
            unless author.last_name == refected_publication_authors[index].last_name
              log.info author.first_name+" "+author.last_name
              author.update_column(:last_name, refected_publication_authors[index].last_name)
              log.info author.first_name+" "+author.last_name+"\n"
            end
        end
        end
      end
    end
  end
end