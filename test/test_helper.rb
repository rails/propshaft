require "minitest/autorun"
require "rails"
require "rails/test_help"
require "debug"

class ActiveSupport::TestCase
  def find_asset(logical_path)
    root_path = Pathname.new("#{__dir__}/fixtures/assets/first_path")
    path = root_path.join(logical_path)
    Propshaft::Asset.new(path, logical_path: logical_path)
  end
end
