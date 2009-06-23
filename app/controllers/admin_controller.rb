class AdminController < ApplicationController
  before_filter :login_required
  before_filter :is_user_admin_auth

  def show
    respond_to do |format|
      format.html
    end
  end

  def graphs

    width=300
    height=200

    data=created_at_data_for_model(Sop)
    dataset = GoogleChartDataset.new :data => data, :color => '0000DD'
    @sop_creation_graph = GoogleLineChart.new :width => width, :height => height, :title=>"Sop Creation"
    @sop_creation_graph.data = GoogleChartData.new :datasets => [dataset]

    data=created_at_data_for_model(Model)
    dataset = GoogleChartDataset.new :data => data, :color => '0000DD'
    @model_creation_graph = GoogleLineChart.new :width => width, :height => height, :title=>"Model Creation"
    @model_creation_graph.data = GoogleChartData.new :datasets => [dataset]

    data=created_at_data_for_model(DataFile)
    dataset = GoogleChartDataset.new :data => data, :color => '0000DD'
    @df_creation_graph = GoogleLineChart.new :width => width, :height => height, :title=>"Data File Creation"
    @df_creation_graph.data = GoogleChartData.new :datasets => [dataset]

    data=created_at_data_for_model(User)
    dataset = GoogleChartDataset.new :data => data, :color => 'DD0000'
    @user_creation_graph = GoogleLineChart.new :width => width, :height => height, :title=>"User creation"
    @user_creation_graph.data = GoogleChartData.new :datasets => [dataset]
  end
  
  private

  def created_at_data_for_model model
    x={}
    model.find(:all,:order=>:created_at).each do |i|
      date=i.created_at.to_date
      day=date.jd
      x[day] ||= 0
      x[day]+=1
    end
    sorted_keys=x.keys.sort
    (sorted_keys.first..sorted_keys.last).collect{|i| x[i].nil? ? 0 : x[i]  }
  end
  
end
