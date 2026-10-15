ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # One SQLite file. Index tests load JSON inside the test transaction.
    # Rows are not fixtures.
  end
end
