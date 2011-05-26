require 'test_helper'
#require 'fixtures/sample_mail'

class CounterTest < ActiveSupport::TestCase
  def setup
    @user = User.create
    @user2 = User.create
  end
  def new_counter(source, cached_class, counter_name, *options)
    options = options.first.blank? ? {} : options.first
    counter_options = {:source => source, :cached_class => cached_class, :name => counter_name}.merge(options)
    Counter.generate(counter_options)
  end
  def new_event_counter(user)
    new_counter(user, 'Event', 'total', :cached_relation => 'organizer')
  end
  test "acts_as_counter method presence" do
    assert User.public_methods.include?('acts_as_activity_counter')
    assert User.private_methods.include?("add_counter_cache_callbacks")
  end
  test "counter uniqueness" do
    assert new_event_counter(@user).save
    assert !new_event_counter(@user).save
  end
  
  test "have all attributes set" do
    counter = new_counter(@user, 'Event', nil, :cached_relation => 'organizer')
    assert(!counter.save)
    assert_equal(counter.errors.keys, [:name])
    counter.name = 'total'
    assert(counter.save)
  end
  
  test 'increase/decrease counter by 1' do
    counter = new_event_counter(@user)
    counter.save
    assert_equal(0, counter.count)
    counter.increase
    assert_equal(1, counter.count)
    counter.decrease
    assert_equal(0, counter.count)
    counter.decrease
    assert_equal(0, counter.count)
  end
end