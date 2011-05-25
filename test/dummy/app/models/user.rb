class User < ActiveRecord::Base
  has_many :events
  has_many :invitations, :dependent => :destroy
  #counter_cache_for :invitiations, :when_is => [:total, :new]
  #  when_is(:new) do |action|
  #    action.increase(:create)
  #    action.decrease(:update, :not => :to_pending?)
  #  end
  #  when_is(:accepted) do |action|
  #    action.increase(:to_accepted?)
  #    action(:update).decrease(:not => :to_accepted?)
  #  end
  #  when_is(:rejected) do |action|
  #    action.increase(:update, :to_rejected?)
  #    action.decrease(:not => :to_rejected?)
  #  end
  #end
end