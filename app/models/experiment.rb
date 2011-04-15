require 'grouped_pagination'
class Experiment < ActiveRecord::Base
  belongs_to :sample
  belongs_to :person
  belongs_to :institution
  has_many :projects


  has_and_belongs_to_many :data_files

   validates_presence_of :title
   validates_uniqueness_of :title

  grouped_pagination :pages=>("A".."Z").to_a, :default_page => Seek::Config.default_page(self.name.underscore.pluralize)



end
