# Propshaft

Propshaft is an asset pipeline library for Rails. It's built for era where bundling assets to save on HTTP connections is no longer urgent, where JavaScript and CSS is either compiled by dedicated Node.js bundlers or served directly to the browsers, and where increases in bandwidth has made the need for minification less pressing. These factors allow for a dramatically simpler and faster asset pipeline compared to previous options, like Sprockets.

So that's what Propshaft doesn't do. Here's what it actually does provide:

1. Configurable load path: You can register directories from multiple places in your app and gems, and reference assets from all of these paths as though they were one.
1. Digest processing: All assets in the load path will be copied (or compiled) in a precompilation step for production that also stamps all of them with a digest hash, so you can use long-expiry cache headers for better performance. The digested assets can be referred to through their logical path because the processing leaves a manifest file that provides a way to translate.
1. Development server: There's no need to precompile the assets in development. You can refer to them via the same asset_path helpers and they'll be served by a development server.
1. Basic compiler step: Propshaft was explicitly not designed to provide full transpiler capabilities. You can get that better elsewhere. But it does offer a simple input->output compiler setup that by default is used to translate `asset-path` function calls in CSS to `url(digested-asset)` instead.


## Installation

With Rails 7+, you can start a new application with propshaft using `rails new myapp -a propshaft`.


## Usage

...


## Migrating from Sprockets

Propshaft does a lot less than Sprockets, by design, so it might well be a fair bit of work to migrate, if it's even desirable. This is particularly true if you rely on Sprockets to provide any form of transpiling, like CoffeeScript or Sass, or if you rely on any gems that do. You'll need to either stop transpiling or use a Node-based transpiler, like those in `jsbundling-rails` and `cssbundling-rails`.

On the other hand, if you're already bundling JavaScript and CSS through a Node-based setup, then Propshaft is going to slot in easily. Since you don't need another tool to bundle or transpile. Just to digest and serve.

But for greenfield apps using the default import-map approach, Propshaft can also work well, if you're able to deal with vanilla CSS.


## License

Propshaft is released under the [MIT License](https://opensource.org/licenses/MIT).
