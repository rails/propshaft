namespace :assets do
  desc "Compile all the assets from config.assets.paths"
  task precompile: :environment do
    Rails.application.assets.processor.process
    if Rails.env.development?
      puts "Warning: You are precompiling assets in development. Rails will not " \
        "serve any changed assets until you delete public#{Rails.application.config.assets.prefix}/.manifest.json"
    end
  end

  desc "Remove config.assets.output_path"
  task clobber: :environment do
    Rails.application.assets.processor.clobber
  end

  desc "Removes old files in config.assets.output_path"
  task :clean, [:count] => [:environment] do |_, args|
    count = args.fetch(:count, 2)
    Rails.application.assets.processor.clean(count.to_i)
  end

  desc "Print all the assets available in config.assets.paths"
  task reveal: :environment do
    puts Rails.application.assets.reveal(:logical_path).join("\n")
  end

  namespace :reveal do
    desc "Print the full path of assets available in config.assets.paths"
    task full: :environment do
      puts Rails.application.assets.reveal(:path).join("\n")
    end
  end
end
