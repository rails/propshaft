require "test_helper"
require "minitest/mock"
require "propshaft/asset"
require "propshaft/load_path"
require "propshaft/output_path"

class Propshaft::OutputPathTest < ActiveSupport::TestCase
  setup do
    @manifest    = {
      ".manifest.json": ".manifest.json",
      "one.txt": "one-f2e1ec14d6856e1958083094170ca6119c529a73.txt"
    }.stringify_keys
    @output_path = Propshaft::OutputPath.new(Pathname.new("#{__dir__}/../fixtures/output"), @manifest)
  end

  test "files" do
    files = @output_path.files

    file = files["one-f2e1ec14d6856e1958083094170ca6119c529a73.txt"]
    assert_equal "one.txt", file[:logical_path]
    assert_equal "f2e1ec14d6856e1958083094170ca6119c529a73", file[:digest]
    assert file[:mtime].is_a?(Time)
  end

  test "clean always keeps most current versions" do
    @output_path.clean(0, 0)
    assert @output_path.path.join(@manifest["one.txt"])
    assert @output_path.path.join(@manifest[".manifest.json"])
  end

  test "clean keeps versions of assets that no longer exist" do
    removed = output_asset("no-longer-in-manifest.txt", "current")
    @output_path.clean(1, 0)
    assert File.exist?(removed)
  ensure
    FileUtils.rm(removed) if File.exist?(removed)
  end

  test "clean keeps the correct number of versions" do
    old     = output_asset("by_count.txt", "old", created_at: Time.now - 300)
    current = output_asset("by_count.txt", "current", created_at: Time.now - 180)

    @output_path.clean(1, 0)

    assert File.exist?(current)
    assert_not File.exist?(old)
  ensure
    FileUtils.rm(old) if File.exist?(old)
    FileUtils.rm(current) if File.exist?(current)
  end

  test "clean keeps all versions under a certain age" do
    old     = output_asset("by_age.txt", "old")
    current = output_asset("by_age.txt", "current")

    @output_path.clean(0, 3600)

    assert File.exist?(current)
    assert File.exist?(old)
  ensure
    FileUtils.rm(old) if File.exist?(old)
    FileUtils.rm(current) if File.exist?(current)
  end

  private
    def output_asset(filename, content, created_at: Time.now)
      asset = Propshaft::Asset.new(nil, logical_path: filename)
      asset.stub :content, content do
        output_path = @output_path.path.join(asset.digested_path)
        `touch -mt #{created_at.strftime('%y%m%d%H%M')} #{output_path}`
        output_path
      end
    end
end
