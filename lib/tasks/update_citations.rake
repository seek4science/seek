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
end