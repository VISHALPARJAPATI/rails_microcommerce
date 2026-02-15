ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Minitest 6 calls run(klass, method_name, reporter); Rails 8 LineFiltering expects run(reporter, options).
# Patch so both signatures work.
module Rails
  module LineFiltering
    def run(reporter = nil, options = nil, third = nil)
      if third
        Minitest::Runnable.run(reporter, options, third)
      else
        options = (options || {}).merge(filter: Rails::TestUnit::Runner.compose_filter(self, (options || {})[:filter]))
        super(reporter, options)
      end
    end
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
