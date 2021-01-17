class EventSerializer < BaseSerializer
  attributes :title, :description, :url,
             :address, :city, :country,
             :start_date, :end_date

  has_many :submitter # set seems to be one way of doing optional
  has_many :projects
  has_many :data_files
  has_many :publications
  has_many :presentations

  def country
    if object.country
      if object.country.length == 2 #a code
        CountryCodes.country(object.country)
      else
        object.country
      end
    end
  end
end
