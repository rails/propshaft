# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
require "rails/test_help"

require "rails/test_unit/reporter"
Rails::TestUnitReporter.executable = "bin/test"

class ActiveSupport::TestCase
  private
    def find_asset(logical_path, fixture_path:)
      root_path = Pathname.new("#{__dir__}/fixtures/assets/#{fixture_path}")
      path = root_path.join(logical_path)
      Propshaft::Asset.new(path, logical_path: logical_path)
    end
end
