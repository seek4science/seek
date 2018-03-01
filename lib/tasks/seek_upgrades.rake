# encoding: utf-8

require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'colorize'
require 'seek/mime_types'
require 'simple_crypt' # TODO: Remove me in 1.7

include Seek::MimeTypes
include SimpleCrypt # TODO: Remove me in 1.7

namespace :seek do
  # these are the tasks required for this version upgrade
  task upgrade_version_tasks: %i[
    environment
    rebuild_sample_templates
    delete_redundant_subscriptions
    update_sample_resource_links
    move_site_credentials_to_settings
    reencrypt_settings
    convert_organism_concept_uris
    merge_duplicate_organisms
  ]

  # these are the tasks that are executes for each upgrade as standard, and rarely change
  task standard_upgrade_tasks: %i[
    environment
    clear_filestore_tmp
    repopulate_auth_lookup_tables

  ]

  desc('upgrades SEEK from the last released version to the latest released version')
  task(upgrade: [:environment, 'db:migrate', 'tmp:clear']) do
    solr = Seek::Config.solr_enabled
    Seek::Config.solr_enabled = false

    begin
      Rake::Task['seek:standard_upgrade_tasks'].invoke
      Rake::Task['seek:upgrade_version_tasks'].invoke

      Seek::Config.solr_enabled = solr
      Rake::Task['seek:reindex_all'].invoke if solr

      puts 'Upgrade completed successfully'
    ensure
      Seek::Config.solr_enabled = solr
    end

  end

  task(rebuild_sample_templates: :environment) do
    SampleType.all.reject{|st| st.uploaded_template?}.each do |sample_type|
      sample_type.queue_template_generation
    end
  end

  task(delete_redundant_subscriptions: :environment) do
    types = ['Specimen', 'Treatment']
    types.each do |type|
      subs = Subscription.where(subscribable_type: 'Specimen')
      if subs.any?
        puts "Deleting #{subs.count} subscriptions linked to #{type}"
        disable_authorization_checks { subs.destroy_all }
      end
    end

    sample_switch_date = Date.parse('2016-09-01')
    samp_subs = Subscription.where(subscribable_type: 'Sample').where('created_at < ?', sample_switch_date)
    if samp_subs.any?
      puts "Deleting #{samp_subs.count} subscriptions linked to old samples (created before #{sample_switch_date})"
      disable_authorization_checks { samp_subs.destroy_all }
    end

    types = ['Strain', 'Sample']
    types.each do |type|
      subs = Subscription.where(subscribable_type: type)
      subs = subs.select { |s| s.subscribable.nil? rescue true }
      if subs.any?
        puts "Deleting #{subs.count} subscriptions linked to non-existent #{type}"
        disable_authorization_checks { subs.each(&:destroy) }
      end
    end
  end

  task(update_sample_resource_links: :environment) do
    pre_count = SampleResourceLink.count
    Sample.all.each do |sample|
      sample.send(:update_sample_resource_links)
    end
    puts "Created #{SampleResourceLink.count - pre_count} SampleResourceLinks"
  end

  task(move_site_credentials_to_settings: :environment) do
    puts 'Moving project site credentials into settings table...'

    global_passphrase = (defined? GLOBAL_PASSPHRASE) ? GLOBAL_PASSPHRASE : 'ohx0ipuk2baiXah'
    key = generate_key(global_passphrase)
    conversions = 0

    Project.all.each do |project|
      if project.site_credentials.present?
        credentials_hash = decrypt(Base64.decode64(project.site_credentials), key)
        project.site_username = credentials_hash[:username]
        project.site_password = credentials_hash[:password]
        project.update_column(:site_credentials, nil)
        conversions += 1
      end
    end

    puts "#{conversions} project site credentials migrated"
  end

  task(reencrypt_settings: :environment) do
    puts 'Re-encrypting SMTP settings and Datacite password...'

    global_passphrase = (defined? GLOBAL_PASSPHRASE) ? GLOBAL_PASSPHRASE : 'ohx0ipuk2baiXah'
    key = generate_key(global_passphrase)

    smtp = Seek::Config.smtp
    if smtp
      begin
        if smtp[:password]
          if smtp[:password].encoding.name == 'ASCII-8BIT'
            print "Attempting to decrypt SMTP password... "
            plaintext = decrypt(smtp[:password], key)
            smtp[:password] = plaintext
            Seek::Config.smtp = smtp
            puts 'done'
          else
            puts "SMTP password already decrypted (encoding: #{smtp[:password].encoding.name})- skipping"
          end
        else
          puts 'No SMTP password found - skipping'
        end
      rescue OpenSSL::Cipher::CipherError => e
        puts 'OpenSSL::Cipher::CipherError occurred when decrypting SMTP password - Already decrypted?'
        puts e.message
      end
    else
      puts 'No SMTP settings found - skipping'
    end

    datacite_password = Seek::Config.datacite_password
    if datacite_password.present?
      begin
        if datacite_password.encoding.name == 'ASCII-8BIT'
          print "Attempting to decrypt datacite password... "
          plaintext = decrypt(datacite_password, key)
          Seek::Config.datacite_password = plaintext
          puts 'done'
        else
          puts "Datacite password already decrypted (encoding: #{datacite_password.encoding.name})- skipping"
        end
      rescue OpenSSL::Cipher::CipherError => e
        puts 'OpenSSL::Cipher::CipherError occurred when decrypting SMTP password - Already decrypted?'
        puts e.message
      end
    else
      puts 'No datacite password found - skipping'
    end

    puts 'Done'
  end

  task(convert_organism_concept_uris: :environment) do
    Organism.all.each do |organism|
      organism.convert_concept_uri
      if organism.bioportal_concept && organism.bioportal_concept.changed?
        organism.save(validate:false)
      end
    end
  end

  task(:merge_duplicate_organisms, [:dry_run] => :environment) do |t,args|
    dry_run = (args.dry_run == 'true')

    polymorphic_associations = {
        Annotation => [:annotatable],
        Annotation::Version => [:annotatable],
        AssayAsset => [:asset],
        AssetsCreator => [:asset],
        ContentBlob => [:asset],
        Favourite => [:resource],
        ProjectFolderAsset => [:asset],
        Relationship => [:subject, :other_object],
        SampleResourceLink => [:resource],
        SpecialAuthCode => [:asset],
        Subscription => [:subscribable],
        ActsAsTaggableOn::Tagging => [:taggable]
    }

    begin
      logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = Logger.new(STDOUT) if dry_run
      ActiveRecord::Base.transaction do
        disable_authorization_checks do
          duplicated = Organism.all.
              group_by { |o| o.ncbi_id }.
              select { |ncbi_id, organisms| !ncbi_id.nil? && ncbi_id!=0 && organisms.length > 1 }

          duplicated.each do |ncbi_id, organisms|
            sorted = organisms.sort_by(&:created_at)
            canonical = sorted.shift

            puts "Resolving #{organisms.count} duplicate#{'s' if organisms.count > 1} of #{canonical.title} (NCBI ID: #{canonical.ncbi_id})"
            puts "\tCanonical: #{canonical.title} (#{canonical.id})"
            sorted.each do |duplicate|
              puts "\tDuplicate: #{duplicate.title} (#{duplicate.id})"
            end

            sorted.each do |duplicate|
              # Strains
              duplicate.strains.each do |s|
                s.update_column(:organism_id, canonical.id)
              end

              # Projects
              canonical.projects += (duplicate.projects - canonical.projects)

              # Assays
              duplicate.assay_organisms.each do |ao|
                ao.update_column(:organism_id, canonical.id)
                # ao.refresh_assay_rdf
              end

              # Models
              duplicate.models.each do |m|
                m.update_column(:organism_id, canonical.id)
                m.versions.each do |mv|
                  if mv.organism_id == duplicate.id
                    mv.update_column(:organism_id, canonical.id)
                  end
                end
                # m.index!
              end

              # Other associations
              polymorphic_associations.each do |klass, associations|
                associations.each do |association|
                  klass.
                      where("#{association}_type" => 'Organism', "#{association}_id" => duplicate.id).
                      update_all("#{association}_id" => canonical.id)
                end
              end

              duplicate.destroy
            end
          end
        end

        raise ActiveRecord::Rollback if dry_run
      end
    ensure
      ActiveRecord::Base.logger = logger
    end
  end
end
