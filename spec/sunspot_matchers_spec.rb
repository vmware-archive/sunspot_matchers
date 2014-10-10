require 'sunspot'
require 'sunspot_matchers'
require 'rspec'

class Post;
end
class Blog;
end
class Person;
end
class PersistentPost
  attr_accessor :id, :body, :name, :author_name, :blog_id, :category_ids, :popularity, :published_at, :average_rating
end
class PersistentPostInstanceAdapter < Sunspot::Adapters::InstanceAdapter
  def id
    1
  end
end

Sunspot::Adapters::InstanceAdapter.register(PersistentPostInstanceAdapter, PersistentPost)

Sunspot.setup(PersistentPost) do
  text :body
  text :name
  string :author_name
  integer :blog_id
  integer :category_ids
  integer :popularity
  time :published_at
  float :average_rating
end

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
    it "allows you to specify your search on multiple models" do
      Sunspot.search([Post, Blog]) do
        keywords 'great pizza'
      end
      expect(Sunspot.session).to have_search_params(:keywords, 'great pizza')
    end

    it "allows you to specify your search" do
      Sunspot.search(Post) do
        keywords 'great pizza'
      end
      Sunspot.search(Blog) do
        keywords 'bad pizza'
      end
      expect(Sunspot.session.searches.first).to have_search_params(:keywords, 'great pizza')
      expect(Sunspot.session.searches.last).to have_search_params(:keywords, 'bad pizza')
    end

    describe "keyword/fulltext matcher" do
      it "matches if search matches" do
        Sunspot.search(Post) do
          keywords 'great pizza'
        end
        expect(Sunspot.session).to have_search_params(:keywords, 'great pizza')
      end

      it "works with fulltext also" do
        Sunspot.search(Post) do
          fulltext 'great pizza'
        end
        expect(Sunspot.session).to have_search_params(:fulltext, 'great pizza')
      end

      it "does not match if search does not match" do
        Sunspot.search(Post) do
          keywords 'terrible pizza'
        end
        expect(Sunspot.session).to_not have_search_params(:keywords, 'great pizza')
      end

      it "matches for multiple keywords" do
        Sunspot.search(Post) do
          keywords 'great pizza'
          keywords 'terrible pizza'
        end
        expect(Sunspot.session).to have_search_params(:keywords) {
          keywords 'great pizza'
          keywords 'terrible pizza'
        }
      end

      it "works with any_param match" do
        Sunspot.search(Post) do
          keywords 'great pizza'
        end
        expect(Sunspot.session).to have_search_params(:keywords, any_param)
      end

      it "works with any_param negative match" do
        Sunspot.search(Post) do
          with :blog_id, 4
        end
        expect(Sunspot.session).to_not have_search_params(:keywords, any_param)
      end
    end

    describe "with matcher" do
      it "matches if search matches" do
        Sunspot.search(Post) do
          with :author_name, 'Mark Twain'
        end
        expect(Sunspot.session).to have_search_params(:with, :author_name, 'Mark Twain')
      end

      it "does not match if search does not match" do
        Sunspot.search(Post) do
          with :author_name, 'Mark Twain'
        end
        expect(Sunspot.session).to_not have_search_params(:with, :author_name, 'John Twain')
      end

      it "matches for multiple with" do
        Sunspot.search(Post) do
          with :author_name, 'Mark Twain'
          with :author_name, 'John Twain'
        end
        expect(Sunspot.session).to have_search_params(:with) {
          with :author_name, 'Mark Twain'
          with :author_name, 'John Twain'
        }
      end

      it "matches for greater_than" do
        Sunspot.search(Post) do
          with(:category_ids).greater_than(1)
        end
        expect(Sunspot.session).to have_search_params(:with) {
          with(:category_ids).greater_than(1)
        }
      end

      it "matches for less_than" do
        Sunspot.search(Post) do
          with(:category_ids).less_than(1)
        end
        expect(Sunspot.session).to have_search_params(:with) {
          with(:category_ids).less_than(1)
        }
      end

      it "matches for range" do
        Sunspot.search(Post) do
          with :category_ids, 1..3
        end
        expect(Sunspot.session).to have_search_params(:with) {
          with :category_ids, 1..3
        }
      end

      it "matches any_of" do
        Sunspot.search(Post) do
          with(:category_ids).any_of [1, 2]
        end
        expect(Sunspot.session).to have_search_params(:with) {
          with(:category_ids).any_of [1, 2]
        }
      end

      it "matches any_of multiline" do
        Sunspot.search(Post) do
          any_of do
            with :category_ids, 1
            with :category_ids, 2
          end
        end
        expect(Sunspot.session).to have_search_params(:with) {
          any_of do
            with :category_ids, 1
            with :category_ids, 2
          end
        }
      end

      it "matches any_of and all_of" do
        Sunspot.search(Post) do
          any_of do
            with :category_ids, 1
            all_of do
              with :category_ids, 2
              with :category_ids, 3
            end
          end
        end
        expect(Sunspot.session).to have_search_params(:with) {
          any_of do
            with :category_ids, 1
            all_of do
              with :category_ids, 2
              with :category_ids, 3
            end
          end
        }
      end

      it "works with any_param match" do
        Sunspot.search(Post) do
          with :blog_id, 4
        end
        expect(Sunspot.session).to have_search_params(:with, :blog_id, any_param)
      end

      it "works with a time attribute and any_param match" do
        Sunspot.search(Post) do
          with :published_at, 'July 1st, 2009'
        end
        expect(Sunspot.session).to have_search_params(:with, :published_at, any_param)
      end

      it "works with any_param negative match no with at all" do
        Sunspot.search(Post) do
          keywords 'great pizza'
        end
        expect(Sunspot.session).to_not have_search_params(:with, :blog_id, any_param)
      end

      it "works with any_param negative match when without exists" do
        Sunspot.search(Post) do
          without :blog_id, 4
          without :blog_id, 5
        end
        expect(Sunspot.session).to_not have_search_params(:with, :blog_id, any_param)
      end

      it "works with any_param negative match different field with query" do
        Sunspot.search(Post) do
          with :category_ids, 7
        end
        expect(Sunspot.session).to_not have_search_params(:with, :blog_id, any_param)
      end
    end

    describe "without matcher" do
      it "matches if search matches" do
        Sunspot.search(Post) do
          without :author_name, 'Mark Twain'
        end
        expect(Sunspot.session).to have_search_params(:without, :author_name, 'Mark Twain')
      end

      it "does not match if search does not match" do
        Sunspot.search(Post) do
          without :author_name, 'Mark Twain'
        end
        expect(Sunspot.session).to_not have_search_params(:without, :author_name, 'John Twain')
      end

      it "does not match a with search" do
        Sunspot.search(Post) do
          with :author_name, 'Mark Twain'
        end
        expect(Sunspot.session).to_not have_search_params(:without, :author_name, 'Mark Twain')
      end

      it "matches for multiple without" do
        Sunspot.search(Post) do
          without :author_name, 'Mark Twain'
          without :author_name, 'John Twain'
        end
        expect(Sunspot.session).to have_search_params(:without) {
          without :author_name, 'Mark Twain'
          without :author_name, 'John Twain'
        }
      end

      it "matches for greater_than" do
        Sunspot.search(Post) do
          without(:category_ids).greater_than(1)
        end
        expect(Sunspot.session).to have_search_params(:without) {
          without(:category_ids).greater_than(1)
        }
      end

      it "matches for less_than" do
        Sunspot.search(Post) do
          without(:category_ids).less_than(1)
        end
        expect(Sunspot.session).to have_search_params(:without) {
          without(:category_ids).less_than(1)
        }
      end

      it "matches for range" do
        Sunspot.search(Post) do
          without :category_ids, 1..3
        end
        expect(Sunspot.session).to have_search_params(:without) {
          without :category_ids, 1..3
        }
      end

      it "matches any_of" do
        Sunspot.search(Post) do
          without(:category_ids).any_of [1, 2]
        end
        expect(Sunspot.session).to have_search_params(:without) {
          without(:category_ids).any_of [1, 2]
        }
      end

      it "matches any_of multiline" do
        Sunspot.search(Post) do
          any_of do
            without :category_ids, 1
            without :category_ids, 2
          end
        end
        expect(Sunspot.session).to have_search_params(:without) {
          any_of do
            without :category_ids, 1
            without :category_ids, 2
          end
        }
      end

      it "matches any_of and all_of" do
        Sunspot.search(Post) do
          any_of do
            without :category_ids, 1
            all_of do
              without :category_ids, 2
              without :category_ids, 3
            end
          end
        end
        expect(Sunspot.session).to have_search_params(:without) {
          any_of do
            without :category_ids, 1
            all_of do
              without :category_ids, 2
              without :category_ids, 3
            end
          end
        }
      end

      it "works with any_param match" do
        Sunspot.search(Post) do
          without :blog_id, 4
        end
        expect(Sunspot.session).to have_search_params(:without, :blog_id, any_param)
      end

      it "works with any_param negative match no without at all" do
        Sunspot.search(Post) do
          keywords 'great pizza'
        end
        expect(Sunspot.session).to_not have_search_params(:without, :blog_id, any_param)
      end

      it "works with any_param negative match when with exists" do
        Sunspot.search(Post) do
          with :blog_id, 4
        end
        expect(Sunspot.session).to_not have_search_params(:without, :blog_id, any_param)
      end

      it "works with any_param negative match different field without query" do
        Sunspot.search(Post) do
          without :category_ids, 4
        end
        expect(Sunspot.session).to_not have_search_params(:without, :blog_id, any_param)
      end
    end

    describe "paginate matcher" do
      it "matches if search matches" do
        Sunspot.search(Post) do
          paginate :page => 3, :per_page => 15
        end
        expect(Sunspot.session).to have_search_params(:paginate, :page => 3, :per_page => 15)
      end

      it "matches if search matches, page only" do
        Sunspot.search(Post) do
          paginate :page => 3
        end
        expect(Sunspot.session).to have_search_params(:paginate, :page => 3)
      end

      it "matches if search matches, per_page only" do
        Sunspot.search(Post) do
          paginate :per_page => 15
        end
        expect(Sunspot.session).to have_search_params(:paginate, :per_page => 15)
      end

      it "does not match if per_page does not match" do
        Sunspot.search(Post) do
          paginate :page => 3, :per_page => 30
        end
        expect(Sunspot.session).to_not have_search_params(:paginate, :page => 3, :per_page => 15)
      end

      it "does not match if page does not match" do
        Sunspot.search(Post) do
          paginate :page => 5, :per_page => 15
        end
        expect(Sunspot.session).to_not have_search_params(:paginate, :page => 3, :per_page => 15)
      end
    end

    describe "order_by matcher" do
      it "matches if search matches" do
        Sunspot.search(Post) do
          order_by :published_at, :desc
        end
        expect(Sunspot.session).to have_search_params(:order_by, :published_at, :desc)
      end

      it "does not match if search does not match" do
        Sunspot.search(Post) do
          order_by :published_at, :asc
        end
        expect(Sunspot.session).to_not have_search_params(:order_by, :published_at, :desc)
      end

      it "matches for multiple orderings" do
        Sunspot.search(Post) do
          order_by :published_at, :asc
          order_by :average_rating, :asc
        end
        expect(Sunspot.session).to have_search_params(:order_by) {
          order_by :published_at, :asc
          order_by :average_rating, :asc
        }
      end

      it "does not match if multiple orderings are reversed" do
        Sunspot.search(Post) do
          order_by :average_rating, :asc
          order_by :published_at, :asc
        end
        expect(Sunspot.session).to_not have_search_params(:order_by) {
          order_by :published_at, :asc
          order_by :average_rating, :asc
        }
      end

      it "matches when using random" do
        Sunspot.search(Post) do
          order_by :average_rating, :asc
          order_by :random
        end
        expect(Sunspot.session).to have_search_params(:order_by) {
          order_by :average_rating, :asc
          order_by :random
        }
      end

      it "does not match when random is missing" do
        Sunspot.search(Post) do
          order_by :average_rating, :asc
          order_by :random
        end
        expect(Sunspot.session).to_not have_search_params(:order_by) {
          order_by :average_rating, :asc
        }
      end

      it "matches when using score" do
        Sunspot.search(Post) do
          order_by :average_rating, :asc
          order_by :score
        end
        expect(Sunspot.session).to have_search_params(:order_by) {
          order_by :average_rating, :asc
          order_by :score
        }
      end

      it "does not match when score is missing" do
        Sunspot.search(Post) do
          order_by :average_rating, :asc
          order_by :score
        end
        expect(Sunspot.session).to_not have_search_params(:order_by) {
          order_by :average_rating, :asc
        }
      end

      it "works with any_param match on direction" do
        Sunspot.search(Post) do
          order_by :average_rating, :asc
        end
        expect(Sunspot.session).to have_search_params(:order_by, :average_rating, any_param)
      end

      it "works with any_param match on field" do
        Sunspot.search(Post) do
          order_by :average_rating, :asc
        end
        expect(Sunspot.session).to have_search_params(:order_by, any_param)
      end

      it "works with any_param negative match on direction" do
        Sunspot.search(Post) do
          order_by :score
        end
        expect(Sunspot.session).to_not have_search_params(:order_by, :average_rating, any_param)
      end

      it "works with any_param negative match on field" do
        Sunspot.search(Post) do
          keywords 'great pizza'
        end
        expect(Sunspot.session).to_not have_search_params(:order_by, any_param)
      end

      it "works with any_param match on field and direction" do
        Sunspot.search(Post) do
          order_by :score, :desc
        end
        expect(Sunspot.session).to have_search_params(:order_by, any_param, any_param)
      end

      it "works with any_param negative match on field and direction" do
        Sunspot.search(Post) do
          keywords 'great pizza'
        end
        expect(Sunspot.session).to_not have_search_params(:order_by, any_param, any_param)
      end
    end

    describe "facet matcher" do
      describe "field facets" do
        it "matches if facet exists" do
          Sunspot.search(Post) do
            facet :category_ids
          end
          expect(Sunspot.session).to have_search_params(:facet, :category_ids)
        end

        it "matches if multiple facet exists" do
          Sunspot.search(Post) do
            facet :category_ids
            facet :blog_id
          end
          expect(Sunspot.session).to have_search_params(:facet, :category_ids)
        end

        it "does not match if facet does not exist" do
          Sunspot.search(Post) do
            paginate :page => 5, :per_page => 15
          end
          expect(Sunspot.session).to_not have_search_params(:facet, :category_ids)
        end

        it "matches when excluding filters" do
          Sunspot.search(Post) do
            category_filter = with(:category_ids, 2)
            facet(:category_ids, :exclude => category_filter)
          end
          expect(Sunspot.session).to have_search_params(:facet) {
            category_filter = with(:category_ids, 2)
            facet(:category_ids, :exclude => category_filter)
          }
        end
      end

      describe "query facets" do
        it "matches if facet exists" do
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
          expect(Sunspot.session).to have_search_params(:facet) {
            facet(:average_rating) do
              row(1.0..2.0) do
                with(:average_rating, 1.0..2.0)
              end
              row(2.0..3.0) do
                with(:average_rating, 2.0..3.0)
              end
            end
          }
        end

        it "matches if multiple facet exists, but the facet you are matching on only has a single row" do
          Sunspot.search(Post) do
            facet(:average_rating) do
              row(1.0..2.0) do
                with(:average_rating, 1.0..2.0)
              end
            end

            facet(:popularity) do
              row(1..5) do
                with(:popularity, 1..5)
              end
              row(6..10) do
                with(:popularity, 6..10)
              end
            end
          end
          expect(Sunspot.session).to have_search_params(:facet) {
            facet(:average_rating) do
              row(1.0..2.0) do
                with(:average_rating, 1.0..2.0)
              end
            end
          }
        end

        it "does not match if actual search is missing a facet" do
          Sunspot.search(Post) do
            facet(:average_rating) do
              row(1.0..2.0) do
                with(:average_rating, 1.0..2.0)
              end
            end
          end
          expect(Sunspot.session).to_not have_search_params(:facet) {
            facet(:average_rating) do
              row(1.0..2.0) do
                with(:average_rating, 1.0..2.0)
              end
              row(2.0..3.0) do
                with(:average_rating, 2.0..3.0)
              end
            end
          }
        end

        it "does not match if facet query is different" do
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
          expect(Sunspot.session).to_not have_search_params(:facet) {
            facet(:average_rating) do
              row(1.0..2.0) do
                with(:average_rating, 1.0..2.0)
              end
              row(2.0..3.0) do
                with(:average_rating, 2.0..4.0)
              end
            end
          }
        end
      end
    end

    describe "boost matcher" do
      it "matches if field boost matches" do
        Sunspot.search(Post) do
          keywords 'great pizza' do
            boost_fields :body => 2.0
          end
        end
        expect(Sunspot.session).to have_search_params(:boost) {
          keywords 'great pizza' do
            boost_fields :body => 2.0
          end
        }
      end

      it "does not match if field boost does not match" do
        Sunspot.search(Post) do
          keywords 'great pizza' do
            boost_fields :body => 2.0
          end
        end
        expect(Sunspot.session).to_not have_search_params(:boost) {
          keywords 'great pizza' do
            boost_fields :body => 3.0
          end
        }
      end

      it "matches if boost query matches" do
        Sunspot.search(Post) do
          keywords 'great pizza' do
            boost(2.0) do
              with :blog_id, 4
            end
          end
        end
        expect(Sunspot.session).to have_search_params(:boost) {
          keywords 'great pizza' do
            boost(2.0) do
              with :blog_id, 4
            end
          end
        }
      end

      it "does not match if boost query does not match" do
        Sunspot.search(Post) do
          keywords 'great pizza' do
            boost(2.0) do
              with :blog_id, 4
            end
          end
        end
        expect(Sunspot.session).to_not have_search_params(:boost) {
          keywords 'great pizza' do
            boost(2.0) do
              with :blog_id, 5
            end
          end
        }
      end

      it "matches if boost function matches" do
        Sunspot.search(Post) do
          keywords 'great pizza' do
            boost(function { sum(:average_rating, product(:popularity, 10)) })
          end
        end
        expect(Sunspot.session).to have_search_params(:boost) {
          keywords 'great pizza' do
            boost(function { sum(:average_rating, product(:popularity, 10)) })
          end
        }
      end

      it "does not match if boost function does not match" do
        Sunspot.search(Post) do
          keywords 'great pizza' do
            boost(function { sum(:average_rating, product(:popularity, 10)) })
          end
        end
        expect(Sunspot.session).to_not have_search_params(:boost) {
          keywords 'great pizza' do
            boost(function { sum(:average_rating, product(:popularity, 42)) })
          end
        }
      end
    end

    describe "group matcher" do
      it "matches if grouping a field" do
        Sunspot.search(Post) do
          keywords 'great pizza'
          group :author_name
        end
        expect(Sunspot.session).to have_search_params(:group, :author_name)
      end

      it "matches if grouping a field" do
        Sunspot.search(Post) do
          keywords 'great pizza'
        end
        expect(Sunspot.session).to_not have_search_params(:group, :author_name)
      end
    end

  end

  describe "be_a_search_for" do
    before do
      Sunspot.search(Post) do
        keywords 'great pizza'
      end
    end

    it "succeeds if the model is correct" do
      expect(Sunspot.session).to be_a_search_for(Post)
    end

    it "fails if the model is incorrect" do
      expect(Sunspot.session).to_not be_a_search_for(Blog)
    end

    describe "when searching for multiple models" do
      it "is true for both" do
        Sunspot.search([Post, Blog]) do
          keywords 'great pizza'
        end

        expect(Sunspot.session).to be_a_search_for(Post)
        expect(Sunspot.session).to be_a_search_for(Blog)
        expect(Sunspot.session).to_not be_a_search_for(Person)
      end
    end

    describe "with multiple searches" do
      it "allows you to choose the search" do
        Sunspot.search(Blog) do
          keywords 'bad pizza'
        end
        expect(Sunspot.session.searches.first).to be_a_search_for(Post)
        expect(Sunspot.session.searches.last).to be_a_search_for(Blog)
      end
    end
  end

  describe "have_searchable_field" do
    it "works with instances as well as classes" do
      expect(Post.new).to have_searchable_field(:body)
    end

    it "succeeds if the model has the given field" do
      expect(Post).to have_searchable_field(:body)
      expect(Post).to have_searchable_field(:author_name)
      expect(Post).to have_searchable_field(:blog_id)
    end

    it "fails if the model does not have the given field" do
      expect(Post).to_not have_searchable_field(:potato)
    end

    it "fails if the model does not have any searchable fields" do
      expect(Person).to_not have_searchable_field(:name)
    end
  end

  describe "have_been_indexed" do
    let(:post) {
      post = PersistentPost.new
      post.name = "foo"
      post.id = 1
      post
    }
    before(:each) do
      Sunspot.session.index(post)
    end
    it "works with instances" do
      expect(post).to have_been_indexed
    end

    it "works with classes" do
      expect(PersistentPost).to have_been_indexed
    end

    it "differentiates between classes" do
      expect(Post).not_to have_been_indexed
    end

    it "succeeds if the model has been indexed with the given field and value" do
      expect(post).to have_been_indexed.with_field(:name, "foo")
    end

    it "succeeds if the model has been indexed with the given field and the value is any_param" do
      expect(post).to have_been_indexed.with_field(:name, any_param)
    end

    it "fails if the model does not have the given field" do
      expect(post).not_to have_been_indexed.with_field(:potato, "foo")
    end

    it "fails if the model was not indexed with the given field" do
      expect(post).not_to have_been_indexed.with_field(:author_name, "foo")
    end

    it "fails if the model was not indexed with the given field and value" do
      expect(post).not_to have_been_indexed.with_field(:name, "bar")
    end

    it "fails if this specific instance of the model was not indexed with the given field" do
      second_post = PersistentPost.new
      second_post.id = 2
      Sunspot.session.index(second_post)

      expect(second_post).not_to have_been_indexed.with_field(:name, "foo")
    end
  end
end
