require 'grouped_pagination'

class Sample < ActiveRecord::Base
   belongs_to :specimen


  has_many :experiments
  alias_attribute :description, :comments
  validates_presence_of :title

  grouped_pagination :pages=>("A".."Z").to_a, :default_page => Seek::Config.default_page(self.name.underscore.pluralize)

end
