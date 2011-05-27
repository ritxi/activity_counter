module ActivityCounter
  module Model
    module Cached
      module ClassMethods
        
        ## Add status_update methods and trigger them to their events
        def configure_cached_class
          self.instance_eval <<-HELLO
            def update_status_counter_on_create
              status.current.counter.increase
            end

            def update_status_counter_on_change
              if status.changed?
                status.old.counter.decrease
                status.new.counter.increase
              end
            end

            def update_status_counter_on_destroy
              status.current.counter.decrease
            end
          HELLO
          
          after_create   :update_status_counter_on_create
          after_update   :update_status_counter_on_change
          before_destroy :update_status_counter_on_destroy
          
        end
      end
    end
  end
end