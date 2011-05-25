module ActivityCounter
  class Engine < Rails::Engine
    initializer 'activity_counter.active_record' do
      require "activity_counter/model/base"
      require 'activity_counter/active_record/associations'
      require 'activity_counter/active_record/base'
      ::ActiveRecord::Base.send :extend, ::ActivityCounter::ActiveRecord::Base::ClassMethods
    end
  end
end