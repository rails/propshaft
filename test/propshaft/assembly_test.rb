require "test_helper"
require "propshaft/assembly"
require "active_support/ordered_options"

class Propshaft::AssemblyTest < ActiveSupport::TestCase
  test "uses static resolver when manifest is present" do
    assembly = Propshaft::Assembly.new(ActiveSupport::OrderedOptions.new.tap { |config| 
      config.output_path = Pathname.new("#{__dir__}/../fixtures/output")
      config.prefix = "/assets"
    })

    assert assembly.resolver.is_a?(Propshaft::Resolver::Static)
  end

  test "uses dynamic resolver when manifest is missing" do
    assembly = Propshaft::Assembly.new(ActiveSupport::OrderedOptions.new.tap { |config| 
      config.output_path = Pathname.new("#{__dir__}/../fixtures/assets")
      config.prefix = "/assets"
    })

    assert assembly.resolver.is_a?(Propshaft::Resolver::Dynamic)
  end

  test "costly methods are memoized" do
    assembly = Propshaft::Assembly.new(ActiveSupport::OrderedOptions.new.tap { |config|
      config.output_path = Pathname.new("#{__dir__}/../fixtures/assets")
      config.prefix = "/assets"
    })

    assert_equal assembly.resolver.object_id, assembly.resolver.object_id
    assert_equal assembly.load_path.object_id, assembly.load_path.object_id
  end
end
