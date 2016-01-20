namespace :iiif do
  desc "TODO"


  task :manifest, [:register] => :environment do |t, args|
    include IiifHelper
    get_manifest(args[:register], replace=true)
  end
end
