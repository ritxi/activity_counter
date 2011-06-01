require 'active_support/basic_object'
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
          define_status_counters(reflection) 
          define_default_counters(reflection) 
        end
        
        alias_method :original_method_missing, :method_missing
        def method_missing(name, *args)
          default_methods = { :status_column_name => :status, :reflection_name => nil }
          if default_methods.keys.include?(name)
            define_class_accessor(name, default_methods[name])
            send name
          else
            super
            #original_method_missing(name, args)
          end
        end

        private
        def define_status_counters(reflection)
          # Custom status based counters
          if reflection.has_status_counter?
            after_create   :update_status_counter_on_create
            after_update   :update_status_counter_on_change
            before_destroy :update_status_counter_on_destroy
          end
        end
        def define_default_counters(reflection)
          reflection.load_default_counters
          if reflection.has_default_counters?
            send :include, DefaultCounters
            reflection.default_counters.each do |counter|
              case counter
                when :total then define_total_counter(reflection)
                when :new then define_new(reflection)
                when :simple  then define_simple(reflection)
              end
            end
          end
        end
        def define_total_counter(reflection)
          # Default counters
          after_create   { |item| item.increase_on_create(reflection) }
          before_destroy { |item| item.collection_counter(reflection,:total).decrease }
        end
        def define_new(reflection)
          after_create { |item| item.increase_on_create(reflection, :new) }
          after_update { |item| item.decrease_new_on_update(reflection) }
          before_destroy { |item| item.decrease_new_on_destroy(reflection) }
        end
        def define_simple(reflection)
          after_create {|item| item.increase_on_create(reflection, :simple) }
        end
      end
      module DefaultCounters
        # types = *:new|:simple|:total
        def increase_on_create(reflection, type=:total)
          counter = collection_counter(reflection,type)
          counter.increase
        end
        def decrease_new_on_update(reflection)
          if changes[:updated_at] 
            (changes[:updated_at].first == created_at) and collection_counter(reflection,:new).decrease
          end
        end
        def decrease_new_on_destroy(reflection)
          self[:updated_at] == self[:created_at] and collection_counter(reflection,:new).decrease
        end
      end
        
      module InstanceMethods
        def collection_counter(reflection, counter_name)
          collection = send(reflection.name).send(reflection.reverseme.name)
          case counter_name
            when :total then collection.total.send(:counter)
            when :new then collection.new.send(:counter) # New default
            when :simple then collection.simple.send(:counter) # New simple
          end
        end
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
            reflection.has_status_counter? and @status_reflections << reflection
          }
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
        class Status < ActiveSupport::BasicObject
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

          def default
            @default ||= read_default_status
          end
          def changed?
            !changes.blank?
          end
          def current
            counter
          end
          def after
            if changed?
              counter = counter_by_value(changes.last)
              counter
            end
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

          def method_missing(method, *args, &block)
            record[status_field].send(method, *args, &block)
          end
          
          private
          def proxy(method, *args)
            record[status_field].send(method, *args)
          end
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
            name = @statuses_invert[value.to_i]
            name
          end
          def counter_by_value(value)
            counter(status_name_for(value))
          end
          def counter(name=nil)
            unless name
              name = status_name_for(self.to_s)
            end
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