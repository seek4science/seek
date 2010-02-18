class JermController < ApplicationController
  before_filter :login_required
  before_filter :is_user_admin_auth
  before_filter :jerm_enabled

  @@harvesters=nil

  def index
    
  end

  def test
    
    project_id=params[:project]

    @project=Project.find(project_id)
    @project.decrypt_credentials
    if @project.site_root_uri.blank?
      flash.now[:error]="No remote site location defined"
    elsif @project.site_password.blank?
      flash.now[:error]="No password has been defined"
    else
      begin
        harvester = construct_project_harvester(@project.title,@project.site_root_uri,@project.site_username,@project.site_password)
        @responses = harvester.update
        response_order=[:success,:warning,:fail,:skipped]
        @responses=@responses.sort_by{|a| response_order.index(a[:response])}
        inform_authors if EMAIL_ENABLED
      rescue Exception => @exception
        puts @exception
      end
    end

    render :update do |page|
      if @exception
        page.replace_html :results,:partial=>"exception",:object=>@exception
      else
        page.replace_html :results,:partial=>"results",:object=>@responses
      end      
    end

  end

  private

  def construct_project_harvester project_name,root_uri,uname,pwd
    #removes hyphens from project name
    clean_project_name=project_name.gsub("-","")
    discover_harvesters if @@harvesters.nil?
    
    harvester_class=@@harvesters.find do |h|
      puts "comparing #{h.name.downcase} with #{clean_project_name.downcase}"
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
      if r[:seek_model]
        resources[r[:seek_model].contributor_id] ||= []
        resources[r[:seek_model].contributor_id] << r
      end
    end 
    resources.each_key do |author_id|
      author = User.find_by_id(author_id).person
      unless author.nil? || author.user.nil?
        Mailer.deliver_resources_harvested(resources[author_id], author.user, base_host)
      end
    end
  end

end
