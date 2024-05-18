# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
Warning[:deprecated] = true
$VERBOSE = true

require_relative "../test/dummy/config/environment"
require "rails/test_help"

require "rails/test_unit/reporter"
Rails::TestUnitReporter.executable = "bin/test"

class ActiveSupport::TestCase
  private
    def find_asset(logical_path, fixture_path:)
      root_path = Pathname.new("#{__dir__}/fixtures/assets/#{fixture_path}")
      path = root_path.join(logical_path)
      load_path = Propshaft::LoadPath.new([ root_path ], compilers: Propshaft::Compilers.new(nil))

      Propshaft::Asset.new(path, logical_path: logical_path, load_path: load_path)
    end
end
