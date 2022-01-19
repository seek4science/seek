class SampleControlledVocabsController < ApplicationController
  respond_to :html, :json

  include Seek::IndexPager
  include Seek::AssetsCommon

  before_action :samples_enabled?
  before_action :login_required, except: %i[show index]
  before_action :is_user_admin_auth, only: %i[destroy update]
  before_action :find_and_authorize_requested_item, except: %i[index new create]
  before_action :find_assets, only: :index
  before_action :auth_to_create, only: %i[new create]

  api_actions :show, :create, :update, :destroy

  def show
    @sample_controlled_vocab = SampleControlledVocab.find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: @sample_controlled_vocab, include: [params[:include]] }
    end
  end

  def new
    @sample_controlled_vocab = SampleControlledVocab.new
    respond_with(@sample_controlled_vocab)
  end

  def edit
    respond_with(@sample_controlled_vocab)
  end

  def create
    @sample_controlled_vocab = SampleControlledVocab.new(cv_params)
    respond_to do |format|
      if @sample_controlled_vocab.save
        Rails.logger.info('Sample Controlled Vocab Saved')
        format.html do
          redirect_to @sample_controlled_vocab, notice: 'The sample controlled vocabulary was successfully created.'
        end
        format.json do
          render json: @sample_controlled_vocab, status: :created, location: @sample_controlled_vocab,
                 include: [params[:include]]
        end
        format.js { render layout: false, content_type: 'text/javascript' }
      else
        Rails.logger.info('Sample Controlled Vocab failed to save')
        format.html { render action: 'new' }
        format.json { render json: json_api_errors(@sample_controlled_vocab), status: :unprocessable_entity }
        format.js { render layout: false, content_type: 'text/javascript' }
      end
    end
  end

  def update
    @sample_controlled_vocab.update_attributes(cv_params)
    respond_to do |format|
      if @sample_controlled_vocab.save
        format.html do
          redirect_to @sample_controlled_vocab, notice: 'The sample controlled vocabulary was successfully updated.'
        end
        format.json { render json: @sample_controlled_vocab, include: [params[:include]] }
      else
        format.html { render action: 'edit', status: :unprocessable_entity }
        format.json { render json: json_api_errors(@sample_controlled_vocab), status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @sample_controlled_vocab.can_delete? && @sample_controlled_vocab.destroy
        format.html do
          redirect_to @sample_controlled_vocab, location: sample_controlled_vocabs_path,
                                                notice: 'The sample controlled vocabulary was successfully deleted.'
        end
        format.json { render json: @sample_controlled_vocab, include: [params[:include]] }
      else
        format.html do
          redirect_to @sample_controlled_vocab, location: sample_types_path,
                                                notice: 'It was not possible to delete the sample controlled vocabulary.'
        end
        format.json { render json: json_api_errors(@sample_controlled_vocab), status: :unprocessable_entity }
      end
    end
  end

  def fetch_ols_terms
    error_msg = nil
    begin
      source_ontology = params[:source_ontology_id]
      root_uri = params[:root_uri]

      raise 'No root URI provided' if root_uri.blank?

      client = Ebi::OlsClient.new
      terms = client.all_descendants(source_ontology, root_uri)
    rescue StandardError => e
      error_msg = e.message
    end

    respond_to do |format|
      if error_msg
        format.json { render json: { errors: [{ details: error_msg }] }, status: :unprocessable_entity }
      else
        format.json { render json: terms.to_json }
      end
    end
  end

  def typeahead
    scv = SampleControlledVocab.find(params[:scv_id])
    results = scv.sample_controlled_vocab_terms.where('LOWER(label) like :query',
                                                      query: "%#{params[:query].downcase}%").limit(params[:limit] || 100)
    items = results.map do |term|
      { id: term.label,
        name: term.label,
        iri: term.iri }
    end

    respond_to do |format|
      format.json { render json: items.to_json }
    end
  end

  private

  def cv_params
    params.require(:sample_controlled_vocab).permit(:title, :description, :group, :source_ontology, :ols_root_term_uri,
                                                    :required, :short_name,
                                                    { sample_controlled_vocab_terms_attributes: %i[id _destroy label
                                                                                                   iri parent_iri] })
  end
end
