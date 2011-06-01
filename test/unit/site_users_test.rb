require 'test_helper'
#require 'fixtures/sample_mail'

class EventInvitationsTest < ActiveSupport::TestCase
  def setup
    @site = Site.create
    @user = User.new
  end
  test "total users counter" do
    assert User.reflections[:site].has_default_counters?
    assert_equal(0, @site.users.total.count)
    1.upto(3){@site.users << User.new}
    
    @site.reload
    assert_equal(3, @site.users.count)
    assert_equal(3, Counter.last.count)
    
    assert_equal(3, @site.users.total.count(:force => true))
    
    1.upto(2){ @site.users.last.destroy }
    @site.reload
    assert_equal(1, @site.users.total.count)
  end
end