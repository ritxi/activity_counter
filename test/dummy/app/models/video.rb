class Video < ActiveRecord::Base
  belongs_to :user, :counter_cache => {:default => [:all]}
end