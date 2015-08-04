require 'sunspot'
require 'minitest/autorun'
require File.expand_path('../matchers', __FILE__)
require File.expand_path('../sunspot_session_spy', __FILE__)
module SunspotMatchers
  class HaveSearchParamsForSession
    include MiniTest::Assertions

    def initialize(session, method, *args, &block)
      @session = session
      @method = method
      @args = (block.nil? ? args : [*args, block])
    end

    def get_matcher
      matcher_class = case @method
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
      end
      matcher_class.new(@session, @args)
    end
  end


  class BeASearchForSession
    def initialize(session, expected_class)
      @session = session
      @expected_class = expected_class
    end

    def match?
      search_types.include?(@expected_class)
    end

    def search_tuple
      search_tuple = @session.is_a?(Array) ? @session : @session.searches.last
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
  module TestHelper
    def assert_has_search_params(session, *method_and_args, &block)
      method, *args = method_and_args
      matcher = HaveSearchParamsForSession.new(session, method, *args, &block).get_matcher
      assert matcher.match?, matcher.missing_param_error_message
    end

    def assert_has_no_search_params(session, *method_and_args, &block)
      method, *args = method_and_args
      matcher = HaveSearchParamsForSession.new(session, method, *args, &block).get_matcher
      assert !matcher.match?, matcher.unexpected_match_error_message
    end

    def assert_is_search_for(session, expected_class)
      matcher = BeASearchForSession.new(session, expected_class)
      assert matcher.match?, matcher.failure_message_for_should
    end

    def assert_is_not_search_for(session, expected_class)
      matcher = BeASearchForSession.new(session, expected_class)
      assert !matcher.match?, matcher.failure_message_for_should_not
    end
  end
end
