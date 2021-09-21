# Propshaft

Propshaft is an asset pipeline library for Rails. It's built for an era where bundling assets to save on HTTP connections is no longer urgent, where JavaScript and CSS are either compiled by dedicated Node.js bundlers or served directly to the browsers, and where increases in bandwidth have made the need for minification less pressing. These factors allow for a dramatically simpler and faster asset pipeline compared to previous options, like Sprockets.

So that's what Propshaft doesn't do. Here's what it does provide:

1. **Configurable load path**: You can register directories from multiple places in your app and gems, and reference assets from all of these paths as though they were one.
1. **Digest stamping**: All assets in the load path will be copied (or compiled) in a precompilation step for production that also stamps all of them with a digest hash, so you can use long-expiry cache headers for better performance. The digested assets can be referred to through their logical path because the processing leaves a manifest file that provides a way to translate.
1. **Development server**: There's no need to precompile the assets in development. You can refer to them via the same asset_path helpers and they'll be served by a development server.
1. **Basic compilers**: Propshaft was explicitly not designed to provide full transpiler capabilities. You can get that better elsewhere. But it does offer a simple input->output compiler setup that by default is used to translate `asset-path` function calls in CSS to `url(digested-asset)` instead.


## Installation

With Rails 7+, you can start a new application with propshaft using `rails new myapp -a propshaft` (pending the merge of [rails/rails#43261](https://github.com/rails/rails/pull/43261)).


## Usage

Propshaft makes all the assets from all the paths it's been configured with through `config.assets.paths` available for serving and will copy all of them into `public/assets` when precompiling. This is unlike Sprockets, which did not copy over assets that hadn't been explicitly included in one of the bundled assets.

These assets can be referenced through their logical path using the normal helpers like `asset_path`, `image_tag`, `javascript_include_tag`, and all the other asset helper tags. These logical references are automatically converted into digest-aware paths in production when `assets:precompile` has been run (through a JSON mapping file found in `public/assets/.manifest.json`).

Additionally, Propshaft ships with a CSS function called `asset-path("image.svg")` that'll be compiled into `url("/assets/image-f2e1ec14d6856e1958083094170ca6119c529a73.svg")` when doing `assets:precompile`. This function is applied to all `.css` files.


## Migrating from Sprockets

Propshaft does a lot less than Sprockets, by design, so it might well be a fair bit of work to migrate if it's even desirable. This is particularly true if you rely on Sprockets to provide any form of transpiling, like CoffeeScript or Sass, or if you rely on any gems that do. You'll need to either stop transpiling or use a Node-based transpiler, like those in `jsbundling-rails` and `cssbundling-rails`.

On the other hand, if you're already bundling JavaScript and CSS through a Node-based setup, then Propshaft is going to slot in easily. Since you don't need another tool to bundle or transpile. Just to digest and serve.

But for greenfield apps using the default import-map approach, Propshaft can also work well, if you're able to deal with vanilla CSS.


## Will Propshaft replace Sprockets as the Rails default?

Most likely, but Sprockets need to be supported as well for a long time to come. Plenty of apps and gems were built on Sprocket features, and they won't be migrating soon. Still working out the compatibility story. This is very much alpha software at the moment.


## License

Propshaft is released under the [MIT License](https://opensource.org/licenses/MIT).
