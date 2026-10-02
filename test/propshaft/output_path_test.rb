# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "propshaft/asset"
require "propshaft/load_path"
require "propshaft/manifest"
require "propshaft/output_path"

class Propshaft::OutputPathTest < ActiveSupport::TestCase
  setup do
    @manifest = Propshaft::Manifest.new
    add_to_manifest ".manifest.json", ".manifest.json"
    add_to_manifest "one.txt", "one-f2e1ec14.txt"
    add_to_manifest "one.txt.map", "one-f2e1ec15.txt.map"
    @output_path = Propshaft::OutputPath.new(Pathname.new("#{__dir__}/../fixtures/output"), @manifest)
  end

  test "files" do
    files = @output_path.files

    file = files["one-f2e1ec14.txt"]
    assert_equal "one.txt", file[:logical_path]
    assert_equal "f2e1ec14", file[:digest]
    assert file[:mtime].is_a?(Time)
  end

  test "clean always keeps most current versions" do
    @output_path.clean(0, 0)
    assert File.exist?(@output_path.path.join(@manifest["one.txt"].digested_path))
    assert File.exist?(@output_path.path.join(@manifest[".manifest.json"].digested_path))
  end

  test "clean keeps the current version when newer versions exist" do
    current = output_asset("by_restore.txt", "current", created_at: Time.now - 300)
    newer   = output_asset("by_restore.txt", "newer", created_at: Time.now - 180)
    newest  = output_asset("by_restore.txt", "newest", created_at: Time.now - 120)
    add_to_manifest "by_restore.txt", current.basename.to_s

    @output_path.clean(1, 0)

    assert File.exist?(current)
    assert File.exist?(newest)
    assert_not File.exist?(newer)
  ensure
    [ current, newer, newest ].each { |file| FileUtils.rm(file) if file && File.exist?(file) }
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

  test "clean keeps the correct number of versions regardless of the file extension" do
    old     = output_asset("by_count.txt.map", "old", created_at: Time.now - 300)
    current = output_asset("by_count.txt.map", "current", created_at: Time.now - 180)

    assert File.exist?(current)
    assert File.exist?(old)

    @output_path.clean(1, 0)

    assert File.exist?(current)
    assert_not File.exist?(old), "#{old} should not exist"
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
    def add_to_manifest(logical_path, digested_path)
      @manifest.push Propshaft::Manifest::ManifestEntry.new(logical_path: logical_path, digested_path: digested_path, integrity: nil)
    end

    def output_asset(filename, content, created_at: Time.now)
      load_path = Propshaft::LoadPath.new([], compilers: Propshaft::Compilers.new(nil))
      asset = Propshaft::Asset.new(nil, logical_path: filename, load_path: load_path)
      asset.stub :content, content do
        output_path = @output_path.path.join(asset.digested_path)
        `touch -mt #{created_at.strftime("%y%m%d%H%M")} #{output_path}`
        output_path
      end
    end
end
