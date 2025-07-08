require "test_helper"

class PropshaftIntegrationTest < ActionDispatch::IntegrationTest
  test "should be able to resolve real assets" do
    get sample_load_real_assets_url

    assert_response :success

    assert_select 'link[href="/assets/hello_world-4137140a.css"][data-custom-attribute="true"]'
    assert_select 'link[href="/assets/goodbye-b1dc9940.css"][data-custom-attribute="true"]'
    assert_select 'link[href="/assets/library-86a3b7a9.css"][data-custom-attribute="true"]'

    hello_css_link = css_select('link[href="/assets/hello_world-4137140a.css"][integrity]').first
    assert(hello_css_link)
    assert_equal "stylesheet", hello_css_link["rel"]
    assert_equal "sha384-ZSAt6UaTZ1OYvSB1fr2WXE8izMW4qnd17BZ1zaZ3TpAdIw3VEUmyupHd/k/cMCqM", hello_css_link["integrity"]

    hello_js_script = css_select('script[src="/assets/hello_world-888761f8.js"]').first
    assert(hello_js_script)
    assert_equal "sha384-BIr0kyMRq2sfytK/T0XlGjfav9ZZrWkSBC2yHVunCchnkpP83H28/UtHw+m9iNHO", hello_js_script["integrity"]
  end

  test "should prioritize app assets over engine assets" do
    get sample_load_real_assets_url

    assert_select 'script[src="/assets/actioncable-2e7de4f9.js"]'
  end

  test "should find app styles via glob" do
    get sample_load_real_assets_url

    assert_select 'link[href="/assets/hello_world-4137140a.css"][data-glob-attribute="true"]'
    assert_select 'link[href="/assets/goodbye-b1dc9940.css"][data-glob-attribute="true"]'
    assert_select('link[href="/assets/library-86a3b7a9.css"][data-glob-attribute="true"]', count: 0)
  end

  test "should raise an exception when resolving nonexistent assets" do
    exception = assert_raises ActionView::Template::Error do
      get sample_load_nonexistent_assets_url
    end
    assert_equal "The asset 'nonexistent.css' was not found in the load path.", exception.message
  end
end
