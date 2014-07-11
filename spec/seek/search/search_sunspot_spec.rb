require 'rails_helper'

describe DataFile do

    before(:context) { Seek::Config.solr_enabled = true }
    context 'when solr is enabled' do
      it { should have_searchable_field(:title) }
      it { should have_searchable_field(:description) }
    end

end
