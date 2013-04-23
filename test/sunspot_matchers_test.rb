require 'rubygems'
require 'bundler'
require 'sunspot_matchers/test_helper'
require 'test/unit'

class Post; end
class Blog; end
class Person; end

Sunspot.setup(Post) do
  text :body
  text :name
  string :author_name
  integer :blog_id
  integer :category_ids
  integer :popularity
  time :published_at
  float :average_rating
end

Sunspot.setup(Blog) do
  text :body
  string :name
end

class SunspotMatchersTest < Test::Unit::TestCase
  include SunspotMatchers::TestHelper

  def setup
    Sunspot.session = SunspotMatchers::SunspotSessionSpy.new(Sunspot.session)
  end

  def test_specify_search_params
    Sunspot.search(Post) do
      keywords 'great pizza'
    end
    Sunspot.search(Blog) do
      keywords 'bad pizza'
    end
    assert_has_search_params Sunspot.session.searches.first, :keywords, 'great pizza'
    assert_has_search_params Sunspot.session.searches.last, :keywords, 'bad pizza'
  end

  # should allow you to specify your search on multiple models
  def test_specify_search_params_multiple_models
    Sunspot.search([ Post, Blog ]) do
      keywords 'great pizza'
    end
    assert_has_search_params Sunspot.session, :keywords, 'great pizza'
  end
  
  def test_match_keywords
    Sunspot.search(Post) do
      keywords 'great pizza'
    end
    assert_has_search_params Sunspot.session, :keywords, 'great pizza'
  end

  def test_match_keywords_nomatch
    Sunspot.search(Post) do
      keywords 'terrible pizza'
    end
    assert_has_no_search_params Sunspot.session, :keywords, 'great pizza'
  end

  def test_match_multiple_keywords
    Sunspot.search(Post) do
      keywords 'great pizza'
      keywords 'terrible pizza'
    end

    assert_has_search_params Sunspot.session, :keywords do
      keywords 'great pizza'
      keywords 'terrible pizza'
    end
  end

  def test_allow_any_match_keyword
    Sunspot.search(Post) do
      keywords 'great pizza'
    end
    assert_has_search_params Sunspot.session, :keywords, any_param
  end

  def test_allow_any_match_keyword_negative
    Sunspot.search(Post) do
      with :blog_id, 4
    end
    assert_has_no_search_params Sunspot.session, :keywords, any_param
  end

  def test_with_matcher_matches
    Sunspot.search(Post) do
      with :author_name, 'Mark Twain'
    end
    assert_has_search_params Sunspot.session, :with, :author_name, 'Mark Twain'
  end

  def test_with_matcher_doesnt_match_search
    Sunspot.search(Post) do
      with :author_name, 'Mark Twain'
    end
    assert_has_no_search_params Sunspot.session, :with, :author_name, 'John Twain'
  end

  def test_with_matcher_matches_multiple_with
    Sunspot.search(Post) do
      with :author_name, 'Mark Twain'
      with :author_name, 'John Twain'
    end
    assert_has_search_params Sunspot.session, :with do
      with :author_name, 'Mark Twain'
      with :author_name, 'John Twain'
    end
  end

  def test_with_matcher_matches_greater_than
    Sunspot.search(Post) do
      with(:category_ids).greater_than(1)
    end
    assert_has_search_params Sunspot.session, :with do
      with(:category_ids).greater_than(1)
    end
  end

  def test_with_matcher_matches_less_than
    Sunspot.search(Post) do
      with(:category_ids).less_than(1)
    end
    assert_has_search_params Sunspot.session, :with do
      with(:category_ids).less_than(1)
    end
  end

  def test_with_matcher_matches_range
    Sunspot.search(Post) do
      with :category_ids, 1..3
    end
    assert_has_search_params Sunspot.session, :with do
      with :category_ids, 1..3
    end
  end

  def test_with_matcher_matches_any_of
    Sunspot.search(Post) do
      with(:category_ids).any_of [ 1, 2 ]
    end
    assert_has_search_params Sunspot.session, :with do
      with(:category_ids).any_of [ 1, 2 ]
    end
  end

  def test_with_matcher_matches_any_of_multiline
    Sunspot.search(Post) do
      any_of do
        with :category_ids, 1
        with :category_ids, 2
      end
    end
    assert_has_search_params Sunspot.session, :with do
      any_of do
        with :category_ids, 1
        with :category_ids, 2
      end
    end
  end

  def test_with_matcher_matches_any_of_and_all_of
    Sunspot.search(Post) do
      any_of do
        with :category_ids, 1
        all_of do
          with :category_ids, 2
          with :category_ids, 3
        end
      end
    end
    assert_has_search_params Sunspot.session, :with do
      any_of do
        with :category_ids, 1
        all_of do
          with :category_ids, 2
          with :category_ids, 3
        end
      end
    end
  end

  def test_with_matcher_matches_any_param_match
    Sunspot.search(Post) do
      with :blog_id, 4
    end
    assert_has_search_params Sunspot.session, :with, :blog_id, any_param
  end

  def test_with_matcher_matches_any_param_negative_no_with
    Sunspot.search(Post) do
      keywords 'great pizza'
    end
    assert_has_no_search_params Sunspot.session, :with, :blog_id, any_param
  end

  def test_with_matcher_matches_any_param_negative_diff_field
    Sunspot.search(Post) do
      with :category_ids, 7
    end
    assert_has_no_search_params Sunspot.session, :with, :blog_id, any_param
  end

  # 'without' matcher

  def test_without_matcher_matches
    Sunspot.search(Post) do
      without :author_name, 'Mark Twain'
    end
    assert_has_search_params Sunspot.session, :without, :author_name, 'Mark Twain'
  end

  def test_without_matcher_doesnt_match_search
    Sunspot.search(Post) do
      without :author_name, 'Mark Twain'
    end
    assert_has_no_search_params Sunspot.session, :without, :author_name, 'John Twain'
  end

  def test_without_matcher_doesnt_match_with_search
    Sunspot.search(Post) do
      with :author_name, 'Mark Twain'
    end
    assert_has_no_search_params Sunspot.session, :without, :author_name, 'Mark Twain'
  end

  def test_without_matcher_matches_multiple_with
    Sunspot.search(Post) do
      without :author_name, 'Mark Twain'
      without :author_name, 'John Twain'
    end
    assert_has_search_params Sunspot.session, :without do
      without :author_name, 'Mark Twain'
      without :author_name, 'John Twain'
    end
  end

  def test_without_matcher_matches_greater_than
    Sunspot.search(Post) do
      without(:category_ids).greater_than(1)
    end
    assert_has_search_params Sunspot.session, :without do
      without(:category_ids).greater_than(1)
    end
  end

  def test_without_matcher_matches_less_than
    Sunspot.search(Post) do
      without(:category_ids).less_than(1)
    end
    assert_has_search_params Sunspot.session, :without do
      without(:category_ids).less_than(1)
    end
  end

  def test_without_matcher_matches_range
    Sunspot.search(Post) do
      without :category_ids, 1..3
    end
    assert_has_search_params Sunspot.session, :without do
      without :category_ids, 1..3
    end
  end

  def test_without_matcher_matches_any_of
    Sunspot.search(Post) do
      without(:category_ids).any_of [ 1, 2 ]
    end
    assert_has_search_params Sunspot.session, :without do
      without(:category_ids).any_of [ 1, 2 ]
    end
  end

  def test_without_matcher_matches_any_of_multiline
    Sunspot.search(Post) do
      any_of do
        without :category_ids, 1
        without :category_ids, 2
      end
    end
    assert_has_search_params Sunspot.session, :without do
      any_of do
        without :category_ids, 1
        without :category_ids, 2
      end
    end
  end

  def test_without_matcher_matches_any_of_and_all_of
    Sunspot.search(Post) do
      any_of do
        without :category_ids, 1
        all_of do
          without :category_ids, 2
          without :category_ids, 3
        end
      end
    end
    assert_has_search_params Sunspot.session, :without do
      any_of do
        without :category_ids, 1
        all_of do
          without :category_ids, 2
          without :category_ids, 3
        end
      end
    end
  end

  def test_without_matcher_matches_any_param_match
    Sunspot.search(Post) do
      without :blog_id, 4
    end
    assert_has_search_params Sunspot.session, :without, :blog_id, any_param
  end

  def test_without_matcher_matches_any_param_negative_no_without
    Sunspot.search(Post) do
      keywords 'great pizza'
    end
    assert_has_no_search_params Sunspot.session, :without, :blog_id, any_param
  end

  def test_without_matcher_matches_any_param_negative_diff_field
    Sunspot.search(Post) do
      without :category_ids, 7
    end
    assert_has_no_search_params Sunspot.session, :without, :blog_id, any_param
  end

  # 'paginate' matcher

  def test_paginate_matcher_matches
    Sunspot.search(Post) do
      paginate :page => 3, :per_page => 15
    end
    assert_has_search_params Sunspot.session, :paginate, { :page => 3, :per_page => 15 }
  end

  def test_paginate_matcher_matches_page_only
    Sunspot.search(Post) do
      paginate :page => 3
    end
    assert_has_search_params Sunspot.session, :paginate, { :page => 3 }
  end

  def test_paginate_matcher_matches_per_page_only
    Sunspot.search(Post) do
      paginate :per_page => 15
    end
    assert_has_search_params Sunspot.session, :paginate, { :per_page => 15 }
  end

  def test_paginate_matcher_doesnt_match_without_per_page
    Sunspot.search(Post) do
      paginate :page => 3, :per_page => 30
    end
    assert_has_no_search_params Sunspot.session, :paginate, { :page => 3, :per_page => 15 }
  end

  def test_paginate_matcher_doesnt_match_without_page
    Sunspot.search(Post) do
      paginate :page => 5, :per_page => 15
    end
    assert_has_no_search_params Sunspot.session, :paginate, { :page => 3, :per_page => 15 }
  end

  def test_order_by_matcher_matches
    Sunspot.search(Post) do
      order_by :published_at, :desc
    end
    assert_has_search_params Sunspot.session, :order_by, :published_at, :desc
  end

  def test_order_by_matcher_doesnt_match
    Sunspot.search(Post) do
      order_by :published_at, :asc
    end
    assert_has_no_search_params Sunspot.session, :order_by, :published_at, :desc
  end

  def test_order_by_matcher_matches_multiple
    Sunspot.search(Post) do
      order_by :published_at, :asc
      order_by :average_rating, :asc
    end
    assert_has_search_params Sunspot.session, :order_by do
      order_by :published_at, :asc
      order_by :average_rating, :asc
    end
  end

  def test_order_by_matcher_doesnt_match_multiple_reversed
    Sunspot.search(Post) do
      order_by :average_rating, :asc
      order_by :published_at, :asc
    end
    assert_has_no_search_params Sunspot.session, :order_by do
      order_by :published_at, :asc
      order_by :average_rating, :asc
    end
  end

  def test_order_by_matcher_matches_on_random
    Sunspot.search(Post) do
      order_by :average_rating, :asc
      order_by :random
    end
    assert_has_search_params Sunspot.session, :order_by do
      order_by :average_rating, :asc
      order_by :random
    end
  end

  def test_order_by_matcher_doesnt_match_without_random
    Sunspot.search(Post) do
      order_by :average_rating, :asc
      order_by :random
    end
    assert_has_no_search_params Sunspot.session, :order_by do
      order_by :average_rating, :asc
    end
  end

  def test_order_by_matcher_with_score
    Sunspot.search(Post) do
      order_by :average_rating, :asc
      order_by :score
    end
    assert_has_search_params Sunspot.session, :order_by do
      order_by :average_rating, :asc
      order_by :score
    end
  end

  def test_order_by_matcher_doesnt_match_without_score
    Sunspot.search(Post) do
      order_by :average_rating, :asc
      order_by :score
    end
    assert_has_no_search_params Sunspot.session, :order_by do
      order_by :average_rating, :asc
    end
  end

  def test_order_by_matcher_respects_any_param_on_direction
    Sunspot.search(Post) do
      order_by :average_rating, :asc
    end
    assert_has_search_params Sunspot.session, :order_by, :average_rating, any_param
  end

  def test_order_by_matcher_respects_any_param_on_field
    Sunspot.search(Post) do
      order_by :average_rating, :asc
    end
    assert_has_search_params Sunspot.session, :order_by, any_param
  end

  def test_order_by_matcher_doesnt_respect_any_param_on_direction
    Sunspot.search(Post) do
      order_by :score
    end
    assert_has_no_search_params Sunspot.session, :order_by, :average_rating, any_param
  end

  def test_order_by_matcher_doesnt_respect_any_param_on_field
    Sunspot.search(Post) do
      keywords 'great pizza'
    end
    assert_has_no_search_params Sunspot.session, :order_by, any_param
  end

  def test_order_by_matcher_respects_any_param_on_field_and_dir
    Sunspot.search(Post) do
      order_by :score, :desc
    end
    assert_has_search_params Sunspot.session, :order_by, any_param, any_param
  end

  def test_order_by_matcher_respects_any_param_on_field_and_dir
    Sunspot.search(Post) do
      keywords 'great pizza'
    end
    assert_has_no_search_params Sunspot.session, :order_by, any_param, any_param
  end

  # 'facet' matcher

  def test_facet_matcher_matches_field_facets
    Sunspot.search(Post) do
      facet :category_ids
    end
    assert_has_search_params Sunspot.session, :facet, :category_ids
  end

  def test_facet_matcher_doesnt_match_nonexistent_facet
    Sunspot.search(Post) do
      paginate :page => 5, :per_page => 15
    end
    assert_has_no_search_params Sunspot.session, :facet, :category_ids
  end

  def test_facet_matcher_matches_excluding_filters
    Sunspot.search(Post) do
      category_filter = with(:category_ids, 2)
      facet(:category_ids, :exclude => category_filter)
    end
    assert_has_search_params Sunspot.session, :facet do
      category_filter = with(:category_ids, 2)
      facet(:category_ids, :exclude => category_filter)
    end
  end

  def test_query_facet_matcher_matches
    Sunspot.search(Post) do
      facet(:average_rating) do
        row(1.0..2.0) do
          with(:average_rating, 1.0..2.0)
        end
        row(2.0..3.0) do
          with(:average_rating, 2.0..3.0)
        end
      end
    end
    assert_has_search_params Sunspot.session, :facet do
      facet(:average_rating) do
        row(1.0..2.0) do
          with(:average_rating, 1.0..2.0)
        end
        row(2.0..3.0) do
          with(:average_rating, 2.0..3.0)
        end
      end
    end
  end

  def test_query_facet_matcher_doesnt_match_missing_facet
    Sunspot.search(Post) do
      facet(:average_rating) do
        row(1.0..2.0) do
          with(:average_rating, 1.0..2.0)
        end
      end
    end
    assert_has_no_search_params Sunspot.session, :facet do
      facet(:average_rating) do
        row(1.0..2.0) do
          with(:average_rating, 1.0..2.0)
        end
        row(2.0..3.0) do
          with(:average_rating, 2.0..3.0)
        end
      end
    end
  end

  def test_query_facet_matcher_doesnt_match_different_query
    Sunspot.search(Post) do
      facet(:average_rating) do
        row(1.0..2.0) do
          with(:average_rating, 1.0..2.0)
        end
        row(2.0..3.0) do
          with(:average_rating, 2.0..3.0)
        end
      end
    end
    assert_has_no_search_params Sunspot.session, :facet do
      facet(:average_rating) do
        row(1.0..2.0) do
          with(:average_rating, 1.0..2.0)
        end
        row(2.0..3.0) do
          with(:average_rating, 2.0..4.0)
        end
      end
    end
  end

  # 'boost' matcher

  def test_boost_matcher_matches
    Sunspot.search(Post) do
      keywords 'great pizza' do
        boost_fields :body => 2.0
      end
    end
    assert_has_search_params Sunspot.session, :boost do
      keywords 'great pizza' do
        boost_fields :body => 2.0
      end
    end
  end

  def test_boost_matcher_doesnt_match_on_boost_mismatch
    Sunspot.search(Post) do
      keywords 'great pizza' do
        boost_fields :body => 2.0
      end
    end
    assert_has_no_search_params Sunspot.session, :boost do
      keywords 'great pizza' do
        boost_fields :body => 3.0
      end
    end
  end

  def test_boost_matcher_matches_boost_query
    Sunspot.search(Post) do
      keywords 'great pizza' do
        boost(2.0) do
          with :blog_id, 4
        end
      end
    end
    assert_has_search_params Sunspot.session, :boost do
      keywords 'great pizza' do
        boost(2.0) do
          with :blog_id, 4
        end
      end
    end
  end

  def test_boost_matcher_doesnt_match_on_boost_query_mismatch
    Sunspot.search(Post) do
      keywords 'great pizza' do
        boost(2.0) do
          with :blog_id, 4
        end
      end
    end
    assert_has_no_search_params Sunspot.session, :boost do
      keywords 'great pizza' do
        boost(2.0) do
          with :blog_id, 5
        end
      end
    end
  end

  def test_boost_matcher_matches_boost_function
    Sunspot.search(Post) do
      keywords 'great pizza' do
        boost(function { sum(:average_rating, product(:popularity, 10)) })
      end
    end
    assert_has_search_params Sunspot.session, :boost do
      keywords 'great pizza' do
        boost(function { sum(:average_rating, product(:popularity, 10)) })
      end
    end
  end

  def test_boost_matcher_doesnt_match_on_boost_function_mismatch
    Sunspot.search(Post) do
      keywords 'great pizza' do
        boost(function { sum(:average_rating, product(:popularity, 10)) })
      end
    end
    assert_has_no_search_params Sunspot.session, :boost do
      keywords 'great pizza' do
        boost(function { sum(:average_rating, product(:popularity, 42)) })
      end
    end
  end

  # 'be a search for'

  def test_be_a_search_for
    Sunspot.search(Post) { keywords 'great pizza' }
    assert_is_search_for Sunspot.session, Post
  end

  def test_be_a_search_for_model_mismatch
    Sunspot.search(Post) { keywords 'great pizza' }
    assert_is_not_search_for Sunspot.session, Blog
  end

  def test_be_a_search_for_multiple_models
    Sunspot.search(Post) { keywords 'great pizza' }
    Sunspot.search([ Post, Blog ]) do
      keywords 'great pizza'
    end
    assert_is_search_for Sunspot.session, Post
    assert_is_search_for Sunspot.session, Blog
    assert_is_not_search_for Sunspot.session, Person
  end
 
  def test_be_a_search_for_multiple_searches
    Sunspot.search(Post) { keywords 'great pizza' }
    Sunspot.search(Blog) { keywords 'bad pizza' }
    assert_is_search_for Sunspot.session.searches.first, Post
    assert_is_search_for Sunspot.session.searches.last, Blog
  end
end