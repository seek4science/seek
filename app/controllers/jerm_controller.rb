class JermController < ApplicationController
  before_filter :login_required
  before_filter :is_user_admin_auth
  before_filter :jerm_enabled

  @@harvesters=nil

  layout "no_sidebar"

  def index
    
  end

  def fix_titles
    @assets=Asset.find(:all).select{|a| a.contributor.nil? && a.resource.title.include?("'")}
    respond_to do |format|
      format.html
    end
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
      downloader=Jerm::DownloaderFactory.create project.name
      data_hash = downloader.get_remote_data uri,project.site_username,project.site_password, type
      send_data data_hash[:data], :filename => data_hash[:filename] || resource.original_filename, :content_type => data_hash[:content_type] || resource.content_type, :disposition => 'attachment'
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
          resources << resource
        end
      end
    end

    begin
      populator = Jerm::EmbeddedPopulator.new
      @responses = populator.populate_collection(resources)
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
    Sop.destroy_all

    @project=Project.find(params[:project])
    @project.decrypt_credentials
    if @project.site_root_uri.blank?
      flash.now[:error]="No remote site location defined"
    elsif @project.site_password.blank?
      flash.now[:error]="No password has been defined"
    else
      begin
        harvester = construct_project_harvester(@project.title,@project.site_root_uri,@project.site_username,@project.site_password)        
        @resources = harvester.update
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

  def construct_project_harvester project_name,root_uri,uname,pwd
    #removes hyphens from project name
    clean_project_name=project_name.gsub("-","")
    discover_harvesters if @@harvesters.nil?
    
    harvester_class=@@harvesters.find do |h|
      h.name.downcase.start_with?("jerm::"+clean_project_name.downcase)
    end
    raise Exception.new("Unable to find Harvester for project #{project_name}") if harvester_class.nil?
    return harvester_class.new(root_uri,uname,pwd)
  end

  def discover_harvesters
    Dir.chdir(File.join(RAILS_ROOT, "lib/jerm")) do
      Dir.glob("*harvester.rb").each do |f|
        ("jerm/" + f.gsub(/.rb/, '')).camelize.constantize
      end
    end
    harvesters=[]
    ObjectSpace.each_object(Class) do |c|
      harvesters << c if c < Jerm::Harvester
    end
    
    @@harvesters=harvesters
  end

  def jerm_enabled
    if (!JERM_ENABLED)
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
          Mailer.deliver_resources_harvested(resources[author], author.user, base_host) if EMAIL_ENABLED
        end
      rescue Exception=>e
        #FIXME: report exception back with the response
        puts "Email failed: #{e.message}"
      end
    end
  end

end
