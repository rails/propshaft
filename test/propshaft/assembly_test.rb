require "test_helper"
require "propshaft/assembly"
require "active_support/ordered_options"

class Propshaft::AssetTest < ActiveSupport::TestCase
  test "uses static resolver when manifest is present" do
    assembly = Propshaft::Assembly.new(ActiveSupport::OrderedOptions.new.tap { |config| 
      config.output_path = Pathname.new("#{__dir__}/../fixtures/output")
      config.manifest_filename = "manifest.json"
      config.prefix = "/assets"
    })

    assert assembly.resolver.is_a?(Propshaft::Resolver::Static)
  end

  test "uses dynamic resolver when manifest is missing" do
    assembly = Propshaft::Assembly.new(ActiveSupport::OrderedOptions.new.tap { |config| 
      config.output_path = Pathname.new("#{__dir__}/../fixtures/output")
      config.manifest_filename = "not-a-manifest.json"
      config.prefix = "/assets"
    })

    assert assembly.resolver.is_a?(Propshaft::Resolver::Dynamic)
  end
end
