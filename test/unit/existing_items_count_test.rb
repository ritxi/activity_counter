require 'test_helper'
#require 'fixtures/sample_mail'

class ExistingItemsCountTest < ActiveSupport::TestCase
  def setup
    @site = Site.create
    @user = User.new
    @site.users << @user
  end
  test "Ensure new counters count existing items" do
    10.times { @user.videos << Video.new }
    Counter.destroy_all
    assert_equal 10, @user.videos.count
    assert_equal 10, @user.videos.total.count
    assert_equal 10, Counter.first[:count]
  end
end