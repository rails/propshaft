# Propshaft

Propshaft is an asset pipeline library for Rails. It's built for an era where bundling assets to save on HTTP connections is no longer urgent, where JavaScript and CSS are either compiled by dedicated Node.js bundlers or served directly to the browsers, and where increases in bandwidth have made the need for minification less pressing. These factors allow for a dramatically simpler and faster asset pipeline compared to previous options, like [Sprockets](https://github.com/rails/sprockets-rails).

So that's what Propshaft doesn't do. Here's what it does provide:

1. **Configurable load path**: You can register directories from multiple places in your app and gems, and reference assets from all of these paths as though they were one.
1. **Digest stamping**: All assets in the load path will be copied (or compiled) in a precompilation step for production that also stamps all of them with a digest hash, so you can use long-expiry cache headers for better performance. The digested assets can be referred to through their logical path because the processing leaves a manifest file that provides a way to translate.
1. **Development server**: There's no need to precompile the assets in development. You can refer to them via the same asset_path helpers and they'll be served by a development server.
1. **Basic compilers**: Propshaft was explicitly not designed to provide full transpiler capabilities. You can get that better elsewhere. But it does offer a simple input->output compiler setup that by default is used to translate `url(asset)` function calls in CSS to `url(digested-asset)` instead and source mapping comments likewise.


## Installation

With Rails 8, Propshaft is the default asset pipeline for new applications. With Rails 7, you can start a new application with propshaft using `rails new myapp -a propshaft`. For existing applications, check the [upgrade guide](https://github.com/rails/propshaft/blob/main/UPGRADING.md) which contains step-by-step instructions.

## Usage

Propshaft makes all the assets from all the paths it's been configured with through `config.assets.paths` available for serving and will copy all of them into `public/assets` when precompiling. This is unlike Sprockets, which did not copy over assets that hadn't been explicitly included in one of the bundled assets.

You can however exempt directories that have been added through the `config.assets.excluded_paths`. This is useful if you're for example using `app/assets/stylesheets` exclusively as a set of inputs to a compiler like Dart Sass for Rails, and you don't want these input files to be part of the load path. (Remember you need to add full paths, like `Rails.root.join("app/assets/stylesheets")`).

These assets can be referenced through their logical path using the normal helpers like `asset_path`, `image_tag`, `javascript_include_tag`, and all the other asset helper tags. These logical references are automatically converted into digest-aware paths in production when `assets:precompile` has been run (through a JSON mapping file found in `public/assets/.manifest.json`).

## Referencing digested assets in CSS and JavaScript

Propshaft will automatically convert asset references in CSS to use the digested file names. So `background: url("/bg/pattern.svg")` is converted to `background: url("/assets/bg/pattern-2169cbef.svg")` before the stylesheet is served.

For JavaScript, you'll have to manually trigger this transformation by using the `RAILS_ASSET_URL` pseudo-method. It's used like this:

```javascript
export default class extends Controller {
  init() {
    this.img = RAILS_ASSET_URL("/icons/trash.svg")
  }
}
```

That'll turn into:

```javascript
export default class extends Controller {
  init() {
    this.img = "/assets/icons/trash-54g9cbef.svg"
  }
}
```

## Bypassing the digest step

If you need to put multiple files that refer to each other through Propshaft, like a JavaScript file and its source map, you have to digest these files in advance to retain stable file names. Propshaft looks for the specific pattern of `-[digest].digested.js` as the postfix to any asset file as an indication that the file has already been digested.

## Subresource Integrity (SRI)

Propshaft supports Subresource Integrity (SRI) to help protect against malicious modifications of assets. SRI allows browsers to verify that resources fetched from CDNs or other sources haven't been tampered with by checking cryptographic hashes.

### Enabling SRI

To enable SRI support, configure the hash algorithm in your Rails application:

```ruby
config.assets.integrity_hash_algorithm = "sha384"
```

Valid hash algorithms include:
- `"sha256"` - SHA-256 (most common)
- `"sha384"` - SHA-384 (recommended for enhanced security)
- `"sha512"` - SHA-512 (strongest)

### Using SRI in your views

Once configured, you can enable SRI by passing the `integrity: true` option to asset helpers:

```erb
<%= stylesheet_link_tag "application", integrity: true %>
<%= javascript_include_tag "application", integrity: true %>
```

This generates HTML with integrity hashes:

```html
<link rel="stylesheet" href="/assets/application-abc123.css"
      integrity="sha384-xyz789...">
<script src="/assets/application-def456.js"
        integrity="sha384-uvw012..."></script>
```

**Important**: SRI only works in secure contexts (HTTPS) or during local development. The integrity hashes are automatically omitted when serving over HTTP in production for security reasons.

### Bulk stylesheet inclusion with SRI

Propshaft extends `stylesheet_link_tag` with special symbols for bulk inclusion:

```erb
<%= stylesheet_link_tag :all, integrity: true %>  <!-- All stylesheets -->
<%= stylesheet_link_tag :app, integrity: true %>  <!-- Only app/assets stylesheets -->
```

## Improving performance in development

Before every request Propshaft checks if any asset was updated to decide if a cache sweep is needed. This verification is done using the application's configured file watcher which, by default, is `ActiveSupport::FileUpdateChecker`.

If you have a lot of assets in your project, you can improve performance by adding the `listen` gem to the development group in your Gemfile, and this line to the `development.rb` environment file:

```ruby
config.file_watcher = ActiveSupport::EventedFileUpdateChecker
```


## Migrating from Sprockets

Propshaft does a lot less than Sprockets, by design, so it might well be a fair bit of work to migrate if it's even desirable. This is particularly true if you rely on Sprockets to provide any form of transpiling, like CoffeeScript or Sass, or if you rely on any gems that do. You'll need to either stop transpiling or use a Node-based transpiler, like those in [`jsbundling-rails`](https://github.com/rails/jsbundling-rails) and [`cssbundling-rails`](https://github.com/rails/cssbundling-rails).

On the other hand, if you're already bundling JavaScript and CSS through a Node-based setup, then Propshaft is going to slot in easily. Since you don't need another tool to bundle or transpile. Just to digest and serve.

But for greenfield apps using the default import-map approach, Propshaft can also work well, if you're able to deal with vanilla CSS.


## License

Propshaft is released under the [MIT License](https://opensource.org/licenses/MIT).
