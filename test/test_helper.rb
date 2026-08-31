ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

# crest is a read-only site built from one open dataset, so the suite runs
# against the real import rather than invented fixtures. Seed once per run.
if Match.count.zero?
  Rails.application.load_tasks
  Rake::Task["crest:import"].invoke
end
