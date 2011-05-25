require 'test_helper'

class ActivityCounterTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, ActivityCounter
    assert_kind_of Class, Counter
  end
end
