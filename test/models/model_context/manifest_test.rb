require "test_helper"

class ModelContext::ManifestTest < ActiveSupport::TestCase
  setup { @tools = ModelContext::Manifest.new.tools }

  test "every tool describes itself for a model that knows nothing" do
    @tools.each do |tool|
      assert tool.description.length > 60, "#{tool.name} needs a fuller description"
      assert_match(/\A[a-z_]+\z/, tool.name)
    end
  end

  test "read tools point at the site's own URLs, never a separate API" do
    reads = @tools.select { it.kind == :read }
    assert reads.any?
    reads.each do |tool|
      assert tool.action.start_with?("/"), "#{tool.name} should call a page URL"
      assert_not tool.action.start_with?("/api"), "crest has no /api namespace"
      assert tool.read_only
    end
  end

  test "page tools act on the browser and name no URL" do
    pages = @tools.select { it.kind == :page }
    assert_equal %w[ set_cycle highlight_cycle plot_cycles filter_by_opponent read_current_page ],
                 pages.map(&:name)
    pages.each { assert_not it.action.start_with?("/") }
  end

  test "tools that move the page are not marked read-only" do
    assert_not @tools.find { it.name == "set_cycle" }.read_only
    assert @tools.find { it.name == "read_current_page" }.read_only
  end

  test "the measures a tool offers are the measures the model computes" do
    enum = @tools.find { it.name == "plot_cycles" }.schema.dig(:metric, :enum)
    assert_equal Cycle::METRICS.keys, enum
    assert_equal Cycle.first.metrics.keys.map(&:to_s).sort, enum.sort
  end

  test "required arguments reach the schema" do
    schema = @tools.find { it.name == "read_cycle" }.as_json[:inputSchema]
    assert_equal [ :cycle ], schema[:required]
    assert_equal false, schema[:additionalProperties]
  end
end
