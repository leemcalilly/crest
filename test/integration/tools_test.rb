require "test_helper"

class ToolsTest < ActionDispatch::IntegrationTest
  test "the manifest reaches every page so tools follow the reader" do
    [ root_path, cycle_path("1994"), player_path("clint-dempsey"), sources_path ].each do |path|
      get path
      assert_response :success
      assert_select "script#model-context-manifest", count: 1
    end
  end

  test "the chart tools are advertised only where a chart is rendered" do
    get root_path
    assert_includes response.body, "plot_chart"

    get sources_path
    assert_not_includes response.body, "plot_chart",
      "sources has no chart, so offering plot_chart there would fail when called"
  end

  test "an agent browser is never turned away" do
    get root_path, headers: { "User-Agent" => "ChatGPT-Agent/1.0" }
    assert_response :success
  end

  test "each read tool's URL answers with the shape it promises" do
    get "/cycles/1994.json"
    assert_equal 97, response.parsed_body["record"]["played"]

    get "/players/clint-dempsey.json"
    body = response.parsed_body
    assert_equal 41, body["goals"]
    assert_nil body["caps"], "caps must be null, never zero — the data does not exist"
    assert body["caps_note"].present?

    get "/matches.json", params: { opponent: "Brazil", year: 1994 }
    assert_equal 1, response.parsed_body["count"]
  end

  test "the World Cup is never called the FIFA World Cup" do
    get "/cycles/1994.json"
    assert_includes response.body, "World Cup"
    assert_not_includes response.body, "FIFA"
  end
end
