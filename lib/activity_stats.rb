class ActivityStats
  
  #FIXME: this should be changed to iterate over the activity logs and gather, rather than all these multipe queries
  
  def monthly_users
    distinct_culprits_since 1.month.ago
  end
  
  def weekly_users
    distinct_culprits_since 1.week.ago
  end
  
  def alltime_users
    distinct_culprits_since
  end
  
  def daily_users
    distinct_culprits_since 1.day.ago
  end 
  
  def yearly_users
    distinct_culprits_since 1.year.ago
  end 
  
  # Uploaded/Registered
  
  def yearly_sops_uploaded
    assets_created_since "Sop",1.year.ago
  end
  
  def monthly_sops_uploaded
    assets_created_since "Sop",1.month.ago
  end
  
  def weekly_sops_uploaded
    assets_created_since "Sop",1.week.ago
  end
  
  def daily_sops_uploaded
    assets_created_since "Sop",1.day.ago
  end
  
  def yearly_models_uploaded
    assets_created_since "Model",1.year.ago
  end
  
  def monthly_models_uploaded
    assets_created_since "Model",1.month.ago
  end
  
  def weekly_models_uploaded
    assets_created_since "Model",1.week.ago
  end
  
  def daily_models_uploaded
    assets_created_since "Model",1.day.ago
  end
  
  def yearly_datafiles_uploaded
    assets_created_since "DataFile",1.year.ago
  end
  
  def monthly_datafiles_uploaded
    assets_created_since "DataFile",1.month.ago
  end
  
  def weekly_datafiles_uploaded
    assets_created_since "DataFile",1.week.ago
  end
  
  def daily_datafiles_uploaded
    assets_created_since "DataFile",1.day.ago
  end
  
  def yearly_publications_registered
    assets_created_since "Publication",1.year.ago
  end
  
  def monthly_publications_registered
    assets_created_since "Publication",1.month.ago
  end
  
  def weekly_publications_registered
    assets_created_since "Publication",1.week.ago
  end
  
  def daily_publications_registered
    assets_created_since "Publication",1.day.ago
  end
  
  #Downloaded
    
  def yearly_sops_downloaded
    assets_downloaded_since "Sop",1.year.ago
  end
  
  def monthly_sops_downloaded
    assets_created_since "Sop",1.month.ago
  end
  
  def weekly_sops_downloaded
    assets_created_since "Sop",1.week.ago
  end
  
  def daily_sops_downloaded
    assets_created_since "Sop",1.day.ago
  end
  
  def yearly_models_downloaded
    assets_created_since "Model",1.year.ago
  end
  
  def monthly_models_downloaded
    assets_created_since "Model",1.month.ago
  end
  
  def weekly_models_downloaded
    assets_created_since "Model",1.week.ago
  end
  
  def daily_models_downloaded
    assets_created_since "Model",1.day.ago
  end
  
  def yearly_datafiles_downloaded
    assets_created_since "DataFile",1.year.ago
  end
  
  def monthly_datafiles_downloaded
    assets_created_since "DataFile",1.month.ago
  end
  
  def weekly_datafiles_downloaded
    assets_created_since "DataFile",1.week.ago
  end
  
  def daily_datafiles_downloaded
    assets_downloaded_since "DataFile",1.day.ago
  end
  
  def yearly_publications_downloaded
    assets_downloaded_since "Publication",1.year.ago
  end
  
  def monthly_publications_downloaded
    assets_downloaded_since "Publication",1.month.ago
  end
  
  def weekly_publications_downloaded
    assets_downloaded_since "Publication",1.week.ago
  end
  
  def daily_publications_downloaded
    assets_downloaded_since "Publication",1.day.ago
  end
  
  
  private
  
  def assets_created_since type,time=500.years.ago
    ActivityLog.count(:all,:conditions=>["action='create' and activity_loggable_type= ? and created_at > ?",type,time])
  end
  
  def assets_downloaded_since type,time=500.years.ago
    ActivityLog.count(:all,:conditions=>["action='download' and activity_loggable_type= ? and created_at > ?",type,time])
  end
  
  def distinct_culprits_since time=500.years.ago
    ActivityLog.count(:all,:select=>"distinct culprit_id",:conditions=>["created_at > ?",time])
  end
  
end