require "active_support/ordered_options"
require 'fileutils'

class Trackrod
  attr_accessor :root, :images, :css, :javascript

  def initialize(dir = nil)
    @root       = dir || "#{Dir.getwd}/trackrod"
    @images     = @root + "/images"
    @css        = @root + "/stylesheets"
    @javascript = @root + "/javascript"
  end

  def build
    puts "Building Trackrod assets"

    create_dir(root)
    create_dir(images)
    create_dir(css)
    create_dir(javascript)

    create_images
    create_css
    create_javascript
  end

  def assets
    @assets ||= ActiveSupport::InheritableOptions.new(
      css: "stylesheets/application.css",
      js: "javascript/application.js",
      images: (small_images + large_images).map { "images/#{_1}" }
    )
  end

  private
    def create_css
      File.open("#{css}/application.css", "a") do |file|
        small_images.each_with_index { |img, idx| file.write(background(img, idx)) }
        large_images.each_with_index { |img, idx| file.write(background(img, idx)) }
      end
    end

    def create_javascript
    end

    def create_images
      small_images.each { |img| FileUtils.touch "#{images}/#{img}" }
      large_images.each { |img| File.open("#{images}/#{img}", "a") { |file| file.write("a" * 2 ** 23) } unless File.exist?(img) }

      nil
    end

    def small_images
      @small_images ||= (1..5000).map { "s#{_1}.jpg" }
    end

    def large_images
      @large_images ||= (1..100).map { "l#{_1}.jpg" }
    end

    def background(img, idx)
      ".background_#{idx} {\n  background: url('../images/#{img}') \n}\n\n"
    end

    def create_dir(path)
      Dir.mkdir(path) unless File.exist?(path)
    end
end
