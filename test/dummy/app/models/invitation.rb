class Invitation < ActiveRecord::Base
  STATUS = {
    :pending => 0,
    :maybe => 1,
    :accepted => 2,
    :rejected => 3
  }
  belongs_to :event, :counter_cache => {:default => {:new => :pending}}.merge(STATUS)
  belongs_to :user
  after_create   :update_status_counter_on_create
  after_update   :update_status_counter_on_change
  before_destroy :update_status_counter_on_destroy
  
  def update_status_counter_on_create
    status.current.counter.increase
  end
  
  def update_status_counter_on_change
    if status.changed?
      status.before.counter.decrease
      status.after.counter.increase
    end
  end
  
  def update_status_counter_on_destroy
    status.current.counter.decrease
  end
  
  
end