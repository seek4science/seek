class NelsController < ApplicationController

  before_filter :oauth_client
 # before_filter :nels_oauth_session, only: :browser
 # before_filter :rest_client, only: [:browser, :datasets, :data]

  def callback
    hash = @oauth_client.get_token(params[:code])

    oauth_session = current_user.oauth_sessions.where(provider: 'NeLS').first_or_initialize
    oauth_session.update_attributes(access_token: hash['access_token'], expires_in: 1.hour)

    redirect_to nels_browser_path
  end

  def browser
    respond_to do |format|
      format.html { render layout: 'nels' }
    end
  end

  def projects
    @data = [{"id"=>1123122, "name"=>"seek_pilot1"}, {"id"=>1123123, "name"=>"seek_pilot2"}]
    tree_data = @data.map { |n| { id: "project#{n['id']}", text: n['name'], parent: '#', state: { loaded: false },
                                  data: { id: n['id'] } } }
    respond_to do |format|
      format.json { render json: tree_data.to_json }
    end
  end

  def datasets
    @data = [{ 'name' => 'test dataset', 'id' => rand(99999) }, { 'name' => 'test dataset2', 'id' => rand(99999) }] # @rest_client.datasets(params[:id])
    tree_data = @data.map { |n| { id: "dataset#{n['id']}", text: n['name'], parent: "project#{params[:id]}",
                                  state: { loaded: false },
                                  data: { id: n['id'], project_id: params[:id] } } }
    respond_to do |format|
      format.json { render json: tree_data.to_json }
    end
  end

  def data
    @data = [{ 'name' => 'test data', 'id' => rand(99999) }, { 'name' => 'test data2', 'id' => rand(99999) }] # @rest_client.data(params[:project_id], params[:id])
    tree_data = @data.map { |n| { id: "data#{n['id']}", text: n['name'], parent: "dataset#{params[:id]}",
                                  data: { id: n['id'], project_id: params[:project_id], dataset_id: params[:id] } } }
    respond_to do |format|
      format.json { render json: tree_data.to_json }
    end
  end

  private

  def oauth_client
    @oauth_client = Nels::Oauth2::Client.new(Seek::Config.nels_client_id,
                                             Seek::Config.nels_client_secret,
                                             nels_oauth_callback_url)
  end

  def nels_oauth_session
    @oauth_session = current_user.oauth_sessions.where(provider: 'NeLS').first
    if !@oauth_session || @oauth_session.expired?
      redirect_to @oauth_client.authorize_url
    end
  end

  def rest_client
    @rest_client = Nels::Rest::Client.new(@oauth_session.access_token)
  end

end
