require "test_helper"

# The repeatable test is written once, in ToolsController::STEPS, and mirrored
# in the submission document so a judge can read it without running the site.
# A copy that nobody checks drifts, and a submission that contradicts the live
# page is worse than no submission. So the copy is checked here.
class WebmcpChallengeTest < ActiveSupport::TestCase
  DOCUMENT = Rails.root.join("WEBMCP-CHALLENGE.md")

  test "the challenge document mirrors every step in the controller" do
    rows = steps_in_document

    assert_equal ToolsController::STEPS.length, rows.length,
      "WEBMCP-CHALLENGE.md lists #{rows.length} steps and the controller defines " \
      "#{ToolsController::STEPS.length}"

    ToolsController::STEPS.each_with_index do |(ask, expectation), i|
      assert_equal ask, rows[i][:ask],
        "step #{i + 1} is asked differently in WEBMCP-CHALLENGE.md"
      assert_equal as_prose(expectation), rows[i][:expectation],
        "step #{i + 1} promises something different in WEBMCP-CHALLENGE.md"
    end
  end

  private
    # The "Try it yourself" table, whose rows read: | # | Ask | Happens | Tool |
    def steps_in_document
      DOCUMENT.readlines.filter_map do |line|
        cells = line.strip.split("|").map(&:strip)
        next unless cells.length == 5 && cells[1].match?(/\A\d+\z/)
        { ask: cells[2].delete_prefix('*"').delete_suffix('"*'), expectation: cells[3] }
      end
    end

    # The controller writes for a web page: HTML entities, and the tool name
    # marked up at the end. The document is Markdown and names the tool in a
    # column of its own.
    def as_prose(expectation)
      expectation.sub(%r{\s*<em>.+</em>\z}, "").gsub("&ndash;", "–").gsub("&mdash;", "—")
    end
end
