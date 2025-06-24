# Upgrading from Sprockets to Propshaft

Propshaft has a smaller scope than Sprockets, therefore migrating to it will also require you to adopt the [jsbundling-rails](https://github.com/rails/jsbundling-rails) and [cssbundling-rails](https://github.com/rails/cssbundling-rails) gems. This guide will assume your project follows Rails 6.1 conventions of using [webpacker](https://github.com/rails/webpacker) to bundle javascript, [sass-rails](https://github.com/rails/sass-rails) to bundle css and [sprockets](https://github.com/rails/sprockets) to digest assets. Finally, you will also need [npx](https://docs.npmjs.com/cli/v7/commands/npx) version 7.1.0 or later installed.

Propshaft depends on Rails 7, so you will need to upgrade to Rails 7+ before starting the migration.

## 1. Migrate from Webpacker to jsbundling-rails

Start by following these steps:

1. Replace `webpacker` with `jsbundling-rails` in your Gemfile;
2. Run `./bin/bundle install`;
3. Run `./bin/rails javascript:install:webpack`;
4. Remove the file `config/initializers/assets.rb`;
5. Remove the file `bin/webpack`;
6. Remove the file `bin/webpack-dev-server`;
7. Remove the folder `config/webpack` (note: any custom configuration should be migrated to the new `webpack.config.js` file);
8. Remove the file `config/webpacker.yml`;
9. Replace all instances of `javascript_pack_tag` with `javascript_include_tag` and add `defer: true` to them.

After you are done you will notice that the install step added various files to your project and updated some of the existing ones.

**The new 'bin/dev' and 'Procfile.dev' files**

The `./bin/dev` file is a shell script that uses [foreman](https://github.com/ddollar/foreman) and `Procfile.dev` to start two processes in a single terminal: `rails s` and `yarn build`. The latter replaces `webpack-dev-server` for bundling and watching for changes in javascript files.

**The 'build' attribute added to package.json**

This is the command that `yarn build` will use to bundle javascript files.

**The new 'webpack.config.js' file**

In `webpacker` this file was hidden inside the gem, but now you can edit it directly. If you had custom configuration in `config/webpack` you can move them to here. Projects with multiple entrypoints will need to adjust the `entry` attribute:

```js
module.exports = {
  entry: {
    application: "./app/javascript/application.js",
    admin: "./app/javascript/admin.js"
  }
}
```

**The 'link_tree' directive added to 'app/assets/manifest.js'**

This tells Sprockets to include the files in `app/assets/builds` during `assets:precompile`. This is the folder where `yarn build` will place the bundled files, so make sure you commit it to the repository and don't delete it when cleaning assets. 

**What about babel?**

If you would like to continue using babel for transpiling, you will need to configure it manually. First, open `webpack.config.js` and add this:

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.(js)$/,
        exclude: /node_modules/,
        use: ['babel-loader']
      }
    ]
  }
}
```

Then open `package.json` and add this:
```json
"babel": {
  "presets": [
    "./webpack.babel.js"
  ]
}
```

Finally, download [webpackers babel preset](https://github.com/rails/webpacker/blob/master/package/babel/preset.js) file and place it in the same directory as `package.json` with the name `webpack.babel.js`.

**Module resolution**

Webpacker included the `source_path` (default: `app/javascript/`) into module resolution, so a statement like `import 'channels'` imported `app/javascript/channels/`. After migrating to `jsbundling-rails` this is no longer the case. You will need to update your `webpack.config.js` to include the following if you wish to maintain that behavior:

```javascript
module.exports = {
  // ...
  resolve: {
    modules: ["app/javascript", "node_modules"],
  },
  //...
}
```

Alternatively, you can change modules to use relative imports, for example:
```diff
- import 'channels'
+ import './channels'
```

### Extracting Sass/SCSS from JavaScript

In webpacker it is possible to extract Sass/SCSS from JavaScript by enabling `extract_css` in `webpacker.yml`. This allows for including those source files in JavaScript, e.g. `import '../scss/application.scss`

If you wish to keep this functionality follow these steps:

1. Run `yarn add mini-css-extract-plugin sass sass-loader css-loader`;
2. Update your `webpack.config.js` to require `mini-css-extract-plugin` and configure the loaders (see example below).

Example `webpack.config.js`:

```javascript
const path    = require("path")
const webpack = require("webpack")
const MiniCssExtractPlugin = require("mini-css-extract-plugin")

module.exports = {
  mode: "production",
  devtool: "source-map",
  entry: {
    application: "./app/javascript/application.js"
  },
  resolve: {
    modules: ["app/javascript", "node_modules"],
  },
  output: {
    filename: "[name].js",
    sourceMapFilename: "[file].map",
    path: path.resolve(__dirname, "app/assets/builds"),
  },
  plugins: [
    new MiniCssExtractPlugin(),
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    })
  ],
  module: {
    rules: [
      {
        test: /\.s[ac]ss$/i,
        use: [MiniCssExtractPlugin.loader, "css-loader", "sass-loader"],
      },
    ],
  },
}
```

## 2. Migrate from sass-rails to cssbundling-rails

Note: if your application used Webpacker's `extract_css` to build your CSS and did not require `sass-rails`, you can skip this section.

Start by following these steps:

1. Add `cssbundling-rails` to your Gemfile;
2. Run `./bin/bundle install`;
3. Run `./bin/rails css:install:sass`.

After you are done you will notice that the install step updated some files.

**The new process in 'Procfile.dev'**

