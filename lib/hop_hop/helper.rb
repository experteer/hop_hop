module HopHop
  module Helper
    def self.wait_unless(seconds, sleep_time = 0.5)
      tries = seconds / sleep_time
      while yield && tries > 0
        tries -= 1
        sleep sleep_time
        # STDOUT.write(".")
      end
    end

    def self.acronym_regex
      /(?=a)b/
    end

    def self.underscore(camel_cased_word)
      word = camel_cased_word.to_s.dup
      word.gsub!('::', '/')
      word.gsub!(/(?:([A-Za-z\d])|^)(#{acronym_regex})(?=\b|[^a-z])/) { "#{$1}#{$1 && '_'}#{$2.downcase}" }
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      # word.tr!("-", "_")
      word.downcase!
      word
    end

    def self.camelize(term, uppercase_first_letter = true)
      string = term.to_s
      if uppercase_first_letter
        string = string.sub(/^[a-z\d]*/) { $&.capitalize }
      else
        string = string.sub(/^(?:#{acronym_regex}(?=\b|[A-Z_])|\w)/) { $&.downcase }
      end
      string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub('/', '::')
    end

    def self.const_defined?(mod, const)
      if method(:const_defined?).arity == 1
        mod.const_defined?(const) # <= ruby 1.8.7
      else
        mod.const_defined?(const, false) # Ruby 1.9>
      end
    end

    # rubocop:disable LineLength, CyclomaticComplexity
    # pretty much the same code rails is using
    # https://github.com/rails/rails/tree/master/activesupport/lib/active_support/inflector/methods.rb#L226
    def self.constantize(camel_cased_word)
      names = camel_cased_word.split('::')
      names.shift if names.empty? || names.first.empty?

      names.inject(Object) do |constant, name|
        if constant == Object
          constant.const_get(name)
        else
          candidate = constant.const_get(name)
          next candidate if const_defined?(constant, name)
          next candidate unless Object.const_defined?(name)

          # Go down the ancestors to check it it's owned
          # directly before we reach Object or the end of ancestors.
          constant = constant.ancestors.inject do |const, ancestor|
            break const if ancestor == Object
            break ancestor if const_defined?(ancestor, name)
            const
          end

          # owner is in Object, so raise
          constant.const_get(name, false)
        end
      end
    end

    # rubocop:enable LineLength, CyclomaticComplexity

    # File activesupport/lib/active_support/core_ext/hash/slice.rb, line 15
    def self.slice_hash(hash, *keys)
      keys.map! { |key| hash.convert_key(key) } if respond_to?(:convert_key, true)
      keys.each_with_object(hash.class.new) { |k, agg| agg[k] = hash[k] if hash.key?(k) }
    end
  end # module Helper
end # module HopHop
