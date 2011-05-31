class User < ActiveRecord::Base
  STATUSES = {
    :unactive => 0,
    :active => 1,
    :disabled => 2
  }
  has_many :events
  has_many :invitations, :dependent => :destroy
  belongs_to :site, :counter_cache => {:default => [:total]}.merge(STATUSES)
end