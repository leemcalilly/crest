require "test_helper"

# A Stimulus controller that assigns to a reserved Controller property breaks
# every target helper and every action on it — silently, at runtime, in the
# browser only. crest hit this once: `this.context = …` broke all seven tools
# while discovery still looked healthy. Nothing in Ruby can catch it, so it is
# caught here as text.
class JavascriptConventionsTest < ActiveSupport::TestCase
  RESERVED = %w[ context application scope element identifier targets classes data ].freeze

  test "no Stimulus controller assigns to a reserved Controller property" do
    Dir[Rails.root.join("app/javascript/controllers/*_controller.js")].each do |path|
      source = File.read(path)
      RESERVED.each do |name|
        assert_no_match(/this\.#{name}\s*=[^=]/, source,
          "#{File.basename(path)} assigns to this.#{name}, which Stimulus owns")
      end
    end
  end
end
