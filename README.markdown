# Sunspot Matchers

[Sunspot](http://outoftime.github.com/sunspot/) is a great Ruby library for constructing searches against Solr.  However,
because of the way the Sunspot DSL is constructed, it can be difficult to do simple assertions about your searches
without doing full integration tests.

The goal of these matchers are to make it easier to unit test search logic without having to construct the individual
fixture scenarios inside of Solr and then actually perform a search against Solr.

# Installation

You will need to replace the Sunspot Session object with the spy provided.  You can do this globally by putting the
following in your spec_helper.

    config.before do
      Sunspot.session = SunspotMatchers::SunspotSessionSpy.new(Sunspot.session)
    end

Keep in mind, this will prevent any test from actually hitting Solr, so if you have integration tests, you'll either
need to be more careful which tests you replace the session for, or you'll need to restore the original session before
those tests

    Sunspot.session = Sunspot.session.original_session

You will also need to include the matchers in your specs.  Again, this can be done globally in your spec_helper.

    config.include SunspotMatchers

Alternately, you could include them into individual tests if needed.

# Matchers

## be_a_search_for

If you perform a search against your Post model, you could write this expectation:

`Sunspot.session.should be_a_search_for(Post)`

Individual searches are stored in an array, so if you perform multiple, you'll have to match against them manually.  Without
an explicit search specified, it will use the last one.

`Sunspot.session.searches.first.should be_a_search_for(Post)`

## have_search_params

This is where the bulk of the functionality lies.  There are seven types of search matches you can perform: `keywords`,
`with`, `without`, `paginate`, `order_by`, `facet`, and `boost`.

In all of the examples below, the expectation fully matches the search terms.  This is not expected or required.  You can
have a dozen `with` restrictions on a search and still write an expectation on a single one of them.

Negative expectations also work correctly.  `should_not` will fail if the search actually includes the expectation.

With all matchers, you can specify a `Proc` as the second argument, and perform multi statement expectations inside the
Proc.  Keep in mind, that only the expectation type specified in the first argument will actually be checked.  So if
you specify `keywords` and `with` restrictions in the same Proc, but you said `have_search_params(:keywords, ...`
the `with` restrictions are simply ignored.

### wildcard matching

keywords, with, without, and order_by support wildcard expectations using the `any_param` parameter:

    Sunspot.search(Post) do
      with :blog_id, 4
      order_by :blog_id, :desc
    end

    Sunspot.session.should have_search_params(:with, :blog_id, any_param)
    Sunspot.session.should have_search_params(:order_by, :blog_id, any_param)
    Sunspot.session.should have_search_params(:order_by, any_param)
    Sunspot.session.should_not have_search_params(:order_by, :category_ids, any_param)

### :keywords

You can match against a keyword search:

    Sunspot.search(Post) do
      keywords 'great pizza'
    end

    Sunspot.session.should have_search_params(:keywords, 'great pizza')

### :with

You can match against a with restriction:

    Sunspot.search(Post) do
      with :author_name, 'Mark Twain'
    end

    Sunspot.session.should have_search_params(:with, :author_name, 'Mark Twain')

Complex conditions can be matched by using a Proc instead of a value.  Be aware that order does matter, not for
the actual results that would come out of Solr, but the matcher will fail of the order of `with` restrictions is
different.

    Sunspot.search(Post) do
      any_of do
        with :category_ids, 1
        with :category_ids, 2
      end
    end

    Sunspot.session.should have_search_params(:with, Proc.new {
      any_of do
        with :category_ids, 1
        with :category_ids, 2
      end
    })

### :without

Without is nearly identical to with:

    Sunspot.search(Post) do
      without :author_name, 'Mark Twain'
    end

    Sunspot.session.should have_search_params(:without, :author_name, 'Mark Twain')

### :paginate

You can also specify only page or per_page, both are not required.

    Sunspot.search(Post) do
      paginate :page => 3, :per_page => 15
    end

    Sunspot.session.should have_search_params(:paginate, :page => 3, :per_page => 15)

### :order_by

Expectations on multiple orderings are supported using using the Proc format mentioned above.

    Sunspot.search(Post) do
      order_by :published_at, :desc
    end

    Sunspot.session.should have_search_params(:order_by, :published_at, :desc)

### :facet

Standard faceting expectation:

    Sunspot.search(Post) do
      facet :category_ids
    end

    Sunspot.session.should have_search_params(:facet, :category_ids)

Faceting where a query is excluded:

    Sunspot.search(Post) do
      category_filter = with(:category_ids, 2)
      facet(:category_ids, :exclude => category_filter)
    end

    Sunspot.session.should have_search_params(:facet, Proc.new {
      category_filter = with(:category_ids, 2)
      facet(:category_ids, :exclude => category_filter)
    })

Query faceting:

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
    
    Sunspot.session.should have_search_params(:facet, Proc.new {
      facet(:average_rating) do
        row(1.0..2.0) do
          with(:average_rating, 1.0..2.0)
        end
        row(2.0..3.0) do
          with(:average_rating, 2.0..3.0)
        end
      end
    })

### :boost

Field boost matching:

    Sunspot.search(Post) do
      keywords 'great pizza' do
        boost_fields :body => 2.0
      end
    end

    Sunspot.session.should have_search_params(:boost, Proc.new {
      keywords 'great pizza' do
        boost_fields :body => 2.0
      end
    })

Boost query matching:

    Sunspot.search(Post) do
      keywords 'great pizza' do
        boost(2.0) do
          with :blog_id, 4
        end
      end
    end

    Sunspot.session.should have_search_params(:boost, Proc.new {
      keywords 'great pizza' do
        boost(2.0) do
          with :blog_id, 4
        end
      end
    })

Boost function matching:

    Sunspot.search(Post) do
      keywords 'great pizza' do
        boost(function { sum(:average_rating, product(:popularity, 10)) })
      end
    end

    Sunspot.session.should have_search_params(:boost, Proc.new {
      keywords 'great pizza' do
        boost(function { sum(:average_rating, product(:popularity, 10)) })
      end
    })