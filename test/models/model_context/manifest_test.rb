require "test_helper"

class ModelContext::ManifestTest < ActiveSupport::TestCase
  setup { @tools = ModelContext::Manifest.new(page: "home").tools }

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
    assert_equal %w[ set_cycle highlight_cycle plot_chart read_current_page ], pages.map(&:name)
    pages.each { assert_not it.action.start_with?("/") }
  end

  test "tools that move the page are not marked read-only" do
    assert_not @tools.find { it.name == "set_cycle" }.read_only
    assert @tools.find { it.name == "read_current_page" }.read_only
  end

  test "a tool is only offered on a page where it can work" do
    on_chart = ModelContext::Manifest.new(page: "home").tools.map(&:name)
    elsewhere = ModelContext::Manifest.new(page: "sources").tools.map(&:name)

    assert_includes on_chart, "plot_chart"
    assert_includes on_chart, "highlight_cycle"
    assert_not_includes elsewhere, "plot_chart", "a page with no chart must not offer to draw one"
    assert_not_includes elsewhere, "highlight_cycle"

    # Navigation and reading follow the reader everywhere.
    assert_includes elsewhere, "set_cycle"
    assert_includes elsewhere, "read_player"
    assert_includes elsewhere, "read_current_page"
  end

  test "the views and measures a tool offers are the ones the chart can draw" do
    schema = @tools.find { it.name == "plot_chart" }.schema
    assert_equal Chart::VIEWS.keys, schema.dig(:view, :enum)
    assert_equal Chart::METRICS.keys, schema.dig(:metric, :enum)
  end

  test "required arguments reach the schema" do
    schema = @tools.find { it.name == "read_cycle" }.as_json[:inputSchema]
    assert_equal [ :cycle ], schema[:required]
    assert_equal false, schema[:additionalProperties]
  end
end
