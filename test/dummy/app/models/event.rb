class Event < ActiveRecord::Base
  belongs_to :user
  has_many :invitees, :foreign_key => 'event_id', :class_name => 'Invitation', :dependent => :destroy
  
  def invite(user)
    invitees << user
  end
end