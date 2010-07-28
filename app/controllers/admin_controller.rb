class AdminController < ApplicationController
  before_filter :login_required
  before_filter :is_user_admin_auth  

  def show
    respond_to do |format|
      format.html
    end
  end

  def update_admins
    admin_ids = params[:admins]
    current_admins = Person.registered.select{|p| p.is_admin?}
    admins = admin_ids.collect{|id| Person.find(id)}
    current_admins.each{|ca| ca.user.is_admin=false}
    admins.each{|a| a.user.is_admin=true}
    (admins | current_admins).each do |admin|
      class << admin.user
        def record_timestamps
          false
        end
      end
      admin.user.save
    end
    redirect_to :action=>:show
  end
  
  def tags
    @tags=Tag.find(:all,:order=>:name)
  end  

  def edit_tag
    if request.post?
      @tag=Tag.find(params[:id])
      @tag.taggings.select{|t| !t.taggable.nil?}.each do |tagging|
        context_sym=tagging.context.to_sym
        taggable=tagging.taggable
        current_tags=taggable.tag_list_on(context_sym).select{|tag| tag!=@tag.name}
        new_tag_list=current_tags.join(", ")

        replacement_tags=", "
        params[:tags_autocompleter_selected_ids].each do |selected_id|
          tag=Tag.find(selected_id)
          replacement_tags << tag.name << ","
        end unless params[:tags_autocompleter_selected_ids].nil?
        params[:tags_autocompleter_unrecognized_items].each do |item|
          replacement_tags << item << ","
        end unless params[:tags_autocompleter_unrecognized_items].nil?

        new_tag_list=new_tag_list << replacement_tags

        method_sym="#{tagging.context.singularize}_list=".to_sym

        taggable.send method_sym, new_tag_list

        taggable.save

      end

      @tag=Tag.find(params[:id])
      
      @tag.destroy if @tag.taggings.select{|t| !t.taggable.nil?}.empty?

      #FIXME: don't like this, but is a temp solution for handling lack of observer callback when removing a tag
      expire_fragment("tag_clouds")

      redirect_to :action=>:tags
    else
      @tag=Tag.find(params[:id])
      @all_tags_as_json=Tag.find(:all).collect{|t| {'id'=>t.id, 'name'=>t.name}}.to_json
      respond_to do |format|
        format.html
      end
    end

  end

  def delete_tag
    tag=Tag.find(params[:id])
    if request.post?
      tag.delete
      flash.now[:notice]="Tag #{tag.name} deleted"

    else
      flash.now[:error]="Must be a post"
    end

    #FIXME: don't like this, but is a temp solution for handling lack of observer callback when removing a tag
    expire_fragment("tag_clouds")

    redirect_to :action=>:tags
  end
  
  def get_stats
    collection = []
    type = nil
    title = nil
    case params[:id]
      when "pals"
        title = "PALs"
        collection = Person.pals
        type = "users"
      when "admins"
        title = "Administrators"
        collection = User.admins
        type = "users"
      when "invalid"
        collection = {}
        type = "invalid_users"
        pal_role=Role.find(:first,:conditions=>{:name=>"Sysmo-DB Pal"})
        collection[:pal_mismatch] = Person.find(:all).select {|p| p.is_pal? != p.roles.include?(pal_role)}
        collection[:duplicates] = Person.duplicates
        collection[:no_person] = User.without_profile
      when "not_activated"
        title = "Users requiring activation"
        collection = User.not_activated
        type = "users"
      when "projectless"
        title = "Users not in a SysMO project"
        collection = Person.without_group.registered
        type = "users"
      when "contents"
        type = "content_stats"
      else
    end
    respond_to do |format|
      case type
        when "invalid_users"
          format.html { render :partial => "admin/invalid_user_stats_list", :locals => { :collection => collection} }          
        when "users"
          format.html { render :partial => "admin/user_stats_list", :locals => { :title => title, :collection => collection} }
        when "content_stats"
          format.html { render :partial => "admin/content_stats", :locals => {:stats => ContentStats.generate} }
      end
    end
  end

  private

  def created_at_data_for_model model
    x={}
    start="1 Nov 2008"

    x[Date.parse(start).jd]=0
    x[Date.today.jd]=0

    model.find(:all, :order=>:created_at).each do |i|
      date=i.created_at.to_date
      day=date.jd
      x[day] ||= 0
      x[day]+=1
    end
    sorted_keys=x.keys.sort
    (sorted_keys.first..sorted_keys.last).collect{|i| x[i].nil? ? 0 : x[i]  }
  end
  
  


end
