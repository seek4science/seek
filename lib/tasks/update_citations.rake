require 'rubygems'
require 'rake'


namespace :seek do
  desc "Update the publication citation style "

  task :change_pages_to_pp => :environment do
    Publication.where("citation LIKE '%pages%'").each do |t|
      puts t.citation
      t.update_column(:citation, t.citation.gsub("pages","pp."))
      puts t.citation
    end

    Publication.where("citation LIKE '%Pages%'").each do |t|
      puts t.citation
      t.update_column(:citation, t.citation.gsub("Pages","pp."))
      puts t.citation
    end

    Publication.where("citation LIKE '%page%'").each do |t|
      puts t.citation
      t.update_column(:citation, t.citation.gsub("page","p."))
      puts t.citation
    end

    Publication.where("citation LIKE '%Page%'").each do |t|
      puts t.citation
      t.update_column(:citation, t.citation.gsub("Page","p."))
      puts t.citation
    end

  end

  task :change_volume_to_vol => :environment do
    Publication.where("citation LIKE '%volume%'").each do |t|
      puts t.citation
      t.update_column(:citation, t.citation.gsub("volume","vol."))
    end

    Publication.where("citation LIKE '%Volume%'").each do |t|
      puts t.citation
      t.update_column(:citation, t.citation.gsub("Volume","vol."))
    end
    puts Publication.where("citation LIKE '%volume%'").count
  end

  task :remove_vol_pp_in_journal => :environment do


    Publication.where("citation LIKE '%vol.%' AND citation LIKE '%pp.%' AND publication_type_id=1").each do |t|
      parts =t.citation.split(',')

      parts.each do |part|
        if part.include? 'vol.'
          part.gsub!("vol. ","")
        end
        if part.include? 'pp.'
          part.gsub!("pp. ",":")
        end
        if part.include? 'p.'
          part.gsub!("p. ",":")
        end
      end

      join = parts.join(',')
      remove_comma = join.slice!(0..(join.index(':')-3))+join.slice((join.index(':'))..-1)
      t.update_column(:citation,remove_comma)
      puts t.citation
    end


  end
end