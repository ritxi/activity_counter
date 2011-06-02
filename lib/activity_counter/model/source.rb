module ActivityCounter
  module Model
    module Source
      module ClassMethods
        def configure_source_model
          before_destroy :remove_counters
        end
      end
      module InstanceMethods
        def remove_counters
          counters = ::Counter.where(:source_class => self.class.name, :source_id => self[:id])
          counters.destroy_all unless counters.blank?
        end
      end
    end
  end
end