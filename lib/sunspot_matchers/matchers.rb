module SunspotMatchers
  class BaseMatcher
    attr_accessor :args

    def initialize(actual, args)
      @actual = actual
      @args = args
      build_comparison_search
    end

    def build_comparison_search
      @comparison_search = if(@args.last.is_a?(Proc))
        SunspotMatchers::SunspotSessionSpy.new(nil).build_search(search_types, &args.last)
      else
        SunspotMatchers::SunspotSessionSpy.new(nil).build_search(search_types) do
          send(search_method, *args)
        end
      end
    end

    def search_tuple
      search_tuple = @actual.is_a?(Array) ? @actual : @actual.searches.last
      raise 'no search found' unless search_tuple
      search_tuple
    end

    def actual_search
      search_tuple.last
    end

    def search_types
      search_tuple.first
    end

    def wildcard?
      @args && @args.last == any_param
    end

    def field
      @args && @args.first
    end

    def query_params_for_search(search)
      search.instance_variable_get(:@query).to_params
    end

    def actual_params
      @actual_params ||= query_params_for_search(actual_search)
    end

    def comparison_params
      @comparison_params ||= query_params_for_search(@comparison_search)
    end

    def match?
      differences.empty?
    end

    def missing_param_error_message
      missing_params = differences
      actual_values = missing_params.keys.collect {|key| "#{key} => #{actual_params[key]}"}
      missing_values = missing_params.collect{ |key, value| "#{key} => #{value}"}
      "expected search params: #{actual_values.join(' and ')} to match expected: #{missing_values.join(' and ')}"
    end

    def unexpected_match_error_message
      actual_values = keys_to_compare.collect {|key| "#{key} => #{actual_params[key]}"}
      comparison_values = keys_to_compare.collect {|key| "#{key} => #{comparison_params[key]}"}
      "expected search params: #{actual_values.join(' and ')} NOT to match expected: #{comparison_values.join(' and ')}"
    end

    def differences
      keys_to_compare.inject({}) do |hsh, key|
        result = compare_key(key)
        hsh[key] = result unless result.empty?
        hsh
      end
    end

    def compare_key(key)
      if(actual_params[key].is_a?(Array) || comparison_params[key].is_a?(Array))
        compare_multi_value(actual_params[key], comparison_params[key])
      else
        compare_single_value(actual_params[key], comparison_matcher_for_key(key))
      end
    end

    def comparison_matcher_for_key(key)
      if wildcard? && wildcard_matcher_for_keys.has_key?(key)
        wildcard_matcher_for_keys[key]
      else
        comparison_params[key]
      end
    end

    def compare_single_value(actual, comparison)
      if comparison.is_a?(Regexp)
        return [] if comparison =~ actual
        return [comparison.source]
      end
      return [comparison] unless actual == comparison
      []
    end

    def compare_multi_value(actual, comparison)
      filter_values(comparison).reject do |value|
        next false unless actual
        value_matcher = Regexp.new(Regexp.escape(value))
        cmp_value = actual.is_a?(String) ? actual.chars : actual
        cmp_value.any?{ |actual_value| actual_value =~ value_matcher }
      end
    end

    def filter_values(values)
      return values unless wildcard?
      field_matcher = Regexp.new(field.to_s)
      values.select{ |value| field_matcher =~ value }.collect{|value| value.gsub(/:.*/, '')}
    end

    def wildcard_matcher_for_keys
      {}
    end
  end

  class HaveSearchParams
    def initialize(method, *args, &block)
      @method = method
      @args = [*args, block].compact
    end

    def matches?(actual)
      @actual = actual
      @matcher = get_matcher.new(@actual, @args)
      @matcher.match?
    end

    def failure_message_for_should
      @matcher.missing_param_error_message
    end

    def failure_message_for_should_not
      @matcher.unexpected_match_error_message
    end

    def get_matcher
      case @method
        when :with
          WithMatcher
        when :without
          WithoutMatcher
        when :keywords, :fulltext
          KeywordsMatcher
        when :boost
          BoostMatcher
        when :facet
          FacetMatcher
        when :order_by
          OrderByMatcher
        when :paginate
          PaginationMatcher
        when :group
          GroupMatcher
      end
    end
  end

  def have_search_params(method, *args, &block)
    HaveSearchParams.new(method, *args, &block)
  end

  class WithMatcher < BaseMatcher
    def search_method
      :with
    end

    def keys_to_compare
      [:fq]
    end
  end

  class WithoutMatcher < BaseMatcher
    def search_method
      :without
    end

    def keys_to_compare
      [:fq]
    end
  end

  class KeywordsMatcher < BaseMatcher
    def search_method
      :keywords
    end

    def keys_to_compare
      [:q, :qf]
    end

    def wildcard_matcher_for_keys
      {:q => /./, :qf => /./}
    end
  end

  class BoostMatcher < BaseMatcher
    def search_method
      :boost
    end


    def keys_to_compare
      [:qf, :bq, :bf]
    end
  end

  class FacetMatcher < BaseMatcher
    def search_method
      :facet
    end

    def keys_to_compare
      comparison_params.keys.select {|key| /facet/ =~ key.to_s}
    end
  end

  class OrderByMatcher < BaseMatcher
    def search_method
      :order_by
    end

    def keys_to_compare
      [:sort]
    end

    def wildcard_matcher_for_keys
      return {:sort => /./} if field_wildcard?
      param = comparison_params[:sort]
      regex = Regexp.new(param.gsub(any_param, '.*'))
      {:sort => regex}
    end

    def field_wildcard?
      @args.first == any_param
    end

    def direction_wildcard?
      @args.length == 2 && @args.last == any_param
    end

    def args
      return @args unless direction_wildcard?
      @args[0...-1] + [:asc]
    end

    def build_comparison_search
      if field_wildcard?
        @comparison_params = {:sort => any_param}
      elsif direction_wildcard?
        super
        @comparison_params = comparison_params
        @comparison_params[:sort].gsub!("asc", any_param)
      else
        super
      end
    end
  end

  class PaginationMatcher < BaseMatcher
    def search_method
      :paginate
    end

    def keys_to_compare
      [:rows, :start]
    end
  end

  class GroupMatcher < BaseMatcher
    def search_method
      :group
    end

    def keys_to_compare
      comparison_params.keys.select {|key| /group/ =~ key.to_s}
    end
  end

  class BeASearchFor
    def initialize(expected_class)
      @expected_class = expected_class
    end

    def matches?(actual)
      @actual = actual
      search_types.include?(@expected_class)
    end

    def search_tuple
      search_tuple = @actual.is_a?(Array) ? @actual : @actual.searches.last
      raise 'no search found' unless search_tuple
      search_tuple
    end

    def search_types
      search_tuple.first
    end

    def failure_message_for_should
      "expected search class: #{search_types.join(' and ')} to match expected class: #{@expected_class}"
    end

    def failure_message_for_should_not
      "expected search class: #{search_types.join(' and ')} NOT to match expected class: #{@expected_class}"
    end
  end

  def be_a_search_for(expected_class)
    BeASearchFor.new(expected_class)
  end

  class HaveSearchableField

    def initialize(field)
      @field = field
    end

    def matches?(klass_or_object)
      @klass = klass_or_object.class.name == 'Class' ? klass_or_object : klass_or_object.class
      @sunspot = Sunspot::Setup.for(@klass)
      (@sunspot.all_text_fields + @sunspot.fields).collect(&:name).include?(@field)
    end

    def failure_message_for_should
      "expected class: #{@klass} to have searchable field: #{@field}"
    end

    def failure_message_for_should_not
      "expected class: #{@klass} NOT to have searchable field: #{@field}"
    end
  end

  def have_searchable_field(field)
    HaveSearchableField.new(field)
  end
end

def any_param
  "ANY_PARAM"
end