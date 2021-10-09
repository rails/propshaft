# Benchmark file for the CssAssetUrls compiler
#
# It will download the free "StartBootstrap" theme to a temporary
# folder and execute the compiler on it.
#
# Execute the the command below from the gems root folder.
#
# irb -I ./lib -r propshaft benchmarks/css_asset_urls.rb

require "rails"
require "rails/railtie"
require "active_support/ordered_options"
require "benchmark/ips"
require "open-uri"

dir = Dir.mktmpdir
file = URI.parse("https://github.com/StartBootstrap/startbootstrap-new-age/archive/refs/heads/master.zip").open

system("unzip #{file.path} -d #{dir}")

assets = ActiveSupport::OrderedOptions.new
assets.paths = [dir + "/startbootstrap-new-age-master/dist"]
assets.prefix = "/assets"
assets.compilers = [["text/css", Propshaft::Compilers::CssAssetUrls]]

assembly = Propshaft::Assembly.new(assets)
asset = assembly.load_path.find("css/styles.css")
compiler = Propshaft::Compilers::CssAssetUrls.new(assembly)

contents = []
10_000.times { contents << asset.content.dup }

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)
  x.report("compile") { compiler.compile(asset.logical_path, contents.pop) }
end ; nil
