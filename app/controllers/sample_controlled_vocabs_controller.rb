class SampleControlledVocabsController < ApplicationController
  respond_to :html, :json, :js

  include Seek::IndexPager
  include Seek::AssetsCommon

  before_filter :samples_enabled?
  before_filter :login_required, except: [:show, :index]
  before_filter :find_and_authorize_requested_item, except: [:index, :new, :create]
  before_filter :find_assets, only: :index
  before_filter :auth_to_create, only: [:new, :create]

  def show
    respond_with(@sample_controlled_vocab)
  end

  def new
    @sample_controlled_vocab = SampleControlledVocab.new
    @sample_controlled_vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new
    respond_with(@sample_controlled_vocab)
  end

  def edit
    respond_with(@sample_controlled_vocab)
  end

  def create
    @sample_controlled_vocab = SampleControlledVocab.new(cv_params)

    flash[:notice] = 'The sample controlled vocabulary was successfully created.' if @sample_controlled_vocab.save
    respond_with(@sample_controlled_vocab) do |format|
      format.js { render layout: false, content_type: 'text/javascript' }
    end
  end

  def update
    @sample_controlled_vocab.update_attributes(cv_params)
    respond_with(@sample_controlled_vocab)
  end

  private

  def cv_params
    params.require(:sample_controlled_vocab).permit(:title, :description,
                                                    { sample_controlled_vocab_terms_attributes: [:id, :_destroy, :label] })
  end

end
