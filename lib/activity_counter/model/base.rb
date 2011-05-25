module ActivityCounter
  module Model
    module Base
      module ClassMethods
        def validate_counter
          send :validates_uniqueness_of, :name, :scope => [:source_class, :source_id, :cached_class], :on => :create
          send :validates_presence_of, :source_class, :source_id, :cached_class, :name
          send :validates_presence_of, :cached_relation, :if => :pluralized_class_is_relation_name
        end
        def generate(*options)
          options = options.first
          [:source, :cached_class, :name].each do |option|
            unless options.keys.include?(option)
              raise "missing parameter #{option} at #{self.class.to_s}.generate method"
            end
          end
          source = options.delete(:source)
          new_counter_options = {:source_class => source.class.to_s, :source_id => source[:id]}.merge(options)
          self.new(new_counter_options)
        end
        def generate!(*options)
          counter = generate(options.first)
          counter.save
          counter
        end
      end
      module InstanceMethods
        def pluralized_class_is_relation_name
          unless source_class.blank?
            puts "source_class: #{source_class}"
            has_relation = eval(source_class).reflections.keys.include?(cached_relation)
            if self[:cached_relation].blank? && !has_relation
              errors[:cached_relation] << "No relation found named #{cached_relation} for #{self[:cached_class]}"
            end
          end
        end
        
        # If not specified is the class table name
        def cached_relation
          self[:cached_relation].blank? ? source_class.tableize : self[:cached_relation]
        end
        def source
          eval("#{source_class}.find(#{source_id})")
        end
        def increase
          update_attribute(:count, self[:count]+1)
        end
        def decrease
          self[:count] > 0 and update_attribute(:count, self[:count]-1)
        end
        def cached_items
          # Not working with relations having custom names yet!!!
          cached_class.tableize
          source.send(cached_class.tableize)
        end
      end
    end
  end
end