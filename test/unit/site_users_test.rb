require 'test_helper'
#require 'fixtures/sample_mail'

class EventInvitationsTest < ActiveSupport::TestCase
  def setup
    @site = Site.create
    @user = User.new
  end
  test "total users counter" do
    1.upto(10) do
      @site.users << User.new
    end
    assert_equal(10, @site.users.total.count(:force => true))
    1.upto(5) do
      @site.users.last.destroy
    end
    @site.reload
    assert_equal(5, @site.users.total.count(:force => true))
  end
end