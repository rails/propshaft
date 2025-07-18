require "test_helper"

class Propshaft::HelperTest < ActionView::TestCase
  test "asset_integrity returns SHA256 hash for existing asset" do
    integrity = asset_integrity("hello_world.js")
    assert_equal "sha384-BIr0kyMRq2sfytK/T0XlGjfav9ZZrWkSBC2yHVunCchnkpP83H28/UtHw+m9iNHO", integrity
  end

  test "asset_integrity with asset type option" do
    integrity = asset_integrity("hello_world", type: :stylesheet)
    assert_equal "sha384-ZSAt6UaTZ1OYvSB1fr2WXE8izMW4qnd17BZ1zaZ3TpAdIw3VEUmyupHd/k/cMCqM", integrity
  end

  test "compute_asset_path returns resolved path for existing asset" do
    path = compute_asset_path("hello_world.js")
    assert_equal "/assets/hello_world-888761f8.js", path
  end

  test "compute_asset_path raises MissingAssetError for nonexistent asset" do
    error = assert_raises(Propshaft::MissingAssetError) do
      compute_asset_path("nonexistent.txt")
    end
    assert_equal "The asset 'nonexistent.txt' was not found in the load path.", error.message
  end

  test "stylesheet_link_tag with integrity in secure context" do
    request.headers["HTTPS"] = "on"

    result = stylesheet_link_tag("hello_world", integrity: true)

    assert_dom_equal(<<~HTML, result)
      <link
        rel="stylesheet"
        href="/assets/hello_world-4137140a.css"
        integrity="sha384-ZSAt6UaTZ1OYvSB1fr2WXE8izMW4qnd17BZ1zaZ3TpAdIw3VEUmyupHd/k/cMCqM"
      />
    HTML
  end

  test "stylesheet_link_tag with integrity in local context" do
    request.remote_addr = "127.0.0.1"

    result = stylesheet_link_tag("hello_world", integrity: true)

    assert_dom_equal(<<~HTML, result)
      <link
        rel="stylesheet"
        href="/assets/hello_world-4137140a.css"
        integrity="sha384-ZSAt6UaTZ1OYvSB1fr2WXE8izMW4qnd17BZ1zaZ3TpAdIw3VEUmyupHd/k/cMCqM"
      />
    HTML
  end

  test "stylesheet_link_tag without integrity in insecure context" do
    result = stylesheet_link_tag("hello_world", integrity: true)

    assert_dom_equal(<<~HTML, result)
      <link
        rel="stylesheet"
        href="/assets/hello_world-4137140a.css"
      />
    HTML
  end

  test "stylesheet_link_tag without request context" do
    request.remote_addr = "127.0.0.1"
    @request = nil

    result = stylesheet_link_tag("hello_world", integrity: true)

    assert_dom_equal(<<~HTML, result)
      <link
        rel="stylesheet"
        href="/assets/hello_world-4137140a.css"
      />
    HTML
  end

  test "stylesheet_link_tag with multiple sources and integrity" do
    request.headers["HTTPS"] = "on"

    result = stylesheet_link_tag("hello_world", "goodbye", integrity: true)

    assert_dom_equal(<<~HTML, result)
      <link
        rel="stylesheet"
        href="/assets/hello_world-4137140a.css"
        integrity="sha384-ZSAt6UaTZ1OYvSB1fr2WXE8izMW4qnd17BZ1zaZ3TpAdIw3VEUmyupHd/k/cMCqM"
      />
      <link
        rel="stylesheet"
        href="/assets/goodbye-b1dc9940.css"
        integrity="sha384-fdjPDIC6emuy5FFidLaq2BgRhq3H1f7Cukj0jMOA8yltqt7kFKylYD+MjrkdZ7Ji"
      />
    HTML
  end

  test "stylesheet_link_tag with :all option" do
    result = stylesheet_link_tag(:all)

    assert_dom_equal(<<~HTML, result)
      <link rel="stylesheet" href="/assets/goodbye-b1dc9940.css" />
      <link rel="stylesheet" href="/assets/hello_world-4137140a.css" />
      <link rel="stylesheet" href="/assets/library-86a3b7a9.css" />
    HTML
  end

  test "stylesheet_link_tag with :app option" do
    result = stylesheet_link_tag(:app)

    assert_dom_equal(<<~HTML, result)
      <link rel="stylesheet" href="/assets/goodbye-b1dc9940.css" />
      <link rel="stylesheet" href="/assets/hello_world-4137140a.css" />
    HTML
  end

  test "stylesheet_link_tag with additional options" do
    result = stylesheet_link_tag(
      "hello_world",
      media: "print",
      data: { turbo_track: "reload" }
    )

    assert_dom_equal(<<~HTML, result)
      <link
        rel="stylesheet"
        href="/assets/hello_world-4137140a.css"
        media="print"
        data-turbo-track="reload"
      />
    HTML
  end

  test "stylesheet_link_tag should extract options from the sources" do
    result = stylesheet_link_tag(
      "hello_world",
      {
        media: "print",
        data: { turbo_track: "reload" }
      }
    )

    assert_dom_equal(<<~HTML, result)
      <link
        rel="stylesheet"
        href="/assets/hello_world-4137140a.css"
        media="print"
        data-turbo-track="reload"
      />
    HTML
  end

  test "javascript_include_tag with integrity in secure context" do
    request.headers["HTTPS"] = "on"

    result = javascript_include_tag("hello_world", integrity: true)

    assert_dom_equal(<<~HTML, result)
      <script
        src="/assets/hello_world-888761f8.js"
        integrity="sha384-BIr0kyMRq2sfytK/T0XlGjfav9ZZrWkSBC2yHVunCchnkpP83H28/UtHw+m9iNHO"
      ></script>
    HTML
  end

  test "javascript_include_tag with integrity in local context" do
    request.remote_addr = "127.0.0.1"

    result = javascript_include_tag("hello_world", integrity: true)

    assert_dom_equal(<<~HTML, result)
      <script
        src="/assets/hello_world-888761f8.js"
        integrity="sha384-BIr0kyMRq2sfytK/T0XlGjfav9ZZrWkSBC2yHVunCchnkpP83H28/UtHw+m9iNHO"
      ></script>
    HTML
  end

  test "javascript_include_tag without integrity in insecure context" do
    result = javascript_include_tag("hello_world", integrity: true)

    assert_dom_equal(<<~HTML, result)
      <script
        src="/assets/hello_world-888761f8.js"
      ></script>
    HTML
  end

  test "javascript_include_tag with multiple sources and integrity" do
    request.headers["HTTPS"] = "on"

    result = javascript_include_tag("hello_world", "hello_world", integrity: true)

    assert_dom_equal(<<~HTML, result)
      <script
        src="/assets/hello_world-888761f8.js"
        integrity="sha384-BIr0kyMRq2sfytK/T0XlGjfav9ZZrWkSBC2yHVunCchnkpP83H28/UtHw+m9iNHO"
      ></script>
      <script
        src="/assets/hello_world-888761f8.js"
        integrity="sha384-BIr0kyMRq2sfytK/T0XlGjfav9ZZrWkSBC2yHVunCchnkpP83H28/UtHw+m9iNHO"
      ></script>
    HTML
  end

  test "javascript_include_tag with additional options" do
    result = javascript_include_tag(
      "hello_world",
      defer: true,
      data: { turbo_track: "reload" }
    )

    assert_dom_equal(<<~HTML, result)
      <script
        src="/assets/hello_world-888761f8.js"
        defer="defer"
        data-turbo-track="reload"
      ></script>
    HTML
  end

  test "javascript_include_tag should extract options from the sources" do
    result = javascript_include_tag(
      "hello_world",
      {
        defer: true,
        data: { turbo_track: "reload" }
      }
    )

    assert_dom_equal(<<~HTML, result)
      <script
        src="/assets/hello_world-888761f8.js"
        defer="defer"
        data-turbo-track="reload"
      ></script>
    HTML
  end

  test "all_stylesheets_paths returns array of CSS asset paths" do
    paths = all_stylesheets_paths

    assert_equal(
      [
        "goodbye.css",
        "hello_world.css",
        "library.css"
      ],
      paths
    )
  end

  test "app_stylesheets_paths returns array of app CSS asset paths" do
    paths = app_stylesheets_paths

    assert_equal(
      [
        "goodbye.css",
        "hello_world.css"
      ],
      paths
    )
  end

  test "asset_integrity handles file extensions correctly" do
    integrity1 = asset_integrity("hello_world.css")

    integrity2 = asset_integrity("hello_world", type: :stylesheet)

    assert_equal integrity1, integrity2
  end

  test "integrity option false explicitly disables integrity" do
    request.headers["HTTPS"] = "on"

    result = stylesheet_link_tag("hello_world", integrity: false)

    assert_dom_equal(<<~HTML, result)
      <link
        rel="stylesheet"
        href="/assets/hello_world-4137140a.css"
      />
    HTML
  end

  test "integrity option nil does not enable integrity" do
    request.headers["HTTPS"] = "on"

    result = stylesheet_link_tag("hello_world", integrity: nil)

    assert_dom_equal(<<~HTML, result)
      <link
        rel="stylesheet"
        href="/assets/hello_world-4137140a.css"
      />
    HTML
  end
end
