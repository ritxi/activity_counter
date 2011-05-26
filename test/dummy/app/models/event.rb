class Event < ActiveRecord::Base
  belongs_to :user, :counter_cache => {:defaults => true}
  has_many :invitees, :foreign_key => 'event_id', :class_name => 'Invitation', :dependent => :destroy
  #counter_cache_for :invitiations, :when_is => [:total, :new, :accepted, :rejected, :maybe]
  #cache_for :invitiations do |observe|
  #  observe.when(:total) do |action|
  #    # Default behaviour
  #    # action.increase(:on => :create)
  #    # action.decrease(:on => :destroy)
  #  end
  #  observe.when(:new) do |action|
  #    # Default behaviour
  #    # action.increase(:on => :create)
  #    # action.decrease(:from_pending?)
  #  end
  #  observe.when(:accepted) do |action|
  #    # Default behaviour
  #    # action.increase(:to_accepted?)
  #    # action.decrease(:form_accepted?)
  #  end
  #end
  #cache_for :invitiations do |observe|
  #  observe.when(:total, :new, :accepted, :pending)
  #  observe.when(:new) do |action|
  #    # Default
  #    # action.increase(:on => :create)
  #    action.decrease(:from_pending?)
  #  end
  #end
  def invite(user)
    invitees << user
  end
end