module ActivityCounter
  module ActiveRecord
    module Base
      module ClassMethods
        def acts_as_activity_counter
          send :extend,  ActivityCounter::Model::Base::ClassMethods
          send :include, ActivityCounter::Model::Base::InstanceMethods
          validate_counter
        end
      end
    end
  end
end