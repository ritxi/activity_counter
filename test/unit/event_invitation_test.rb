require 'test_helper'
#require 'fixtures/sample_mail'

class EventInvitationTest < ActiveSupport::TestCase
  def setup
    @event = Event.new
  end
  
  test "reverse reflections" do
    assert_equal(:event, Event.reflections[:invitees].reverseme.first)
    assert_equal(:invitees, Invitation.reflections[:event].reverseme.first)
    
    assert_equal(:events, Event.reflections[:user].reverseme.first)
    assert_equal(:user, User.reflections[:events].reverseme.first)
  end
  
  #test "presence of counters accessors" do
  #  @event.invitees
  #  assert @event.invitees.respond_to?(:pending)
  #  assert @event.invitees.respond_to?(:accepted)
  #  assert @event.invitees.respond_to?(:rejected)
  #end
  #test "event invitations counter increase on create" do
  #  assert_equal(0, @event.invitees.pending.count)
  #  @event.invitees << Invitation.new
  #  assert_equal(1, @event.invitees.pending.count)
  #end
  #test "event invitations counter increase/decrease on update" do
  #  @event.invitees << Invitation.new
  #  assert_equal(1, @event.invitees.pending.count)
  #  
  #  assert_equal(0, @event.invitees.accepted.count)
  #  @event.invitees.last.update_attribute(:status, Invitation::STATUS[:accepted])
  #  assert_equal(0, @event.invitees.pending.count)
  #  assert_equal(1, @event.invitees.accepted.count)
  #end
  
  #test "event invitations counter decrease on destroy" do
  #  @event.invitees << Invitation.new
  #  assert_equal(1, @event.invitees.pending.count)
  #  
  #  @event.invitees.last.destroy
  #  assert_equal(0, @event.invitees.pending.count)
  #end
end