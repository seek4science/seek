require 'rubygems'
require 'rake'
require 'time'
require 'active_record/fixtures'
require 'csv'

namespace :seek_deliverables do

  task :asset_creation_dates => :environment do
    types=[DataFile,Model,Sop,Presentation,Assay,Study,Investigation,Project]
    puts 'type, creation date'
    types.each do |type|
      type_str=type.to_s
      type.send(:all).each do |item|
        puts "#{type_str}, #{item.created_at.strftime('%d-%m-%Y')}"
      end
    end
  end


  task :user_retention => :environment do
    users = User.all.select{|u| u.person } #only those with profiles
    puts 'id, registered, last activity'
    users.each do |user|
      id = user.id
      created_at = user.created_at
      last_active = ActivityLog.where(culprit_id:id).order(:created_at).last.try(:created_at)
      last_active ||= created_at
      puts "#{id},#{created_at.strftime('%d-%m-%Y')},#{last_active.strftime('%d-%m-%Y')}"
    end
  end

  #the first two tasks are for D2.2
  task :erasys_statistic_12_months => :environment do
    puts "12 months statistic"
    puts "Type / Project / No of assets / Size"
    t1=Time.new(2016, 02, 01)
    t2=Time.new(2017, 02, 01)
    p=Programme.find(5)
    projects = p.projects

    projects.each do |pro|
      ['data_files', 'sops', 'presentations'].each do |type|
        assets = pro.send(type)
        report_assets = assets.select { |a| a.created_at >= t1 && a.created_at <= t2 }

        content_blobs = report_assets.collect(&:content_blob)
        sizes = content_blobs.collect(&:file_size).compact
        allsize = 0
        sizes.each do |size|
          allsize +=size
        end
        human_size = Class.new.extend(ActionView::Helpers::NumberHelper).number_to_human_size(allsize)
        puts "#{type} / #{pro.title} / #{report_assets.count} / #{human_size}"
      end
    end
  end

  task :erasys_statistic_30_months => :environment do
    puts "30 months statistic"
    puts "Type / Project / No of assets / Size"
    t1=Time.new(2014, 8, 01)
    t2=Time.new(2017, 02, 01)
    p=Programme.find(5)
    projects = p.projects

    projects.each do |pro|
      ['data_files', 'sops', 'presentations'].each do |type|
        assets = pro.send(type)
        report_assets = assets.select { |a| a.created_at >= t1 && a.created_at <= t2 }

        content_blobs = report_assets.collect(&:content_blob)
        sizes = content_blobs.collect(&:file_size).compact
        allsize = 0
        sizes.each do |size|
          allsize +=size
        end
        human_size = Class.new.extend(ActionView::Helpers::NumberHelper).number_to_human_size(allsize)
        puts "#{type} / #{pro.title} / #{report_assets.count} / #{human_size}"
      end
    end
  end

  task :projects_and_assets => :environment do
    puts "Programme / Projects / No of assets"

    projects = Project.all.sort_by(&:programme_id)
    projects.each do |project|
      asset_count = project.assets.count
      programme_title = project.programme.try(:title)
      puts "#{programme_title} / #{project.title} / #{asset_count}"
    end
  end


  desc('user statistic 12_months')
  task :user_statistic_12_months => :environment do
    puts "12 months statistic"
    puts "all / erasysapp / others"
    [User].each do |type|
      puts "#{type.name}"

      t1=Time.new(2016, 02, 01)
      t2=Time.new(2017, 02, 01)
      recent=type.where(:created_at => (t1..t2))

      recent_era = recent.select do |i|
        person = i.person
        unless person.nil?
          person.projects.collect(&:programme).compact.collect(&:id).include?(5)
        end
      end

      only_era=recent.select do |i|
        person = i.person
        unless person.nil?
          person.projects.collect(&:programme).compact.collect(&:id) == [5]
        end
      end

      not_era=recent-only_era

      puts "#{recent.count} #{recent_era.count} #{not_era.count}"
    end
  end

  desc('user statistic 30_months')
  task :user_statistic_30_months => :environment do
    puts "30 months statistic"
    puts "all / erasysapp / others"
    [User].each do |type|
      puts "#{type.name}"
      t1=Time.new(2014, 8, 01)
      t2=Time.new(2017, 02, 01)
      recent=type.where(:created_at => (t1..t2))

      recent_era = recent.select do |i|
        person = i.person
        unless person.nil?
          person.projects.collect(&:programme).compact.collect(&:id).include?(5)
        end
      end

      only_era=recent.select do |i|
        person = i.person
        unless person.nil?
          person.projects.collect(&:programme).compact.collect(&:id) == [5]
        end
      end

      not_era=recent-only_era

      puts "#{recent.count} #{recent_era.count} #{not_era.count}"
    end
  end

  task :asset_statistic_12_months => :environment do
    puts "12 months statistic"
    puts "all / erasysapp / others/ download"
    [Investigation, Study, Assay, DataFile, Model, Sop, Publication, Presentation, Event].each do |type|
      puts "#{type.name}"
      all=type.all
      era=all.select { |i| i.projects.collect(&:programme).compact.collect(&:id).include?(5) }
      t1=Time.new(2016, 02, 01)
      t2=Time.new(2017, 02, 01)
      recent=type.where(:created_at => (t1..t2))
      recent_era = recent.select { |i| i.projects.collect(&:programme).compact.collect(&:id).include?(5) }

      only_era=all.select { |i| i.projects.collect(&:programme).compact.collect(&:id) == [5] }
      not_era=all-only_era
      recent_not_era = not_era.collect(&:id) & recent.collect(&:id)

      recent_download_count = ActivityLog.where(:action => 'download', :activity_loggable_type => "#{type.name}", :created_at => (t1..t2)).no_spider.count

      puts "#{recent.count} #{recent_era.count} #{recent_not_era.count} #{recent_download_count}"
    end
  end

  task :users_30_months => :environment do
    t1=Time.new(2014, 8, 01)
    t2=Time.new(2017, 02, 01)
    puts ActivityLog.where(:created_at => (t1..t2)).select("distinct culprit_id").count
  end

  task :asset_statistic_30_months => :environment do
    puts "30 months statistic"
    puts "all / erasysapp / not erasysapp"
    [Investigation, Study, Assay, DataFile, Model, Sop, Publication, Presentation, Event].each do |type|
      puts "#{type.name}"
      all=type.all
      era=all.select { |i| i.projects.collect(&:programme).compact.collect(&:id).include?(5) }
      t1=Time.new(2014, 8, 01)
      t2=Time.new(2017, 02, 01)
      recent=type.where(:created_at => (t1..t2))
      recent_era = recent.select { |i| i.projects.collect(&:programme).compact.collect(&:id).include?(5) }

      only_era=all.select { |i| i.projects.collect(&:programme).compact.collect(&:id) == [5] }
      not_era=all-only_era
      recent_not_era = not_era.collect(&:id) & recent.collect(&:id)

      recent_download_count = ActivityLog.where(:action => 'download', :activity_loggable_type => "#{type.name}", :created_at => (t1..t2)).no_spider.count

      puts "#{recent.count} #{recent_era.count} #{recent_not_era.count} #{recent_download_count}"
    end
  end

  task :programm_size_12_months => :environment do
    t1=Time.new(2016, 02, 01)
    t2=Time.new(2017, 02, 01)
    puts "12 months statistic"
    puts "title / size"
    Programme.all.each do |programme|
      total_asset_size= programme.projects.sum do |project|
        recent_assets = project.assets.select { |a| t1 <= a.created_at && a.created_at <= t2 }
        recent_assets.sum do |asset|
          if asset.respond_to?(:content_blob)
            asset.content_blob.file_size || 0
          elsif asset.respond_to?(:content_blobs)
            asset.content_blobs.sum do |blob|
              blob.file_size || 0
            end
          else
            0
          end
        end
      end

      size = Class.new.extend(ActionView::Helpers::NumberHelper).number_to_human_size(total_asset_size)
      puts "#{programme.title} / #{size}"
    end
  end

  task :programm_size_30_months => :environment do
    t1=Time.new(2014, 8, 01)
    t2=Time.new(2017, 02, 01)
    puts "30 months statistic"
    puts "title / size"
    Programme.all.each do |programme|
      total_asset_size= programme.projects.sum do |project|
        recent_assets = project.assets.select { |a| t1 <= a.created_at && a.created_at <= t2 }
        recent_assets.sum do |asset|
          if asset.respond_to?(:content_blob)
            asset.content_blob.file_size || 0
          elsif asset.respond_to?(:content_blobs)
            asset.content_blobs.sum do |blob|
              blob.file_size || 0
            end
          else
            0
          end
        end
      end

      size = Class.new.extend(ActionView::Helpers::NumberHelper).number_to_human_size(total_asset_size)
      puts "#{programme.title} / #{size}"
    end
  end

  task :asset_type_12_months => :environment do
    t1=Time.new(2016, 02, 01)
    t2=Time.new(2017, 02, 01)
    puts "12 months statistic"
    puts "Data file type : Count"
    df_content_type_groups = DataFile.where(:created_at => (t1..t2)).collect(&:content_blob).group_by(&:human_content_type)
    df_content_type_groups.each do |key, value|
      puts "#{key} : #{value.count}"
    end
    puts "--------------------"
    puts "Model type : Count"
    #model types
    model_types = Model.where(:created_at => (t1..t2)).collect(&:model_type)
    model_type_groups = model_types.compact.group_by(&:title)
    model_type_groups.each do |key, value|
      puts "#{key} : #{value.count}"
    end
    puts "no type assigned : #{model_types.count - model_types.compact.count}"

    puts "--------------------"
    puts "Model format : Count"
    #model format
    model_formats = Model.where(:created_at => (t1..t2)).collect(&:model_format)
    model_format_groups = model_formats.compact.group_by(&:title)
    model_format_groups.each do |key, value|
      puts "#{key} : #{value.count}"
    end
    puts "no type assigned : #{model_formats.count - model_formats.compact.count}"

    puts "--------------------"
    puts "SOP type : Count"
    sop_content_type_groups = Sop.where(:created_at => (t1..t2)).collect(&:content_blob).group_by(&:human_content_type)
    sop_content_type_groups.each do |key, value|
      puts "#{key} : #{value.count}"
    end
  end

  task :asset_type_30_months => :environment do
    t1=Time.new(2014, 8, 01)
    t2=Time.new(2017, 02, 01)
    puts "30 months statistic"
    puts "DataFile type : Count"
    df_content_type_groups = DataFile.where(:created_at => (t1..t2)).collect(&:content_blob).group_by(&:human_content_type)
    df_content_type_groups.each do |key, value|
      puts "#{key} : #{value.count}"
    end
    puts "--------------------"
    puts "Model type : Count"
    #model types
    model_types = Model.where(:created_at => (t1..t2)).collect(&:model_type)
    model_type_groups = model_types.compact.group_by(&:title)
    model_type_groups.each do |key, value|
      puts "#{key} : #{value.count}"
    end
    puts "no type assigned : #{model_types.count - model_types.compact.count}"

    puts "--------------------"
    puts "Model format : Count"
    #model format
    model_formats = Model.where(:created_at => (t1..t2)).collect(&:model_format)
    model_format_groups = model_formats.compact.group_by(&:title)
    model_format_groups.each do |key, value|
      puts "#{key} : #{value.count}"
    end
    puts "no type assigned : #{model_formats.count - model_formats.compact.count}"

    puts "--------------------"
    puts "SOP type : Count"
    sop_content_type_groups = Sop.where(:created_at => (t1..t2)).collect(&:content_blob).group_by(&:human_content_type)
    sop_content_type_groups.each do |key, value|
      puts "#{key} : #{value.count}"
    end
  end

end