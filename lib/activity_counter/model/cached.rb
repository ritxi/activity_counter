module ActivityCounter
  module Model
    module Cached
      module ClassMethods
        @@status_column_name = :status
        @@reflection_name = nil
        def reflection_name=(name)
          @@reflection_name = name
        end
        def reflection_name
          @@reflection_name
        end
        def status_column_name=(name)
          @@status_column_name = name
        end
        def status_column_name
          @@status_column_name
        end
        ## Add status_update methods and trigger them to their events
        def configure_cached_class(reflection)
          self.status_column_name= reflection.status_column_name
          self.reflection_name= reflection.name
          puts "#{self.to_s}: Configuring cached model"
          send(:include, InstanceMethods)
          
          
          after_create   :update_status_counter_on_create
          after_update   :update_status_counter_on_change
          before_destroy :update_status_counter_on_destroy
          before_create  :on_create_default_counter
          before_save    :on_create_default_counter
        end
      end
      module InstanceMethods
        def status_column_name
          self.class.status_column_name
        end
        def status
          @status ||= Status.new(self, self.class.reflection_name)
          @status.send(:call, self)
        end
        def on_create_default_counter
          #puts "status column name: #{status_column_name.inspect}"
          #puts "status nil?: #{self[status_column_name].nil?.inspect}"
          #puts "status method accessor found: #{respond_to? status_column_name}"
          if new_record? && self[status_column_name].nil?
            self[status_column_name] = send(status_column_name).default
            puts "Default status column value: #{self[status_column_name]}"
          end
        end
        def update_status_counter_on_create
          puts "update on create"
          send(status_column_name).current.counter.increase
        end
        def update_status_counter_on_change
          puts "update on update"
          if status.changed?
            send(status_column_name).before.counter.decrease
            send(status_column_name).after.counter.increase
          end
        end
        def update_status_counter_on_destroy
          puts "update on destroy"
          send(status_column_name).current.counter.decrease
        end
        def method_missing(name, *args)
          if name == self.class.status_column_name
            eval <<-MAGIC
              def #{name}
                puts "reflection: #{self.class.reflection_name}"
                puts "column: #{self.class.status_column_name}"
                status
              end
            MAGIC
            send name
          else
            super
          end
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
        #   .changes              => changes if any on the status column
        class Status
          attr_reader :record, :reflection, :name, :status_field

          def initialize(record, reflection_name)
            @counter = {}
            @record, @reflection = record, reflection_for(record, reflection_name)
            @statuses = @reflection.options[:counter_cache].reject{|status,value| status == :default }
            @status_field = @record.status_column_name

            
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
            counter_by_value(self)
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
          def counter(name)
            @counter[name] ||= ::Counter.create_or_retrieve(:source => @owner, :auto => @reflection, :name => name)
          end
          def reflection_for(record, name)
            record.class.reflections[name]
          end
        end
      end
    end
  end
end