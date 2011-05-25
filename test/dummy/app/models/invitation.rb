class Invitation < ActiveRecord::Base
  STATUS = {
    :pending => 0,
    :maybe => 1,
    :accepted => 2,
    :rejected => 3
  }
  belongs_to :event
  belongs_to :user, :counter_cache => STATUS
end