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

# Support Sunspot random field in test -- Sunspot originally generate a random number for the field
class Sunspot::Query::Sort::RandomSort < Sunspot::Query::Sort::Abstract
  def to_param
    "random #{direction_for_solr}"
  end
end