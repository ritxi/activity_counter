class User < ActiveRecord::Base
  STATUSES = {
    :unactive => 0,
    :active => 1,
    :disabled => 2
  }
  has_many :events
  has_many :invitations, :dependent => :destroy
  has_many :messages
  belongs_to :site, :counter_cache => {:default => true}.merge(STATUSES)
  
  def activate!
    update_attribute(:status, STATUSES[:active])
  end
end