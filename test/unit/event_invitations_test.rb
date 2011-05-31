require 'test_helper'
#require 'fixtures/sample_mail'

class EventInvitationsTest < ActiveSupport::TestCase
  def setup
    @event = Event.create
    @invitation = Invitation.new
  end
  
  test "reverse reflections" do
    assert_equal(:event, Event.reflections[:invitees].reverseme.name)
    assert_equal(:invitees, Invitation.reflections[:event].reverseme.name)
    
    assert_equal(:events, Event.reflections[:user].reverseme.name)
    assert_equal(:user, User.reflections[:events].reverseme.name)
  end
  
  test "presence of counters accessors" do
    @event.invitees.pending
    @event.invitees.accepted
    @event.invitees.rejected
    assert @event.invitees.respond_to?(:pending)
    assert @event.invitees.respond_to?(:accepted)
    assert @event.invitees.respond_to?(:rejected)
  end
  test "event invitations counter increase on create,  and decrease on delete invitation" do
    assert_equal(0, @event.invitees.pending.to_s.count)
    assert_equal(@event, @event.invitees.owner)
    @event.invitees << @invitation
    assert_equal(1, @event.invitees.pending.count)
  end
  test "event invitations counter decrease/increase on update" do
    @event.invitees << @invitation
    @invitation.reload
    @invitation.update_attribute(:estat, Invitation::STATUS[:accepted])
    assert_equal([:pending, :accepted], Counter.all.map{|c| c.name.to_sym })
    assert_equal(0, @event.invitees.pending.count(:force => true))
    assert_equal(1, @event.invitees.accepted.count(:force => true))
    assert_equal(:accepted, @invitation.status.current.name)
  end
  test "event invitations counter decrease on destroy" do
    @event.invitees << @invitation
    @invitation.reload
    @invitation.destroy
    assert_equal(0, @event.invitees.pending.count(:force => true))
  end
end