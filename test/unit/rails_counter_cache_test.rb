require 'test_helper'
class EventInvitationsTest < ActiveSupport::TestCase
  def setup
    @site = Site.create
    @user = User.new
    @site.users << @user
  end
  test "test buildin rails counter cache" do
    @user.photos << Photo.new
    @user.reload
    assert_equal 1, @user.photos_count
    @user.photos.last.destroy
    @user.reload
    assert_equal 0, @user.photos_count
  end
end