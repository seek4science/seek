class JermController < ApplicationController
  before_filter :login_required
  before_filter :is_user_admin_auth
  before_filter :jerm_enabled
  
  @@harvester_factory=Jerm::JermHarvesterFactory.new
  @@populator = Jerm::EmbeddedPopulator.new
  
  def index
    
  end 
  
  def update_titles
    included_keys = params.keys.select{|k| k.start_with?("include_")}
    @assets=[]
    included_keys.each do |included|
      asset_id=included.gsub("include_","").to_i
      asset=Asset.find(asset_id)
      new_title=params["proposed_#{asset_id}"]
      asset.resource.update_attribute(:title,new_title)
      @assets << asset
    end
    respond_to do |format|
      format.html
    end
  end

  def download
    if params[:id]
      asset = Asset.find(params[:id])
      download_jerm_resource asset.resource
    else
      project=Project.find(params[:project])
      uri=params[:uri]
      type=params[:type]
      project.decrypt_credentials
      downloader=Jerm::DownloaderFactory.create project.title
      data_hash = downloader.get_remote_data uri,project.site_username,project.site_password, type
      send_data data_hash[:data], :filename => data_hash[:filename], :content_type => data_hash[:content_type] || resource.content_type, :disposition => 'attachment'
    end
  end
  
  def insert_results
    resources=[]
    @project=Project.find(params[:project])
    params.keys.each do |key|
      if key.start_with?("title")
        uuid=key.gsub("title_","")
        unless params["exclude_#{uuid}"]
          resource=Jerm::Resource.new
          resource.title=params[key]
          resource.project=params["project_#{uuid}"]
          resource.description=params["description_#{uuid}"]
          resource.author_first_name=params["first_name_#{uuid}"]
          resource.author_last_name=params["last_name_#{uuid}"]
          resource.author_seek_id=params["seek_id_#{uuid}"]
          resource.type=params["type_#{uuid}"]
          resource.uri=params["uri_#{uuid}"]
          resource.timestamp=params["timestamp_#{uuid}"]
          resource.duplicate=params["duplicate_#{uuid}"]
          resource.authorization=params["authorization_#{uuid}"]
          resource.filename=params["filename_#{uuid}"]
          resources << resource
        end
      end
    end
    
    begin
      
      @responses = @@populator.populate_collection(resources)
      response_order=[:success,:warning,:fail,:skipped]
      
      @responses=@responses.sort_by{|a| response_order.index(a[:response])}      
      @project.update_attribute(:last_jerm_run,Time.now)
      
      inform_authors
    rescue Exception => @exception
      puts @exception
    end
    
    render :update do |page|
      if @exception
        page.replace_html :results,:partial=>"exception",:object=>@exception
      else
        page.replace_html :results,:partial=>"insert_results",:object=>@responses
      end
    end
  end
  
  
  def fetch    
    @project=Project.find(params[:project])
    @project.decrypt_credentials
    if @project.site_root_uri.blank?
      flash.now[:error]="No remote site location defined"
    elsif @project.site_password.blank?
      flash.now[:error]="No password has been defined"
    else
      begin
        harvester = @@harvester_factory.construct_project_harvester(@project.title,@project.site_root_uri,@project.site_username,@project.site_password)        
        @resources = harvester.update
        @resources.each do |r| 
          begin
            r.duplicate=@@populator.exists?(r)
          rescue Exception=>e
            r.error=e
          end
        end
      rescue Exception => @exception
        puts @exception
      end
    end
    
    render :update do |page|
      if @exception
        page.replace_html :results,:partial=>"exception",:object=>@exception
      else
        page.replace_html :results,:partial=>"fetch_results",:object=>@resources
      end
    end
    
  end
  
  private
  
  
  
  
  
  def jerm_enabled
    if (!Seek::Config.jerm_enabled)
      error("JERM is not enabled","invalid action")
      return false
    end
  end
  
  def inform_authors
    resources = {}
    @responses.each do |r|
      if r[:seek_model] && r[:author]
        resources[r[:author]] ||= []
        resources[r[:author]] << r
      end
    end
    resources.each_key do |author|
      begin
        unless author.nil? || author.user.nil?
          Mailer.resources_harvested(resources[author], author.user).deliver_now if Seek::Config.email_enabled?
        end
      rescue Exception=>e
        #FIXME: report exception back with the response
        puts "Email failed: #{e.message}"
      end
    end
  end
  
end
