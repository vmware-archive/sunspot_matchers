require 'sunspot'
require 'sunspot_matchers'
require 'rspec'

describe SunspotMatchers::HaveSearchableField do
  let(:matcher) do
    described_class.new(:field).tap do |matcher|
      matcher.matches? klass
    end
  end

  context "when a class has no searchable fields" do
    let(:klass) { NotALotGoingOn = Class.new }

    it "gives Sunspot configuration error" do
      expect(matcher.failure_message_for_should).to match(/Sunspot was not configured/)
    end
  end

  context "when a class has an unexpected searchable field" do
    let(:klass) { IndexedWithWrongThings = Class.new }
    before do
      Sunspot.setup(klass) { text :parachute }
    end

    it "does not have an error" do
      expect(matcher.failure_message_for_should).to be_nil
    end
  end
end
