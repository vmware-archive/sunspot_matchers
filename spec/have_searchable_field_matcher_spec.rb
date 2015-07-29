require 'sunspot'
require 'sunspot_matchers'
require 'rspec'

describe SunspotMatchers::HaveSearchableField do
  class NotALotGoingOn; end
  class IndexedWithWrongThings; end

  let(:matcher) do
    described_class.new(:field).tap do |matcher|
      matcher.matches? klass
    end
  end

  context "when a class has no searchable fields" do
    let(:klass) { NotALotGoingOn }

    it "gives Sunspot configuration error" do
      expect(matcher.failure_message).to match(/Sunspot was not configured/)
    end
  end

  context "when a class has an unexpected searchable field" do
    let(:klass) { IndexedWithWrongThings }
    before do
      Sunspot.setup(klass) { text :parachute }
    end

    it "does not have an error" do
      expect(matcher.failure_message).to be_nil
    end
  end
end
