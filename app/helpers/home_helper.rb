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
    item_hash=classify_for_tabs(selected_people)

    classes=Seek::Util.persistent_classes.select do |c|
        c.is_isa? || c.is_asset?
    end

    classes << Event if Seek::Config.events_enabled

    classes.each do |c|
      valid=[]
      c.find(:all,:order=>'updated_at DESC').each do |i|
        valid << i if projects.include?(i.project) && (!i.authorization_supported? || i.can_view?(current_user))
        break if valid.size >= RECENT_SIZE
      end
      item_hash.merge! classify_for_tabs(valid)
    end

    item_hash

  end

  def recent_changes_hash

    item_hash=classify_for_tabs(Person.find(:all,:order=>'updated_at DESC',:limit=>RECENT_SIZE))
    item_hash.merge! classify_for_tabs(Project.find(:all,:order=>'updated_at DESC',:limit=>RECENT_SIZE))

    classes=Seek::Util.persistent_classes.select do |c|
        c.is_isa? || c.is_asset?
    end

    classes << Event if Seek::Config.events_enabled

    classes.each do |c|
      valid=[]
      c.find(:all,:order=>"updated_at DESC").each do |i|
        valid << i if !i.authorization_supported? || i.can_view?(current_user)
        break if valid.size>=RECENT_SIZE
      end
      item_hash.merge! classify_for_tabs(valid)
    end

    item_hash
  end

  
end
