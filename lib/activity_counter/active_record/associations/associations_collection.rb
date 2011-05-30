require 'active_record/associations/association_collection'
module ActiveRecord
  module Associations
    class AssociationCollection < AssociationProxy
      attr_reader :counter_cache_options_without_default, :default_counters
      def owner
        @owner
      end
      
      
      alias_method :activity_count_initialize, :initialize
      def initialize(owner, reflection)
        activity_count_initialize(owner, reflection)
        @counter_cache_options = reflection.reverseme.options[:counter_cache]
        @counter_cache_options_without_default = @counter_cache_options.reject{ |key,value| key == :default }
        @internal_counter = InternalCounter.new(@owner, @reflection, self)
        @defaults = @counter_cache_options[:default]
        @default_counters = []
        if @defaults == true
          @default_counters = [:total, :new_default]
        elsif @defaults.is_a?(Array)
          @defaults.each do |default|
            case default
            when :total then @default_counters << :total
            when :new then @default_counters << :new_default
            when :new_default then @default_counters << :new_default
            when :new_simple then @default_counters << :new_simple
            end
          end
        end
        define_default_counters(@default_counters)
      end
      alias_method :rails_method_missing, :method_missing
      def method_missing(method, *args)
        if @counter_cache_options.reject{ |key,value| key == :default }.keys.include?(method.to_sym)
          counter_name = method
          eval <<-MAGIC
            def #{counter_name.to_s}
              @internal_counter.send(:call, #{counter_name.inspect})
            end
          MAGIC
          send(counter_name)
        else
          rails_method_missing(method, args.first)
        end
      end
      private

      class InternalCounter
        def initialize(owner, reflection, collection)
          @counter       ||= {}
          @owner         = owner
          @reflection    = reflection
          @collection    = collection
          @status_column = @reflection.status_column_name
          # statuses hash list
          @counter_caches = collection.counter_cache_options_without_default
        end
        def to_s
          @collection.where( @status_column => @counter_caches[@current_counter] )
        end
        def count(options={})
          options = {:force => false}.merge(options)
          options[:force] ? self.to_s.count : counter.count
        end
        private
        def call(counter_name)
          @current_counter = counter_name
          self
        end
        def counter
          @counter[@current_counter] ||= Counter.create_or_retrieve(:source => @owner, :auto => @reflection, :name => @current_counter)
        end
      end
    end
  end
end