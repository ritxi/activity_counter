require 'active_record/reflection'
module ActiveRecord
  # = Active Record Reflection
  module Reflection
    class MacroReflection
      attr_reader :default_counters
      # Gets the belongs_to relation on the has_many side
      def reverseme
        @reverseme ||= if reverse_class.instance_methods.include?(reverse_reflection_name.to_s)
          reverse_reflection_by_class.last
        else
          reverse_reflection_by_custom_name.last
        end
      end
      def status_column_name
        (belongs_to? and (options[:status_field] or :status).to_sym) or reverseme.status_column_name
      end
      def load_default_counters
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
      end
      def has_default_counters?
        belongs_to? and options[:counter_cache] and options[:counter_cache].is_a?(Hash) and options[:counter_cache][:default]
      end
      def has_status_counter?
        (belongs_to? and options[:counter_cache] and options[:counter_cache].reject{|k,v| k == :default }.keys.count > 1)
      end
      private
      def reverse_class
        klass
      end
      def reverse_class_name
        reverse_class.to_s.underscore.to_sym
      end

      def reverse_reflection_name(reversed_name = nil)
        reversed_name ||= source_class_name
        macro == :has_many ? reversed_name.underscore.to_sym : reversed_name.tableize.to_sym
      end
      def source_class_name
        active_record.to_s
      end
      
      # reverse reflection discover methods
      def reverse_reflection_by_class
        reverse_reflection = reverse_class.reflections[reverse_reflection_name]
        [reverse_reflection_name, reverse_reflection]
      end
      def reverse_reflection_by_custom_name
        reversed_reflection = reverse_class.reflections.reject{ |name, reverse_reflection|
          reverse_reflection_class_name = reverse_reflection_name(source_class_name.underscore).to_s
          
          same_class_name = (name.to_s == reverse_reflection_class_name)
          diferent_name = (reverse_reflection.options[:class_name] && reverse_reflection.options[:class_name].to_s == source_class_name)
          
          !(same_class_name or diferent_name)
        }
        case
        when reversed_reflection.count == 0 then
          raise("No reverse reflections found for #{source_class_name}.#{name}")
        when reversed_reflection.count > 1 then
          raise("Too many(#{reverse.count}) reverse reflections found for #{source_class_name}.#{name}:\n#{reverse.inspect}")
        else
          Array(reversed_reflection).first # [:reflection_name, reflection]
        end
      end
    end
  end
end