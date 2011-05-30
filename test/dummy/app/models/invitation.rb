class Invitation < ActiveRecord::Base
  STATUS = {
    :pending => 0,
    :maybe => 1,
    :accepted => 2,
    :rejected => 3
  }
  belongs_to :event, :counter_cache => {:default => {:new => :pending}}.merge(STATUS), :status_field => :estat
  belongs_to :user
  
  
end