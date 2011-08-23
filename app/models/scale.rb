class Scale < ActiveRecord::Base
  has_many :scalings, :dependent => :destroy

  alias_attribute :name, :title

  validates_presence_of :title
  validates_uniqueness_of :title

  def display_title
    case title
      when 'liverLobe'
        'Liver Lobe'
      when 'liverLobule'
        'Liver Lobule'
      else
        title.capitalize
    end

  end
end