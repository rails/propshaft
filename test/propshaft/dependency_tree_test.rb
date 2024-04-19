require "test_helper"
require "minitest/mock"
require "propshaft/asset"
require "propshaft/assembly"
require "propshaft/compilers"

class Propshaft::DependencyTreeTest < ActiveSupport::TestCase
  setup do
    @assembly = Propshaft::Assembly.new(ActiveSupport::OrderedOptions.new.tap { |config|
      config.paths = [ Pathname.new("#{__dir__}/../fixtures/assets/dependent") ]
      config.output_path = Pathname.new("#{__dir__}/../fixtures/output")
      config.prefix = "/assets"
    })
    @assembly.compilers.register "text/css", Propshaft::Compiler::CssAssetUrls
  end

  test "cyclic assets do not cause a loop" do
    @assembly.load_path.assets
  end

  def write_child2(col)
    File.open("#{__dir__}/../fixtures/assets/dependent/child2.css", "w") do |file|
      file.puts "p { background: #{col}; }"
    end
  end

  test "modification of a child affects dependent asset digests" do
    write_child2('blue')    # ensure no leftovers from previous runs
    prev_assets = @assembly.load_path.assets
    prev_main_digest = prev_assets.detect{|a| a.logical_path.to_s == 'main.css'}.digest
    write_child2('red')
    @assembly.load_path.cache_sweeper.execute
    changed_assets = @assembly.load_path.assets
    changed_main_digest = changed_assets.detect{|a| a.logical_path.to_s == 'main.css'}.digest
    assert_not_equal(prev_main_digest, changed_main_digest)
    write_child2('blue')    # restore the original
    @assembly.load_path.cache_sweeper.execute
    final_assets = @assembly.load_path.assets
    final_main_digest = final_assets.detect{|a| a.logical_path.to_s == 'main.css'}.digest
    assert_equal(prev_main_digest, final_main_digest)
  end
end
