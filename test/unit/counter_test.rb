require 'test_helper'
#require 'fixtures/sample_mail'

class CounterTest < ActiveSupport::TestCase
  def setup
    @event = Event.create
    
  end
  def new_counter(source, counter_name, *options)
    options = options.first.blank? ? {} : options.first
    counter_options = {:source => source, :name => counter_name}.merge(options)
    Counter.generate(counter_options)
    
    
    
  end
  def new_event_invitation_counter(event)
    new_counter(event, :pending, :source_relation => :invitees)
  end
  test "acts_as_counter method presence" do
    assert Event.public_methods.include?('acts_as_activity_counter')
    assert Event.private_methods.include?("add_counter_cache_callbacks")
  end
  test "counter uniqueness" do
    assert  new_event_invitation_counter(@event).save
    assert !new_event_invitation_counter(@event).save
  end
  
  test "have all attributes set" do
    error = assert_raise(RuntimeError) { counter = new_counter(@event, nil, :source_relation => :invitees) }
    assert_equal error.message, "missing parameter name at Class.generate method"
  end
  
  test 'increase/decrease counter by 1' do
    counter = new_event_invitation_counter(@event)
    counter.save
    assert_equal 0, counter.count
    
    counter.not_reloaded!
    counter.increase
    assert_equal 1, counter.count
    
    counter.increase
    assert_equal 2, counter.count
    
    counter.decrease
    assert_equal 1, counter.count
    
    counter.decrease
    assert_equal 0, counter.count
  end
  
  test "counters are destroyed before source item" do
    site = Site.create
    site.users << User.new
    assert_equal 1, site.users.total.count
    
    user = site.users.first
    user.videos << Video.new
    assert_equal 1, user.videos.total.count
    
    assert_equal 5, Counter.count
    user.destroy
    assert_equal 4, Counter.count
  end
end