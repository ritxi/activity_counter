class User < ActiveRecord::Base
  has_many :events
  has_many :invitations, :dependent => :destroy
  belongs_to :site, :counter_cache => {:default => true}
end