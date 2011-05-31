module ActivityCounter
  module Model
    module Cached
      module ClassMethods

        def define_class_accessor(name, default=nil)
          unless respond_to?(name)
            class_eval <<-MAGIC
              @@#{name} = #{default.inspect}
              def self.#{name}=(name)
                @@#{name} = name
              end
              def self.#{name}
                @@#{name}
              end
            MAGIC
          end
        end
        
        ## Add status_update methods and trigger them to their events
        def configure_cached_class(reflection)
          status_column_name= reflection.status_column_name
          reflection_name= reflection.name

          send(:include, InstanceMethods)
          reflection.load_default_counters
          define_status_counters if reflection.has_status_counter?
          #define_default_counters
        end
        
        alias_method :original_method_missing, :method_missing
        def method_missing(name, *args)
          default_methods = { :status_column_name => :status, :reflection_name => nil }
          if default_methods.keys.include?(name)
            define_class_accessor(name, default_methods[name])
            send name
          else
            original_method_missing(name, args)
          end
        end

        private
        def define_status_counters
          # Custom status based counters
          after_create   :update_status_counter_on_create
          after_update   :update_status_counter_on_change
          before_destroy :update_status_counter_on_destroy
        end
        def define_default_counters(counters)
          counters.each do |counter|
            case counter
              when :total then define_total_counter
              when :new_default then define_new_default
              when :new_simple  then define_new_simple
            end
          end
        end
        def define_total_counter
          # Default counters
          after_create   {|item| item.total.increase}
          before_destroy {|item| item.total.decrease}
        end
        def define_new_default
          send :include, DefaultCounters
          after_create {|item| item.counter_new.increase }
          after_update :decrease_new_on_updated_at_distinct_of_created_at
        end
        def define_new_simple
          after_create {|item| item.counter_new.increase }
        end
      end
      module DefaultCounters
        def decrease_new_on_updated_at_distinct_of_created_at
          if changes[:updated_at].first == created_at
            counter_new.decrease
          end
        end
      end
        
      module InstanceMethods
        def status_column_name
          @status_column_name ||= status.status_field
        end
        def reflection_name
          # at this moment only one is expected, is ready to accept more
          @reflection_name ||= find_status_reflections.first.name
        end
        def status
          @status ||= Status.new(self, reflection_name)
          @status = @status.send(:call, self)
          @status
        end
        def after_create_update_default_counter
          if self[status_column_name].nil? && !status.default.nil?
            self[status_column_name] = status.default
            status.should_not_update!
            save
          end
        end
        def update_status_counter_on_create
          after_create_update_default_counter
          self.status.current.increase
        end
        def update_status_counter_on_change
          status.should_update? do
            if status.changed?
              status.before.decrease
              status.after.increase
            end
          end
        end
        def update_status_counter_on_destroy
          status.current.decrease
        end

        def method_missing(name, *args)
          if name == self.class.status_column_name
            eval <<-MAGIC
              def #{name}
                status
              end
            MAGIC
            send name
          else
            super
          end
        end
        
        private
        def find_status_reflections
          @status_reflections ||= []
          @status_reflections.empty? and self.class.reflections.each_pair{ |name,reflection|
            reflection.has_status_counter? and @status_reflections << reflection }
          @status_reflections
        end
        # It represents the "status" column for the current instance
        # .status => this name might change
        #   .list                 => known statuses list
        #   .to_s                 => record column value
        #   .default              => default status value
        #   .changed?             => has the status field changed?
        #   .current              => current status name
        #   .before               => before update status name
        #   .after                => after update status name
        #   .cached_class_name    => class name of the class containing status (Invitation in this case)
        #   .cached_relation_name => belongs_to relation name
        #   .changes              => changes on the status column
        class Status
          attr_reader :record, :reflection

          def initialize(record, reflection_name)
            @counter = {}
            @record = record
            @reflection = reflection_for(reflection_name)
            @owner = @record.send(@reflection.name)
            @statuses = @reflection.options[:counter_cache].reject{|status,value| status == :default }
            @should_update = true
          end
          def status_field
            @status_field ||= reflection_for(record.reflection_name).status_column_name
          end
          def list
            @statuses
          end
          def to_s
            record[status_field]
          end
          def default
            @default ||= read_default_status
          end
          def changed?
            !changes.nil?
          end
          def current
            counter
          end
          def after
            changed? and counter_by_value(changes.last)
          end
          def before
            changed? and counter_by_value(changes.first)
          end
          def cached_class_name
            (reflection.options[:class_name] or reflection.name.classify)
          end
          def cached_relation_name
            reflection.active_record.to_s
          end
          def changes
            record.changes[status_field] or nil
          end
          def should_not_update!
            @should_update = false
          end
          def should_update?(&block)
            if block_given?
              if !should_update?
                @should_update = true
              else
                yield
              end
            else
              @should_update
            end
          end
          private
          def call(record)
            @record = record
            self
          end
          def read_default_status
            default = @reflection.options[:counter_cache][:default]
            default_status = if default
              case
              when default.is_a?(Array) then
                default.reject!{|item| !item.is_a?(Hash) || !item[:new]}
                (!default.blank? and default.first[:new]) or nil
              when default.is_a?(Hash) then
                (default[:new] or nil)
              end
            end
            (default_status and list[default_status]) or nil
          end
          def status_name_for(value)
            @statuses_invert ||= list.invert
            @statuses_invert[value]
          end
          def counter_by_value(value)
            counter(status_name_for(value))
          end
          def counter(name=nil)
            name = status_name_for(self.to_s) unless name
            @counter[name] ||= ::Counter.create_or_retrieve(:source => @owner, :auto => @reflection, :name => name)
          end
          def reflection_for(name)
            reflection = record.class.reflections[name]
            (reflection.nil? and raise "Reflection #{name} not found for #{record.class.to_s} Class") or reflection
          end
        end
        
      end
    end
  end
end