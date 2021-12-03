require "minitest/autorun"
require "rails"
require "rails/test_help"
require "debug"

require "propshaft"

Propshaft.logger = Logger.new("/dev/null")

class ActiveSupport::TestCase
  private
    def find_asset(logical_path, fixture_path:)
      root_path = Pathname.new("#{__dir__}/fixtures/assets/#{fixture_path}")
      path = root_path.join(logical_path)
      Propshaft::Asset.new(path, logical_path: logical_path)
    end
end
