require 'grouped_pagination'
require 'acts_as_authorized'

class Sample < ActiveRecord::Base
  belongs_to :specimen
  belongs_to :institution
  has_many :assays

  has_many :assets_creators, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
  has_many :creators, :class_name => "Person", :through => :assets_creators, :order=>'assets_creators.id'


  alias_attribute :description, :comments
  validates_presence_of :title
  validates_uniqueness_of :title
  validates_presence_of :specimen,:lab_internal_number
  validates_presence_of :donation_date


  has_and_belongs_to_many :tissue_and_cell_types

  grouped_pagination :pages=>("A".."Z").to_a, :default_page => Seek::Config.default_page(self.name.underscore.pluralize)

  acts_as_solr(:fields=>[:description,:title,:lab_internal_number],:include=>[:specimen,:assays]) if Seek::Config.solr_enabled

  acts_as_authorized


  def can_delete? user=User.current_user
    assays.empty? && mixin_super(user)
  end

  def self.user_creatable?
    true
  end
  def associate_tissue_and_cell_type tissue_and_cell_type_id,tissue_and_cell_type_title
       tissue_and_cell_type=nil
    if tissue_and_cell_type_title && !tissue_and_cell_type_title.empty?
      if ( tissue_and_cell_type_id =="0" )
          found = TissueAndCellType.find(:first,:conditions => {:title => tissue_and_cell_type_title})
          unless found
          tissue_and_cell_type = TissueAndCellType.create!(:title=> tissue_and_cell_type_title)
          end
      else
          tissue_and_cell_type = TissueAndCellType.find_by_id(tissue_and_cell_type_id)
      end
    end
   if !tissue_and_cell_type.nil?
     existing = false
     self.tissue_and_cell_types.each do |t|
       if t == tissue_and_cell_type
         existing = true
         break
       end
     end
     unless existing
       self.tissue_and_cell_types << tissue_and_cell_type
     end
   end


  end
end
