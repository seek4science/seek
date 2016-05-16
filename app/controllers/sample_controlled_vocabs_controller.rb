class SampleControlledVocabsController < ApplicationController
  respond_to :html

  include Seek::IndexPager

  def show
    @sample_controlled_vocab = SampleControlledVocab.find(params[:id])
    respond_with(@sample_controlled_vocab)
  end

  def new
    @sample_controlled_vocab = SampleControlledVocab.new
    respond_with(@sample_controlled_vocab)
  end

  def edit
    @sample_controlled_vocab = SampleControlledVocab.find(params[:id])
    respond_with(@sample_controlled_vocab)
  end

  def create
    @sample_controlled_vocab = SampleControlledVocab.new(params[:sample_controlled_vocab])

    flash[:notice] = 'The sample controlled vocabulary was successfully created.' if @sample_controlled_vocab.save
    respond_with(@sample_controlled_vocab)
  end

  def update
    @sample_controlled_vocab = SampleControlledVocab.find(params[:id])
    @sample_controlled_vocab.update_attributes(params[:sample_controlled_vocab])
    respond_with(@sample_controlled_vocab)
  end

end