require 'sunspot'
require 'sunspot_matchers'

class Post; end
class Blog; end

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

describe "Sunspot Matchers" do
  include SunspotMatchers
  
  before do
    Sunspot.session = SunspotMatchers::SunspotSessionSpy.new(Sunspot.session)
  end

  describe "have_search_params" do
    it "should allow you to specify your search" do
      Sunspot.search(Post) do
        keywords 'great pizza'
      end
      Sunspot.search(Blog) do
        keywords 'bad pizza'
      end
      Sunspot.session.searches.first.should have_search_params(:keywords, 'great pizza')
      Sunspot.session.searches.last.should have_search_params(:keywords, 'bad pizza')
    end

    describe "keyword matcher" do
      it "should match if search matches" do
        Sunspot.search(Post) do
          keywords 'great pizza'
        end
        Sunspot.session.should have_search_params(:keywords, 'great pizza')
      end

      it "should not match if search does not match" do
        Sunspot.search(Post) do
          keywords 'terrible pizza'
        end
        Sunspot.session.should_not have_search_params(:keywords, 'great pizza')
      end

      it "should match for multiple keywords" do
        Sunspot.search(Post) do
          keywords 'great pizza'
          keywords 'terrible pizza'
        end
        Sunspot.session.should have_search_params(:keywords, Proc.new {
          keywords 'great pizza'
          keywords 'terrible pizza'
        })
      end

      it "should work with any_param match" do
        Sunspot.search(Post) do
          keywords 'great pizza'
        end
        Sunspot.session.should have_search_params(:keywords, any_param)
      end

      it "should work with any_param negative match" do
        Sunspot.search(Post) do
          with :blog_id, 4
        end
        Sunspot.session.should_not have_search_params(:keywords, any_param)
      end
    end

    describe "with matcher" do
      it "should match if search matches" do
        Sunspot.search(Post) do
          with :author_name, 'Mark Twain'
        end
        Sunspot.session.should have_search_params(:with, :author_name, 'Mark Twain')
      end

      it "should not match if search does not match" do
        Sunspot.search(Post) do
          with :author_name, 'Mark Twain'
        end
        Sunspot.session.should_not have_search_params(:with, :author_name, 'John Twain')
      end

      it "should match for multiple with" do
        Sunspot.search(Post) do
          with :author_name, 'Mark Twain'
          with :author_name, 'John Twain'
        end
        Sunspot.session.should have_search_params(:with, Proc.new {
          with :author_name, 'Mark Twain'
          with :author_name, 'John Twain'
        })
      end

      it "should match for greater_than" do
        Sunspot.search(Post) do
          with(:category_ids).greater_than(1)
        end
        Sunspot.session.should have_search_params(:with, Proc.new {
          with(:category_ids).greater_than(1)
        })
      end

      it "should match for less_than" do
        Sunspot.search(Post) do
          with(:category_ids).less_than(1)
        end
        Sunspot.session.should have_search_params(:with, Proc.new {
          with(:category_ids).less_than(1)
        })
      end

      it "should match for range" do
        Sunspot.search(Post) do
          with :category_ids, 1..3
        end
        Sunspot.session.should have_search_params(:with, Proc.new {
          with :category_ids, 1..3
        })
      end

      it "should match any_of" do
        Sunspot.search(Post) do
          with(:category_ids).any_of [1,2]
        end
        Sunspot.session.should have_search_params(:with, Proc.new {
          with(:category_ids).any_of [1,2]
        })
      end

      it "should match any_of multiline" do
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
      end

      it "should match any_of and all_of" do
        Sunspot.search(Post) do
          any_of do
            with :category_ids, 1
            all_of do
              with :category_ids, 2
              with :category_ids, 3
            end
          end
        end
        Sunspot.session.should have_search_params(:with, Proc.new {
          any_of do
            with :category_ids, 1
            all_of do
              with :category_ids, 2
              with :category_ids, 3
            end
          end
        })
      end

      it "should work with any_param match" do
        Sunspot.search(Post) do
          with :blog_id, 4
        end
        Sunspot.session.should have_search_params(:with, :blog_id, any_param)
      end

      it "should work with any_param negative match no with at all" do
        Sunspot.search(Post) do
          keywords 'great pizza'
        end
        Sunspot.session.should_not have_search_params(:with, :blog_id, any_param)
      end

      it "should work with any_param negative match different field with query" do
        Sunspot.search(Post) do
          with :category_ids, 7
        end
        Sunspot.session.should_not have_search_params(:with, :blog_id, any_param)
      end
    end

    describe "without matcher" do
      it "should match if search matches" do
        Sunspot.search(Post) do
          without :author_name, 'Mark Twain'
        end
        Sunspot.session.should have_search_params(:without, :author_name, 'Mark Twain')
      end

      it "should not match if search does not match" do
        Sunspot.search(Post) do
          without :author_name, 'Mark Twain'
        end
        Sunspot.session.should_not have_search_params(:without, :author_name, 'John Twain')
      end

      it "should not match a with search" do
        Sunspot.search(Post) do
          with :author_name, 'Mark Twain'
        end
        Sunspot.session.should_not have_search_params(:without, :author_name, 'Mark Twain')
      end

      it "should match for multiple without" do
        Sunspot.search(Post) do
          without :author_name, 'Mark Twain'
          without :author_name, 'John Twain'
        end
        Sunspot.session.should have_search_params(:without, Proc.new {
          without :author_name, 'Mark Twain'
          without :author_name, 'John Twain'
        })
      end

      it "should match for greater_than" do
        Sunspot.search(Post) do
          without(:category_ids).greater_than(1)
        end
        Sunspot.session.should have_search_params(:without, Proc.new {
          without(:category_ids).greater_than(1)
        })
      end

      it "should match for less_than" do
        Sunspot.search(Post) do
          without(:category_ids).less_than(1)
        end
        Sunspot.session.should have_search_params(:without, Proc.new {
          without(:category_ids).less_than(1)
        })
      end

      it "should match for range" do
        Sunspot.search(Post) do
          without :category_ids, 1..3
        end
        Sunspot.session.should have_search_params(:without, Proc.new {
          without :category_ids, 1..3
        })
      end

      it "should match any_of" do
        Sunspot.search(Post) do
          without(:category_ids).any_of [1,2]
        end
        Sunspot.session.should have_search_params(:without, Proc.new {
          without(:category_ids).any_of [1,2]
        })
      end

      it "should match any_of multiline" do
        Sunspot.search(Post) do
          any_of do
            without :category_ids, 1
            without :category_ids, 2
          end
        end
        Sunspot.session.should have_search_params(:without, Proc.new {
          any_of do
            without :category_ids, 1
            without :category_ids, 2
          end
        })
      end

      it "should match any_of and all_of" do
        Sunspot.search(Post) do
          any_of do
            without :category_ids, 1
            all_of do
              without :category_ids, 2
              without :category_ids, 3
            end
          end
        end
        Sunspot.session.should have_search_params(:without, Proc.new {
          any_of do
            without :category_ids, 1
            all_of do
              without :category_ids, 2
              without :category_ids, 3
            end
          end
        })
      end

      it "should work with any_param match" do
        Sunspot.search(Post) do
          without :blog_id, 4
        end
        Sunspot.session.should have_search_params(:without, :blog_id, any_param)
      end

      it "should work with any_param negative match no without at all" do
        Sunspot.search(Post) do
          keywords 'great pizza'
        end
        Sunspot.session.should_not have_search_params(:without, :blog_id, any_param)
      end

      it "should work with any_param negative match different field without query" do
        Sunspot.search(Post) do
          without :category_ids, 4
        end
        Sunspot.session.should_not have_search_params(:without, :blog_id, any_param)
      end
    end

    describe "paginate matcher" do
      it "should match if search matches" do
        Sunspot.search(Post) do
          paginate :page => 3, :per_page => 15
        end
        Sunspot.session.should have_search_params(:paginate, :page => 3, :per_page => 15)
      end

      it "should match if search matches, page only" do
        Sunspot.search(Post) do
          paginate :page => 3
        end
        Sunspot.session.should have_search_params(:paginate, :page => 3)
      end

      it "should match if search matches, per_page only" do
        Sunspot.search(Post) do
          paginate :per_page => 15
        end
        Sunspot.session.should have_search_params(:paginate, :per_page => 15)
      end

      it "should not match if per_page does not match" do
        Sunspot.search(Post) do
          paginate :page => 3, :per_page => 30
        end
        Sunspot.session.should_not have_search_params(:paginate, :page => 3, :per_page => 15)
      end

      it "should not match if page does not match" do
        Sunspot.search(Post) do
          paginate :page => 5, :per_page => 15
        end
        Sunspot.session.should_not have_search_params(:paginate, :page => 3, :per_page => 15)
      end
    end

    describe "order_by matcher" do
      it "should match if search matches" do
        Sunspot.search(Post) do
          order_by :published_at, :desc
        end
        Sunspot.session.should have_search_params(:order_by, :published_at, :desc)
      end

      it "should not match if search does not match" do
        Sunspot.search(Post) do
          order_by :published_at, :asc
        end
        Sunspot.session.should_not have_search_params(:order_by, :published_at, :desc)
      end

      it "should match for multiple orderings" do
        Sunspot.search(Post) do
          order_by :published_at, :asc
          order_by :average_rating, :asc
        end
        Sunspot.session.should have_search_params(:order_by, Proc.new {
          order_by :published_at, :asc
          order_by :average_rating, :asc
        })
      end

      it "should not match if multiple orderings are reversed" do
        Sunspot.search(Post) do
          order_by :average_rating, :asc
          order_by :published_at, :asc
        end
        Sunspot.session.should_not have_search_params(:order_by, Proc.new {
          order_by :published_at, :asc
          order_by :average_rating, :asc
        })
      end

      it "should match when using random" do
        Sunspot.search(Post) do
          order_by :average_rating, :asc
          order_by :random
        end
        Sunspot.session.should have_search_params(:order_by, Proc.new {
          order_by :average_rating, :asc
          order_by :random
        })
      end

      it "should not match when random is missing" do
        Sunspot.search(Post) do
          order_by :average_rating, :asc
          order_by :random
        end
        Sunspot.session.should_not have_search_params(:order_by, Proc.new {
          order_by :average_rating, :asc
        })
      end

      it "should match when using score" do
        Sunspot.search(Post) do
          order_by :average_rating, :asc
          order_by :score
        end
        Sunspot.session.should have_search_params(:order_by, Proc.new {
          order_by :average_rating, :asc
          order_by :score
        })
      end

      it "should not match when score is missing" do
        Sunspot.search(Post) do
          order_by :average_rating, :asc
          order_by :score
        end
        Sunspot.session.should_not have_search_params(:order_by, Proc.new {
          order_by :average_rating, :asc
        })
      end

      it "should work with any_param match on direction" do
        Sunspot.search(Post) do
          order_by :average_rating, :asc
        end
        Sunspot.session.should have_search_params(:order_by, :average_rating, any_param)
      end

      it "should work with any_param match on field" do
        Sunspot.search(Post) do
          order_by :average_rating, :asc
        end
        Sunspot.session.should have_search_params(:order_by, any_param)
      end

      it "should work with any_param negative match on direction" do
        Sunspot.search(Post) do
          order_by :score
        end
        Sunspot.session.should_not have_search_params(:order_by, :average_rating, any_param)
      end

      it "should work with any_param negative match on field" do
        Sunspot.search(Post) do
          keywords 'great pizza'
        end
        Sunspot.session.should_not have_search_params(:order_by, any_param)
      end

      it "should work with any_param match on field and direction" do
        Sunspot.search(Post) do
          order_by :score, :desc
        end
        Sunspot.session.should have_search_params(:order_by, any_param, any_param)
      end

      it "should work with any_param negative match on field and direction" do
        Sunspot.search(Post) do
          keywords 'great pizza'
        end
        Sunspot.session.should_not have_search_params(:order_by, any_param, any_param)
      end
    end

    describe "facet matcher" do
      describe "field facets" do
        it "should match if facet exists" do
          Sunspot.search(Post) do
            facet :category_ids
          end
          Sunspot.session.should have_search_params(:facet, :category_ids)
        end

        it "should not match if facet does not exist" do
          Sunspot.search(Post) do
            paginate :page => 5, :per_page => 15
          end
          Sunspot.session.should_not have_search_params(:facet, :category_ids)
        end

        it "should match when excluding filters" do
          Sunspot.search(Post) do
            category_filter = with(:category_ids, 2)
            facet(:category_ids, :exclude => category_filter)
          end
          Sunspot.session.should have_search_params(:facet, Proc.new {
            category_filter = with(:category_ids, 2)
            facet(:category_ids, :exclude => category_filter)
          })
        end
      end

      describe "query facets" do
        it "should match if facet exists" do
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
        end

        it "should not match if actual search is missing a facet" do
          Sunspot.search(Post) do
            facet(:average_rating) do
              row(1.0..2.0) do
                with(:average_rating, 1.0..2.0)
              end
            end
          end
          Sunspot.session.should_not have_search_params(:facet, Proc.new {
            facet(:average_rating) do
              row(1.0..2.0) do
                with(:average_rating, 1.0..2.0)
              end
              row(2.0..3.0) do
                with(:average_rating, 2.0..3.0)
              end
            end
          })
        end

        it "should not match if facet query is different" do
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
          Sunspot.session.should_not have_search_params(:facet, Proc.new {
            facet(:average_rating) do
              row(1.0..2.0) do
                with(:average_rating, 1.0..2.0)
              end
              row(2.0..3.0) do
                with(:average_rating, 2.0..4.0)
              end
            end
          })
        end
      end
    end

    describe "boost matcher" do
      it "should match if field boost matches" do
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
      end

      it "should not match if field boost does not match" do
        Sunspot.search(Post) do
          keywords 'great pizza' do
            boost_fields :body => 2.0
          end
        end
        Sunspot.session.should_not have_search_params(:boost, Proc.new {
          keywords 'great pizza' do
            boost_fields :body => 3.0
          end
        })
      end

      it "should match if boost query matches" do
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
      end

      it "should not match if boost query does not match" do
        Sunspot.search(Post) do
          keywords 'great pizza' do
            boost(2.0) do
              with :blog_id, 4
            end
          end
        end
        Sunspot.session.should_not have_search_params(:boost, Proc.new {
          keywords 'great pizza' do
            boost(2.0) do
              with :blog_id, 5
            end
          end
        })
      end

      it "should match if boost function matches" do
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
      end

      it "should not match if boost function does not match" do
        Sunspot.search(Post) do
          keywords 'great pizza' do
            boost(function { sum(:average_rating, product(:popularity, 10)) })
          end
        end
        Sunspot.session.should_not have_search_params(:boost, Proc.new {
          keywords 'great pizza' do
            boost(function { sum(:average_rating, product(:popularity, 42)) })
          end
        })
      end
    end

  end

  describe "be_a_search_for" do
    before do
      Sunspot.search(Post) do
        keywords 'great pizza'
      end
    end

    it "should succeed if the model is correct" do
      Sunspot.session.should be_a_search_for(Post)
    end

    it "should fail if the model is incorrect" do
      Sunspot.session.should_not be_a_search_for(Blog)
    end

    describe "with multiple searches" do
      it "should allow you to choose the search" do
        Sunspot.search(Blog) do
          keywords 'bad pizza'
        end
        Sunspot.session.searches.first.should be_a_search_for(Post)
        Sunspot.session.searches.last.should be_a_search_for(Blog)
      end
    end
  end
end
