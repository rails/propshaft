namespace :assets do
  desc "Compile all the assets from config.assets.paths"
  task precompile: :environment do
    Rails.application.assets.processor.process
  end

  desc "Remove config.assets.output_path"
  task clobber: :environment do
    Rails.application.assets.processor.clobber
  end

  desc "Removes old files in config.assets.output_path"
  task clean: :environment do
    Rails.application.assets.processor.clean
  end

  desc "Print all the assets available in config.assets.paths"
  task reveal: :environment do
    Rails.application.assets.reveal(:logical_path)
  end

  namespace :reveal do
    desc "Print the full path of assets available in config.assets.paths"
    task full: :environment do
      Rails.application.assets.reveal(:path)
    end
  end
end
