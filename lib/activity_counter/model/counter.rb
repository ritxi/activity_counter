module ActivityCounter
  module Model
    module Counter
      module ClassMethods
        def validate_counter
          send :validates_uniqueness_of, :name, :scope => [:source_class, :source_id, :source_relation], :on => :create
          send :validates_presence_of, :source_class, :source_id, :source_relation, :name
        end
        
        def create_or_retrieve(*options)
          dirty_options = options.first
          options_cleaned = cleanup_params(dirty_options)
          counter = self.where(options_cleaned)
          if counter.empty?
            generate!(options_cleaned)
          else
            counter.first
          end
        end
        
        def generate(*options)
          self.new(cleanup_params(options.first))
        end
        
        def split_source(options)
          @source = options.delete(:source)
          @source ? { :source_class => @source.class.to_s, :source_id => @source[:id] }.merge(options) : options
        end
        
        def find_reflection_name(options)
          case
          when options[:reverse] then
            reverse = options.delete(:reverse).reverseme
            options[:source_relation] = reverse.name # reflection name
          when options[:auto] then
            auto = options.delete(:auto)
            raise "unsuported relation #{auto.macro}" unless [:belongs_to, :has_many].include?(auto.macro)
            (auto.macro == :belongs_to and options[:reverse] = auto) or options[:reflection] = auto
            options = find_reflection_name(options)
          when options[:reflection] then
            options[:source_relation] = options.delete(:reflection).name
          end
          options
        end
        def find_source(reflection)
          (reflection.macro == :belongs_to and reflection.active_record) or reflection.reverseme.active_record
        end
        
        ###=====================================================###
         # Parameters description                                #
        ###-----------------------------------------------------###
         # - :source => object that has many items               #
         # - :name => counter name                               #
        ###-----------------------------------------------------###
         # Only one of them can be passed                        #
         # - :reverse => belongs to side reflection              #
         # - :auto => it discovers the given reflection type     #
         # - :reflection => has many side reflection             #
         # - :source_relation => it's the has_many relation name #
        ###=====================================================###
        
        def cleanup_params(*options)
          options = options.first
          missing = keep_missing(options)
          
          unless missing.blank?
            [:source, [:reverse, :auto, :reflection, :source_relation], :name].each do |expected|
              if expected.is_a?(Array)
                validate_one_is_present(expected, options)
              else
                validate_option(options, expected)
              end
            end
            
            options = split_source(options)
            options = find_reflection_name(options)
          end
          #puts "Options cleaned: #{options.inspect}"
          options
        end
        def generate!(*options)
          params = cleanup_params(options.first)
          self.create(params)
        end
        private
        def keep_missing(given_options)
          [:source_id, :source_class, :source_relation, :name].reject{|option| given_options.keys.include?(option) && !given_options[option].nil? }
        end
        def validate_one_is_present(expected, given_options)
          found = expected.reject{|new_option| !given_options.keys.include?(new_option)}
          if found.empty?
            raise "Non of the following params found: #{expected.inspect}"
          elsif found.size > 1
            raise "Only one of the following can be present: #{found.inspect}"
          end
        end
        def validate_option(options, option)
          if !options.keys.include?(option) || options[option].nil?
            raise "missing parameter #{option} at #{self.class.to_s}.generate method"
          end
        end
      end
      module InstanceMethods
        def counter_changed?
          @counter_changed
        end
        def counter_changed!
          @counter_changed = true
        end
        def counter_unchanged!
          @counter_changed = false
        end
        def source
          eval("#{source_class}.find(#{source_id})")
        end
        def reset!
          update_attribute(:count, 0)
        end
        def reload!
          new_count = cached_items.send(name).count
          update_attribute(:count, new_count) unless new_count == self[:count]
        end
        def cached_items
          source.send(source_relation)
        end
        def increase
          #puts "up!"
          up = self.class.increment_counter(:count, self[:id])
          (up == 1 and counter_changed!) or puts "ep que no funciona"
        end
        def decrease
          #puts "down!"
          down = self.class.decrement_counter(:count, self[:id])
          (down == 1 and counter_changed!) or puts "ep que no funciona"
        end
        def count(options={})
          options = {:force => false}.merge(options)
          if counter_changed? || options[:force]
            counter_unchanged!
            self.reload
          end
          self[:count]
        end
      end
    end
  end
end