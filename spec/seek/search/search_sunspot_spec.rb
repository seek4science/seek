require 'rails_helper'

#acts_as_asset
describe DataFile do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

  it { should have_searchable_field(:creators) }
  it { should have_searchable_field(:other_creators) }
  it { should have_searchable_field(:content_blob) }

  it { should have_searchable_field(:assay_type_titles) }
  it { should have_searchable_field(:technology_type_titles) }
  it { should have_searchable_field(:spreadsheet_annotation_search_fields) }
  it { should have_searchable_field(:fs_search_fields) }
 #it { should have_searchable_field(:spreadsheet_contents_for_search) }
end

describe Sop do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

  it { should have_searchable_field(:creators) }
  it { should have_searchable_field(:other_creators) }
  it { should have_searchable_field(:content_blob) }

  it { should have_searchable_field(:assay_type_titles) }
  it { should have_searchable_field(:technology_type_titles) }
  it { should have_searchable_field(:exp_conditions_search_fields) }
end

describe Model do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

  it { should have_searchable_field(:creators) }
  it { should have_searchable_field(:other_creators) }
  it { should have_searchable_field(:content_blob) }

  it { should have_searchable_field(:assay_type_titles) }
  it { should have_searchable_field(:technology_type_titles) }
  it { should have_searchable_field(:organism_terms) }
  it { should have_searchable_field(:model_contents_for_search) }
  it { should have_searchable_field(:model_format) }
  it { should have_searchable_field(:model_type) }
  it { should have_searchable_field(:recommended_environment) }
end

describe Presentation do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

  it { should have_searchable_field(:creators) }
  it { should have_searchable_field(:other_creators) }
  it { should have_searchable_field(:content_blob) }
end


describe Publication do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

  it { should have_searchable_field(:creators) }

  it { should have_searchable_field(:journal) }
  it { should have_searchable_field(:pubmed_id) }
  it { should have_searchable_field(:doi) }
  it { should have_searchable_field(:non_seek_authors) }
  it { should have_searchable_field(:publication_authors) }
#  it { should have_searchable_field(:published_date) }
#  it { should have_searchable_field(:organism_terms) }
end

describe Workflow do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

  it { should have_searchable_field(:creators) }
  it { should have_searchable_field(:other_creators) }
  it { should have_searchable_field(:content_blob) }

  it { should have_searchable_field(:category) }
end

#acts_as_isa
describe Assay do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

  it { should have_searchable_field(:organism_terms) }
  it { should have_searchable_field(:assay_type_label) }
  it { should have_searchable_field(:technology_type_label) }
  it { should have_searchable_field(:strains) }
end

describe Study do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

  it { should have_searchable_field(:experimentalists) }
  it { should have_searchable_field(:person_responsible) }
end

describe Investigation do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }
end

#acts_as_yellow_pages
describe Person do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  #it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

#  it { should have_searchable_field(:email) }
#  it { should have_searchable_field(:skype_name) }
#  it { should have_searchable_field(:web_page) }
#  it { should have_searchable_field(:orcid) }
  #this goes through institutions
  it { should have_searchable_field(:locations) }
  it { should have_searchable_field(:project_roles) }
  it { should have_searchable_field(:disciplines) }
  #all the assets contributed by the person
#  it { should have_searchable_field(:contributed_assets) }
end

describe Project do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  #it { should have_searchable_field(:contributor) }
  #it { should have_searchable_field(:projects) }

  it { should have_searchable_field(:locations) }
#  it { should have_searchable_field(:web_page) }
#  it { should have_searchable_field(:organism) }
#  it { should have_searchable_field(:institutions) }
#  it { should have_searchable_field(:programme) }
  #all the assets associated with the project
#  it { should have_searchable_field(:associated_assets) }
end

describe Institution do
  it { should have_searchable_field(:title) }
  #it { should have_searchable_field(:description) }
  #it { should have_searchable_field(:searchable_tags) }
  #it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

  it { should have_searchable_field(:locations) }
  it { should have_searchable_field(:city) }
  it { should have_searchable_field(:address) }
#  it { should have_searchable_field(:web_page) }
end

describe Programme do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  #it { should have_searchable_field(:searchable_tags) }
  #it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

#  it { should have_searchable_field(:people) }
  it { should have_searchable_field(:institutions) }
  it { should have_searchable_field(:funding_details) }
#  it { should have_searchable_field(:web_page) }
end

#biosamples
describe Strain do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

  it { should have_searchable_field(:provider_name) }
  it { should have_searchable_field(:provider_id) }
  it { should have_searchable_field(:genotype_info) }
  it { should have_searchable_field(:phenotype_info) }

#  it { should have_searchable_field(:specimens) }
#  it { should have_searchable_field(:organism_terms) }
  it { should have_searchable_field(:synonym) }
#  it { should have_searchable_field(:parent) }
#  it { should have_searchable_field(:children) }
end

describe Specimen do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

  it { should have_searchable_field(:creators) }
  it { should have_searchable_field(:other_creators) }

  it { should have_searchable_field(:provider_id) }
  it { should have_searchable_field(:provider_name) }
#  it { should have_searchable_field(:treatment) }
  it { should have_searchable_field(:genotype_info) }
  it { should have_searchable_field(:phenotype_info) }
  it { should have_searchable_field(:lab_internal_number) }
  it { should have_searchable_field(:institution) }

#  it { should have_searchable_field(:medium) }
#  it { should have_searchable_field(:culture_format) }
#  it { should have_searchable_field(:confluency) }
#  it { should have_searchable_field(:passage) }
#  it { should have_searchable_field(:viability) }
#  it { should have_searchable_field(:purity) }
#  it { should have_searchable_field(:ploidy) }
  it { should have_searchable_field(:culture_growth_type) }
#  it { should have_searchable_field(:age_unit) }
  it { should have_searchable_field(:strain) }
#  it { should have_searchable_field(:samples) }
end

describe Sample do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

  it { should have_searchable_field(:provider_name) }
  it { should have_searchable_field(:provider_id) }
#  it { should have_searchable_field(:treatment) }
  it { should have_searchable_field(:lab_internal_number) }
  it { should have_searchable_field(:institution) }

#  it { should have_searchable_field(:explantation) }
#  it { should have_searchable_field(:organism_part) }
#  it { should have_searchable_field(:sample_type) }

#  it { should have_searchable_field(:tissue_and_cell_types) }
  it { should have_searchable_field(:specimen) }
  it { should have_searchable_field(:strain) }
end

#others
describe Event do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

  it { should have_searchable_field(:address) }
  it { should have_searchable_field(:city) }
  it { should have_searchable_field(:country) }
  it { should have_searchable_field(:url) }
end
