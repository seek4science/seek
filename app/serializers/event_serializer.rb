class EventSerializer < BaseSerializer
  attributes :title, :description, :url,
             :address, :city, :country,
             :start_date, :end_date

  has_many :submitter # set seems to be one way of doing optional
  has_many :projects
  has_many :data_files
  has_many :publications
  has_many :presentations
end
