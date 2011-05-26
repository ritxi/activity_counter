module ActivityCounter
  module ActiveRecord
    module Base
      module ClassMethods
        def acts_as_activity_counter
          send :extend,  ActivityCounter::Model::Counter::ClassMethods
          send :include, ActivityCounter::Model::Counter::InstanceMethods
          validate_counter
        end
      end
    end
  end
end