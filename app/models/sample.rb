require 'grouped_pagination'
require 'acts_as_authorized'

class Sample < ActiveRecord::Base
  belongs_to :specimen
  belongs_to :institution
  has_and_belongs_to_many :assays

  has_many :assets_creators, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
  has_many :creators, :class_name => "Person", :through => :assets_creators, :order=>'assets_creators.id'

  alias_attribute :description, :comments
  validates_presence_of :title
  validates_uniqueness_of :title
  validates_presence_of :specimen,:lab_internal_number
  validates_presence_of :donation_date


  has_and_belongs_to_many :tissue_and_cell_types

  def self.sop_sql()
  'SELECT sop_versions.* FROM sop_versions ' +
  'INNER JOIN sample_sops ' +
  'ON sample_sops.sop_id = sop_versions.sop_id ' +
  'WHERE (sample_sops.sop_version = sop_versions.version ' +
  'AND sample_sops.sample_id = #{self.id})'
  end

  has_many :sops, :class_name => "Sop::Version", :finder_sql => self.sop_sql()
  has_many :sample_sops
  has_many :sop_masters,:through => :sample_sops
  grouped_pagination :pages=>("A".."Z").to_a, :default_page => Seek::Config.default_page(self.name.underscore.pluralize)

  acts_as_solr(:fields=>[:description,:title,:lab_internal_number],:include=>[:specimen,:assays]) if Seek::Config.solr_enabled

  acts_as_authorized


  def can_delete? *args
    assays.empty? && mixin_super(*args)
  end

  def self.user_creatable?
    true
  end

  def associate_tissue_and_cell_type tissue_and_cell_type_id,tissue_and_cell_type_title
       tissue_and_cell_type=nil
    if !tissue_and_cell_type_title.blank?
      if ( tissue_and_cell_type_id =="0" )
          found = TissueAndCellType.find(:first,:conditions => {:title => tissue_and_cell_type_title})
          unless found
          tissue_and_cell_type = TissueAndCellType.create!(:title=> tissue_and_cell_type_title)
          end
      else
          tissue_and_cell_type = TissueAndCellType.find_by_id(tissue_and_cell_type_id)
      end

      if tissue_and_cell_type
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

  def associate_sop sop

    sample_sop = sample_sops.select{|ss|ss.sop==sop}.first

    if sample_sop.nil?
      sample_sop = SampleSop.new
      sample_sop.sample = self
    end
    sample_sop.sop = sop
    sample_sop.sop_version = sop.version
    sample_sop.save if sample_sop.changed?

    return sample_sop
  end
end
