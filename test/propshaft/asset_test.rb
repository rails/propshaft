require "test_helper"
require "propshaft/asset"

class Propshaft::AssetTest < ActiveSupport::TestCase
  test "content" do
    assert_equal "One from first path", find_asset("one.txt").content
  end

  test "length" do
    assert_equal 19, find_asset("one.txt").length
  end

  test "digest" do
    assert_equal "f2e1ec14d6856e1958083094170ca6119c529a73", find_asset("one.txt").digest
  end

  test "digested path" do
    assert_equal "one-f2e1ec14d6856e1958083094170ca6119c529a73.txt",
      find_asset("one.txt").digested_path
  end

  test "value object equality" do
    assert_equal find_asset("one.txt"), find_asset("one.txt")
  end

  private
    def find_asset(logical_path)
      path = Pathname.new("#{__dir__}/../assets/first_path/#{logical_path}")
      Propshaft::Asset.new(path, logical_path: logical_path)
    end
end
