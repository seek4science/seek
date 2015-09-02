class StudiedFactor < ActiveRecord::Base
  include Seek::ExperimentalFactors::ModelConcerns

  belongs_to :data_file
  has_many :studied_factor_links, :before_add => proc {|sf,sfl| sfl.studied_factor = sf}, :dependent => :destroy
  alias_attribute :links,:studied_factor_links

  validates :data_file,presence:true


  def range_text
    #TODO: write test
    return start_value unless (end_value && end_value!=0)
    return "#{start_value} to #{end_value}"
  end

end
