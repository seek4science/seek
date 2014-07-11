require 'rails_helper'

describe DataFile do
  before(:all) { Seek::Config.solr_enabled = true }

  it { should have_searchable_field(:title) }
  it { should have_searchable_field(:description) }
  it { should have_searchable_field(:searchable_tags) }
  it { should have_searchable_field(:contributor) }
  it { should have_searchable_field(:projects) }

  it { should have_searchable_field(:creators) }
  it { should have_searchable_field(:other_creators) }
  it { should have_searchable_field(:content_blob) }

  it { should have_searchable_field(:spreadsheet_annotation_search_fields) }
  it { should have_searchable_field(:fs_search_fields) }
  it { should have_searchable_field(:assay_type_titles) }
  it { should have_searchable_field(:technology_type_titles) }
  it { should have_searchable_field(:spreadsheet_contents_for_search) }
end

