module ActivityCounter
  module Model
    module Counter
      module ClassMethods
        def validate_counter
          send :validates_uniqueness_of, :name, :scope => [:source_class, :source_id, :source_relation], :on => :create
          send :validates_presence_of, :source_class, :source_id, :source_relation, :name
        end
        
        def create_or_retrieve(*options)
          options = cleanup_params(options.first)
          counter = self.where(options).first
          if counter.blank?
            generate!(options)
          else
            counter
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
            options[:source_relation] = options.delete(:reverse).reverseme.first
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
            puts ""
            puts "missing: #{missing.inspect}"
            puts "options: #{options.inspect}"
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
          options
        end
        def generate!(*options)
          counter = generate(options.first)
          counter.save
          counter
        end
        private
        def keep_missing(given_options)
          [:source_id, :source_class, :source_relation, :name].reject{|option| given_options.include?(option)}
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
          unless options.keys.include?(option)
            #puts "option:  #{option.inspect}"
            #puts "options: #{options.inspect}"
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
        def cached_items
          source.send(source_relation)
        end
        def increase
          self.class.increment_counter(:count, self[:id])
          counter_changed!
        end
        def decrease
          self.class.decrement_counter(:count, self[:id])
          counter_changed!
        end
        def count
          if counter_changed?
            counter_unchanged!
            self.reload
          end
          self[:count]
        end
      end
    end
  end
end