require 'test_helper'

class OpenbisFakeJobTest < ActiveSupport::TestCase

  def setup
    @batch_size = 3
    @job = OpenbisFakeJob.new('fakish', @batch_size)
    Delayed::Job.destroy_all # avoids jobs created from the after_create callback, this is tested for OpenbisEndpoint
  end

  test 'setup' do
    assert @job
  end

  test 'rnd_assay gives an assay' do
    assay = Factory :assay
    refute assay.new_record?

    set = @job.rnd_assays.to_a
    assert set.length <= @batch_size
    refute set.empty?
    assert set.first.is_a? Assay

  end

  test 'rnd_asset gives a DataFile' do
    df = Factory :data_file
    refute df.new_record?

    set = @job.rnd_assets.to_a
    assert set.length <= @batch_size
    refute set.empty?
    assert set.first.is_a? DataFile

  end

  test 'assets_and_assets contains both' do
    assay = Factory :assay
    df = Factory :data_file
    set = @job.assets_and_assays

    assert set.is_a? Array
    refute set.select { |e| e.is_a? Assay}.empty?
    refute set.select { |e| e.is_a? DataFile}.empty?
  end

  test 'performs job on assay' do
    assay = Factory :assay
    mod = assay.updated_at

    @job.perform_job(assay)
    assay.reload
    assert_not_equal mod, assay.updated_at
  end

end