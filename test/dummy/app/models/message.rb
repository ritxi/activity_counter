class Message < ActiveRecord::Base
  STATUSES = {
    :unread => 1,
    :read => 2
  }
  has_many :events
  has_many :invitations, :dependent => :destroy
  belongs_to :user, :counter_cache => {:default => [:simple, {:new => :unread}]}.merge(STATUSES)
  
  def read!
    update_attribute(:status, STATUSES[:active])
  end
end