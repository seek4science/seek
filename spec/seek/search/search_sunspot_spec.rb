require 'rails_helper'
require 'factory_girl'
require_relative '../../../test/factories_helper.rb'
include FactoriesHelper

FactoryGirl.find_definitions

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

  it { should have_searchable_field(:data_type_annotations) }
  it { should have_searchable_field(:data_format_annotations) }

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
  it { should have_searchable_field(:human_disease_terms) }
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
#  it { should have_searchable_field(:human_disease_terms) }
end

#acts_as_isa
describe Assay do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

  it { should have_searchable_field(:organism_terms) }
  it { should have_searchable_field(:human_disease_terms) }
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
  it { should have_searchable_field(:expertise) }
  it { should have_searchable_field(:tools) }
  it { should have_searchable_field(:projects) }


  #this goes through institutions
  it { should have_searchable_field(:locations) }
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
#  it { should have_searchable_field(:human_disease) }
#  it { should have_searchable_field(:institutions) }
#  it { should have_searchable_field(:programme) }
  #all the assets associated with the project
#  it { should have_searchable_field(:associated_assets) }

  it { should have_searchable_field(:topic_annotations) }
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
#  it { should have_searchable_field(:human_disease_terms) }
  it { should have_searchable_field(:synonym) }
#  it { should have_searchable_field(:parent) }
#  it { should have_searchable_field(:children) }
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

describe Sample do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:searchable_tags) }
  it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

  it { should have_searchable_field(:creators) }
  it { should have_searchable_field(:other_creators) }

  it { should have_searchable_field(:assay_type_titles) }
  it { should have_searchable_field(:technology_type_titles) }

  it { should have_searchable_field(:sample_type) }
  it { should have_searchable_field(:attribute_values) }
end

describe SampleType do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:content_blob) }
  it { should have_searchable_field(:attribute_search_terms) }
end

describe Workflow do
  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }
  it { should have_searchable_field(:creators) }
  it { should have_searchable_field(:unregistered_creators) }
  it { should have_searchable_field(:content_blob) }
  it { should have_searchable_field(:git_content) }

  it { should have_searchable_field(:topic_annotations) }
  it { should have_searchable_field(:operation_annotations) }

end