Just like the javascript process, this one will bundle and watch for changes in css files.

**The 'build:css' attribute added to package.json**

This is the command `yarn build` will use to bundle css files.

**The 'link_tree' directive removed from 'app/assets/manifest.js'**

Now that the CSS files will be placed into `app/assets/build`, Sprockets no longer needs to worry about the `app/assets/stylesheets` folder. If you have any other `link_tree` for css files, remove them too.

### Configuring multiple entrypoints

Sprockets will only compile files in the root directories listed in `manifest.js`, but the sass package that `yarn build` uses will also check subfolders, which might cause compilation errors if your scss files are using features like `@import` and variables. This means that if you have multiple entry points in your app, you have some extra work ahead of you. 

Let's assume you have the following structure in your `app/asset/stylesheets` folder:

```
stylesheets/admin.scss
stylesheets/admin/source_1.scss
stylesheets/admin/source_2.scss
stylesheets/application.scss
stylesheets/application/source_1.scss
stylesheets/application/source_2.scss
```

Start by your separating your entrypoints from your other files, and adjusting all `@import` for the new structure:

```
stylesheets/entrypoints/admin.scss
stylesheets/entrypoints/application.scss
stylesheets/sources/admin/source_1.scss
stylesheets/sources/admin/source_2.scss
stylesheets/sources/application/source_1.scss
stylesheets/sources/application/source_2.scss
```

Then adjust the `build` attribute in `package.json`:
```
"build:css": "sass ./app/assets/stylesheets/entrypoints:./app/assets/builds --no-source-map --load-path=node_modules"
```

### Deprecation warnings

Sass might raise deprecation warnings depending on what features you are using (such as division), but the messages will explain how to fix them. If you are not sure, see more details in the [official documentation](https://sass-lang.com/documentation/breaking-changes).

## 3. Migrate from Sprockets to Propshaft

Start by following these steps:

1. Remove `sprockets`, `sprockets-rails`, and `sass-rails` from the Gemfile and add `propshaft`;
2. Run `./bin/bundle install`;
3. Check your `Gemfile.lock`, repeat steps 1 and 2 for gems that list `sprockets` or `sprockets-rails` as a dependency;
4. Open `config/application.rb` and remove `config.assets.paths << Rails.root.join('app','assets')`;
5. Remove `app/assets/config/manifest.js`.
6. Replace all asset_helpers (`image_url`, `font_url`) in css files with standard `urls`.
7. If you are importing only the frameworks you need (instead of `rails/all`), remove `require "sprockets/railtie"`;

### Asset paths

Propshaft will automatically include in its search paths the folders `vendor/assets`, `lib/assets` and `app/assets` of your project and of all the gems in your Gemfile. You can see all included files by using the `reveal` rake task:
```
 rake assets:reveal
```

### Asset helpers

Propshaft does not rely on asset_helpers (`asset_path`, `asset_url`, `image_url`, etc.) like Sprockets did. Instead, it will search for every `url` function in your css files, and adjust them to include the digest of the assets they reference.

Go through your css files, and make the necessary adjustments:
```diff
- background: image_url('hero.jpg');
+ background: url('/hero.jpg');
```

Notice that Propshaft's version starts with an `/` and Sprockets' version does not? That's because the latter uses **absolute paths**, and the former uses **relative paths**. To better illustrate that difference, let's assume you have the following structure:

```
assets/stylesheets/theme/main.scss
assets/images/hero.jpg
```

In Sprockets, `main.scss` can reference `hero.jpg` like this:
```css
background: image_url('hero.jpg')
```

Using the same path with `url` in Propshaft will cause it to raise an error, saying it cannot locate `theme/hero.jpg`. That's because Propshaft assumes all paths are relative to the path of the file it's processing. Since it was processing a css file inside the `theme` folder, it will also look for `hero.jpg` in the same folder.

By adding a `/` at the start of the path we are telling Propshaft to consider this path as an absolute path. While this change in behavior increases the work a bit when upgrading, it makes **external libraries like FontAwesome and Bootstrap themes work out-of-the-box**.  

### Asset content

It's a common pattern in apps to inline small SVG files and low resolution versions of images that need to be displayed as quickly as possible. In Propshaft, the same line of code works for all environments: 
```ruby
Rails.application.assets.load_path.find('logo.svg').content
```

As Rails escapes html tags in views by default, in order to output a rendered svg you will need to specify rails not to escape the string using [html_safe](https://api.rubyonrails.org/classes/String.html#method-i-html_safe) or [raw](https://api.rubyonrails.org/classes/ActionView/Helpers/OutputSafetyHelper.html#method-i-raw).
```ruby
Rails.application.assets.load_path.find('logo.svg').content.html_safe
raw Rails.application.assets.load_path.find('logo.svg').content
```

### Precompilation in development

Propshaft uses a dynamic assets resolver in development mode. However, when you run `assets:precompile` locally Propshaft will then switch to a static assets resolver. Therefore, changes to assets will not be observed anymore and you will have to precompile the assets each time changes are made. This is different to Sprockets.

If you wish to have dynamic assets resolver enabled again, you need to clean your target folder (usually `public/assets`) and propshaft will start serving dynamic content from source.  One way to do this is to run `rails assets:clobber`.

Another way to watch changes in your CSS & JS assets is by running `bin/dev` command instead of `rails server` that not only runs the server but also keeps looking for any changes in the assets and once it detects any changes, it compiles them while the server is running. This is possible because of the `Procfile.dev`.
