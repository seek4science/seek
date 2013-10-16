class Sweep < ActiveRecord::Base

  has_many :runs, :class_name => 'TavernaPlayer::Run', :dependent => :destroy
  belongs_to :user
  belongs_to :workflow

  accepts_nested_attributes_for :runs

  before_destroy :cancel

  def cancel
    runs.each do |run|
      run.cancel unless run.finished?
    end
  end

end
