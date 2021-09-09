class AssetsCreator < ApplicationRecord
  belongs_to :asset, polymorphic: true
  belongs_to :creator, class_name: 'Person', optional: true

  include Seek::Rdf::ReactToAssociatedChange
  include Seek::OrcidSupport
  update_rdf_on_change :asset

  default_scope { order(:pos) }

  def family_name
    creator ? creator.last_name : super
  end

  def given_name
    creator ? creator.first_name : super
  end

  def name
    creator ? creator.name : "#{given_name} #{family_name}"
  end

  def affiliation
    a = super
    return a unless a.nil?
    creator.institutions.map(&:title).join(', ') if creator
  end

  def orcid
    creator ? creator.orcid : super
  end

  def self.registered
    where.not(creator: nil)
  end

  def self.unregistered
    where(creator: nil)
  end

  def self.with_name(name)
    concat_clause = if Seek::Util.database_type == 'sqlite3'
                      "LOWER(assets_creators.given_name || ' ' || assets_creators.family_name)"
                    else
                      "LOWER(CONCAT(assets_creators.given_name, ' ', assets_creators.family_name))"
                    end

    AssetsCreator.where("#{concat_clause} LIKE :query OR LOWER(assets_creators.given_name) LIKE :query OR LOWER(assets_creators.family_name) LIKE :query",
                 query: "#{name.downcase}%")
  end
  
  def needs_orcid?
    false
  end
end
