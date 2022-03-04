# Upgrading from Sprockets to Propshaft

Propshaft has a smaller scope than Sprockets, therefore migrating to it will also require you to adopt the [jsbundling-rails](https://github.com/rails/jsbundling-rails) and [cssbundling-rails](https://github.com/rails/cssbundling-rails) gems. This guide will assume your project follows Rails 6.1 conventions of using [webpacker](https://github.com/rails/webpacker) to bundle javascript, [sass-rails](https://github.com/rails/sass-rails) to bundle css and [sprockets](https://github.com/rails/sprockets) to digest assets. Finally, you will also need [npx](https://docs.npmjs.com/cli/v7/commands/npx) version 7.1.0 or later installed.

## 1. Migrate from webpacker to jsbundling-rails

Start by following these steps:

1. Replace `webpacker` with `jsbundling-rails` in your Gemfile;
2. Run `./bin/bundle install`;
3. Run `./bin/rails javascript:install:webpack`;
4. Remove the file `config/initializers/assets.rb`;
5. Remove the file `bin/webpack`;
5. Remove the file `bin/webpack-dev-server`;
6. Remove the folder `config/webpack`;
7. Replace all instances of `javascript_pack_tag` with `javascript_include_tag` and add `defer: true` to them.

After you are done you will notice that the install step added various files to your project and updated some of the existing ones.

**The new 'bin/dev' and 'Procfile.dev' files**

The `./bin/dev` file is a shell script that uses [foreman](https://github.com/ddollar/foreman) and `Procfile.dev` to start two processes in a single terminal: `rails s` and `yarn build`. The latter replaces `webpack-dev-server` in bundling and watching for changes in javascript files.

**The 'build' attribute added to packages.json**

This is the command that `yarn build` will use to bundle javascript files.

**The new 'webpack.config.js file'**

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

Then open `packages.json` and add this:
```json
"babel": {
  "presets": [
    "./webpack.babel.js"
  ]
}
```

Finally, download [webpackers babel preset](https://github.com/rails/webpacker/blob/master/package/babel/preset.js) file and place it in the same directory as `packages.json` with the name `webpack.babel.js`.

## 2. Migrate from sass-rails to cssbundling-rails

Start by following these steps:

1. Add `cssbundling-rails` to your Gemfile;
2. Run `./bin/bundle install`;
3. Run `./bin/rails css:install:sass`.

After you are done you will notice that the install step updated some files.

**The new process in 'Procfile.dev'**

Just like the javascript process, this one will bundle and watch for changes in css files.

**The 'build:css' attribute added to packages.json**

This is the command `yarn build` will use to bundle css files.

**The 'link_tree' directive removed from 'app/assets/manifest.js'**

Now that the CSS files will be placed into `app/assets/build`, Sprockets no longer needs to worry about the `app/assets/stylesheets` folder. If you have any other `link_tree` for css files, remove them too.

**Configuring multiple entrypoints**

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

Then adjust the `build` attribute in `packages.json`:
```
"build:css": "sass ./app/assets/stylesheets/entrypoints:./app/assets/builds --no-source-map --load-path=node_modules"
```

**Deprecation warnings**

Sass might raise deprecation warnings depending on what features you are using (such as division), but the messages will explain how to fix them. If you are not sure, see more details in the [official documentation](https://sass-lang.com/documentation/breaking-changes).

## 3. Migrate from Sprockets to Propshaft

Start by following these steps:

1. Remove `sprockets`, `sprockets-rails`, and `sass-rails` from the Gemfile and add `propshaft`;
2. Run `./bin/bundle install`;
3. Open `config/application.rb` and remove `config.assets.paths << Rails.root.join('app','assets')`;
4. Remove `asset/config/manifest.js`.
5. Replace all asset_helpers (`image_url`, `font_url`) in css files with standard `urls`.
6. If you are importing only the frameworks you need (instead of `rails/all`), remove `require "sprockets/railtie"`;

**Asset paths**

Propshaft will automatically include in its search paths the folders `vendor/assets`, `lib/assets` and `app/assets` of your project and all the gems in your gemfile. You can see all included files by using the `reveal` rake task:
```
 rake assets:reveal
```

**Asset helpers**

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

By adding a `/` at the start of the path we are telling Propshaft to consider to treat this path as an absolute path. While this change in behavior increases the work a bit when upgrading, it makes **external libraries like FontAwesome and Bootstrap themes work out-of-the-box**.  

**Asset content**

It's a common pattern in apps to inline small SVG files and low resolution versions of images that need to be displayed as quickly as possible. In Propshaft, the same line of code works for all environments: 
```ruby
Rails.application.assets.load_path.find('logo.svg').content
```

**Precompilation in development**

Propshaft is using dynamic assets resolver in development mode. However, when you run `assets:precompile` locally - it's then switching to static assets resolver. Your changes to assets will not be anymore observed and you'd have to precompile assets each time. This is different to Sprockets.
