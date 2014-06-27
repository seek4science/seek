#encoding: utf-8
require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'
require 'colorize'


namespace :seek do

  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :update_assay_types_from_ontology,
            :update_technology_types_from_ontology,
             :update_top_level_assay_type_titles,
            :repopulate_missing_publication_book_titles,
            :resynchronise_assay_types,
            :resynchronise_technology_types,
            :remove_invalid_group_memberships,
            :clear_filestore_tmp,
            :repopulate_auth_lookup_tables,
  ]

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade=>[:environment,"db:migrate","db:sessions:clear","tmp:clear"]) do

    solr=Seek::Config.solr_enabled

    Seek::Config.solr_enabled=false

    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr

    if (solr)
      Rake::Task["seek:reindex_all"].invoke
    end

    puts "Upgrade completed successfully"
  end

  desc("Cleans out group memberships where the person no longer exists")
  task(:remove_invalid_group_memberships => :environment) do
    invalid = GroupMembership.select{|gm| gm.person.nil? || gm.work_group.nil?}
    invalid.each do |inv|
      inv.destroy
    end
  end



  desc("Synchronised the assay types assigned to assays according to the current ontology")
  task(:resynchronise_assay_types => :environment) do

    label_map = read_label_map(:assay_types)

    Assay.record_timestamps = false

    Assay.all.each do |assay|
      assay_type_label_hash = assay.assay_type_reader.class_hierarchy.hash_by_label

      label = assay[:assay_type_label].try(:downcase)

      unless label.nil?
        #check to see if the label can resolve to a uri
        resolved_uri = assay_type_label_hash[label].try(:uri).try(:to_s)

        #if the resolved uri is nil try a mapped label
        resolved_uri ||= assay_type_label_hash[label_map[label]].try(:uri).try(:to_s)

        #if the uri is resolved, update the stored uri and remove the label
        unless resolved_uri.nil?
          if assay.assay_type_uri != resolved_uri
            assay.assay_type_uri = resolved_uri
            puts "the assay type URI for Assay #{assay.id} updated to #{resolved_uri.inspect} based on the label #{label.inspect}".green
          end
          assay.assay_type_label = nil
        end

      end

      unless assay.valid_assay_type_uri?
        #if the uri is still invalid, we need to set it to the default
        uri = assay[:assay_type_uri]
        puts "the assay type label and URI for Assay #{assay.id} cannot be resolved, so resetting the URI to the default, but keeping the stored label.\n\t the original label was #{label.inspect} and URI was #{uri.inspect}".red
        assay.use_default_assay_type_uri!
      end

      unless assay.suggested_assay_type_label.nil?
         puts "The Assay #{assay.id} has a suggested assay type label of #{assay.assay_type_label.inspect}, currently attached to the parent URI #{assay.assay_type_uri.inspect}".yellow
      end

      disable_authorization_checks do
        assay.save if assay.changed?
      end

    end
    Assay.record_timestamps = true
  end

  desc("Synchronised the technology types assigned to assays according to the current ontology")
  task(:resynchronise_technology_types => :environment) do
    Assay.record_timestamps = false

    tech_type_label_hash = Seek::Ontologies::TechnologyTypeReader.instance.class_hierarchy.hash_by_label

    label_map = read_label_map(:technology_types)

    Assay.all.each do |assay|
      unless assay.is_modelling?
        label = assay[:technology_type_label].try(:downcase)
        unless label.nil?

          resolved_uri = tech_type_label_hash[label].try(:uri).try(:to_s)

          #if the resolved uri is nil try a mapped label
          resolved_uri ||= tech_type_label_hash[label_map[label]].try(:uri).try(:to_s)

          #if the uri is resovled, update the stored uri and remove the label
          unless resolved_uri.nil?
            if assay.technology_type_uri != resolved_uri
              assay.technology_type_uri = resolved_uri
              puts "the technology type URI for Assay #{assay.id} updated to #{resolved_uri.inspect} based on the label #{label.inspect}".green
            end
            assay.technology_type_label = nil
          end

        end
      else
        assay.technology_type_uri = nil
      end
      unless assay.valid_technology_type_uri?
        uri = assay[:technology_type_uri]
        puts "the technology type label and URI for Assay #{assay.id} cannot be resolved, so resetting the URI to the default, but keeping the stored label.\n\t the original label was #{label.inspect} and URI was #{uri.inspect}".red
        assay.use_default_technology_type_uri!
      end

      disable_authorization_checks do
        assay.save if assay.changed?
      end
      unless assay.suggested_technology_type_label.nil?
        puts "The Assay #{assay.id} has a suggested technology type label of #{assay.technology_type_label.inspect}, currently attached to the parent URI #{assay.technology_type_uri.inspect}".yellow
      end
    end
    Assay.record_timestamps = true
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

        #If no results, match by normalised name, taken from grouped_pagination.rb
        if matches.empty?
          seek_authors.each do |seek_author|
            ascii1 = normalize_name(author.last_name)
            ascii2 = normalize_name(seek_author.last_name)
            matches << seek_author if (ascii1 == ascii2)
          end
        end

        #special normalization case for umlaut: e.g. ü match ue
        if matches.empty?
          seek_authors.each do |seek_author|
            ascii1 = normalize_name(author.last_name, false, true)
            ascii2 = normalize_name(seek_author.last_name, false, true)
            matches << seek_author if (ascii1 == ascii2)
          end
        end

        #if no results, match by parts of last name
        if matches.empty?
          matches = seek_authors.select{|seek_author| Regexp.new(seek_author.last_name, Regexp::IGNORECASE).match(author.last_name) ||
                                                      Regexp.new(author.last_name, Regexp::IGNORECASE).match(seek_author.last_name)}
        end

        match = matches.first
        unless match.nil?
          updating_publication_author_order = PublicationAuthorOrder.where(["publication_id=? AND author_id=? AND author_type=?", publication.id, author.id, 'PublicationAuthor' ]).first
          updating_publication_author_order.author = match
          updating_publication_author_order.save
          author.delete
        end
      end
  end

  private

  def read_label_map type
    file = "#{type.to_s}_label_mappings.yml"
    file = File.join(Rails.root,"config","default_data",file)
    YAML::load_file(file)
  end

  def normalize_name(name, remove_special_character=true, replace_umlaut=false)
    #handle the characters that can't be handled through normalization
    %w[ØO].each do |s|
      name.gsub!(/[#{s[0..-2]}]/, s[-1..-1])
    end

    codepoints = name.mb_chars.normalize(:d).split(//u)
    if remove_special_character
      ascii=codepoints.map(&:to_s).reject{|e| e.bytesize > 1}.join
    end
    if replace_umlaut
      ascii=codepoints.map(&:to_s).collect {|e| e == '̈' ? 'e' : e}.join
    end
    ascii
  end
end
