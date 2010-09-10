module HomeHelper

  RECENT_SIZE=5

  def recent_project_changes_hash

    projects=current_user.person.projects
    people=Person.find(:all,:order=>'updated_at DESC')
    selected_people=[]

    people.each do |p|      
      selected_people << p if !(projects & p.projects).empty?
      break if selected_people.size>=RECENT_SIZE
    end
    
    selected_models=[]
    Model.find(:all,:order=>'updated_at DESC').each do |m|
      selected_models << m if projects.include?(m.project) && m.can_view?(current_user)
      break if selected_models.size>=RECENT_SIZE
    end

    selected_sops=[]
    Sop.find(:all,:order=>'updated_at DESC').each do |s|
      selected_sops << s if projects.include?(s.project) && s.can_view?(current_user)
      break if selected_sops.size>=RECENT_SIZE
    end
    
    selected_data_files=[]
    DataFile.find(:all,:order=>'updated_at DESC').each do |df|
      selected_data_files << df if projects.include?(df.project) && df.can_view?(current_user)
      break if selected_data_files.size>=RECENT_SIZE
    end

    selected_studies=[]
    Study.find(:all,:order=>'updated_at DESC').each do |s|
      selected_studies << s if projects.include?(s.project)
      break if selected_studies.size>=RECENT_SIZE
    end

    selected_assays=[]
    Assay.find(:all,:order=>'updated_at DESC').each do |a|
      selected_assays << a if projects.include?(a.project)
      break if selected_assays.size>=RECENT_SIZE
    end

    selected_investigations=[]
    Investigation.find(:all,:order=>'updated_at DESC').each do |i|
      selected_investigations << i if projects.include?(i.project)
      break if selected_investigations.size>=RECENT_SIZE
    end
    
    selected_publications=[]
    Publication.find(:all,:order=>'updated_at DESC').each do |i|
      selected_publications << i if projects.include?(i.project)
      break if selected_publications.size>=RECENT_SIZE
    end

    item_hash=classify_for_tabs(selected_people)
    item_hash.merge! classify_for_tabs(selected_models)
    item_hash.merge! classify_for_tabs(selected_sops)
    item_hash.merge! classify_for_tabs(selected_data_files)
    item_hash.merge! classify_for_tabs(selected_assays)
    item_hash.merge! classify_for_tabs(selected_studies)
    item_hash.merge! classify_for_tabs(selected_investigations)
    item_hash.merge! classify_for_tabs(selected_publications)

    return item_hash

  end

  def recent_changes_hash
    selected_people=Person.find(:all,:order=>'updated_at DESC',:limit=>RECENT_SIZE)
    selected_projects=Project.find(:all,:order=>'updated_at DESC',:limit=>RECENT_SIZE)
    selected_models=[]
    selected_data_files=[]
    selected_sops=[]
    selected_assays=Assay.find(:all,:order=>'updated_at DESC',:limit=>RECENT_SIZE)
    selected_studies=Study.find(:all,:order=>'updated_at DESC',:limit=>RECENT_SIZE)
    selected_investigations=Investigation.find(:all,:order=>'updated_at DESC',:limit=>RECENT_SIZE)
    selected_publications=Publication.find(:all,:order=>'updated_at DESC',:limit=>RECENT_SIZE)

    Model.find(:all,:order=>'updated_at DESC').each do |m|
      selected_models << m if m.can_view?(current_user)
      break if selected_models.size>=RECENT_SIZE
    end

    Sop.find(:all,:order=>'updated_at DESC').each do |s|
      selected_sops << s if s.can_view?(current_user)
      break if selected_sops.size>=RECENT_SIZE
    end

    DataFile.find(:all,:order=>'updated_at DESC').each do |df|
      selected_data_files << df if df.can_view?(current_user)
      break if selected_data_files.size>=RECENT_SIZE
    end

    item_hash=classify_for_tabs(selected_people)
    item_hash.merge! classify_for_tabs(selected_projects)
    item_hash.merge! classify_for_tabs(selected_models)
    item_hash.merge! classify_for_tabs(selected_sops)
    item_hash.merge! classify_for_tabs(selected_data_files)
    item_hash.merge! classify_for_tabs(selected_assays)
    item_hash.merge! classify_for_tabs(selected_studies)
    item_hash.merge! classify_for_tabs(selected_investigations)
    item_hash.merge! classify_for_tabs(selected_publications)

    return item_hash
  end

  
end
