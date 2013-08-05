module SunspotMatchers
  class SunspotSearchSpy < Sunspot::Search::StandardSearch
    def execute
      self
    end
    def solr_response
      {}
    end
    def facet_response
      {'facet_queries' => {}}
    end
  end

  class SunspotSessionSpy < Sunspot::Session
    attr_reader :original_session
    attr_reader :current_search_class

    attr_accessor :searches

    def initialize(original_session)
      # Support Sunspot random field in test -- Sunspot originally generate a random number for the field
      # Only patch method if SunspotSessionSpy is initialized to prevent poisoning class simply by being included in Gemfile.
      Sunspot::Query::Sort::RandomSort.class_eval do
        define_method :to_param do
          "random #{direction_for_solr}"
        end
      end

      @searches = []
      @original_session = original_session
      @config = Sunspot::Configuration.build
    end

    def inspect
      'Solr Search'
    end

    def index(*objects)
    end

    def index!(*objects)
    end

    def remove(*objects)
    end

    def remove!(*objects)
    end

    def remove_by_id(clazz, id)
    end

    def remove_by_id!(clazz, id)
    end

    def remove_all(clazz = nil)
    end

    def remove_all!(clazz = nil)
    end

    def dirty?
      false
    end

    def delete_dirty?
      false
    end

    def commit_if_dirty
    end

    def commit_if_delete_dirty
    end

    def commit
    end

    def search(*types, &block)
      new_search(*types, &block)
    end

    def new_search(*types, &block)
      types.flatten!
      search = build_search(*types, &block)
      @searches << [types, search]
      search
    end

    def build_search(*types, &block)
      types.flatten!
      search = SunspotSearchSpy.new(
        nil,
        setup_for_types(types),
        Sunspot::Query::StandardQuery.new(types),
        @config
      )
      search.build(&block) if block
      search
    end

    def setup_for_types(types)
      if types.empty?
        raise(ArgumentError, "You must specify at least one type to search")
      end
      if types.length == 1
        Sunspot::Setup.for(types.first)
      else
        Sunspot::CompositeSetup.for(types)
      end
    end
  end
end