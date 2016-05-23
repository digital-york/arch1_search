namespace :iiif do
  desc "Task for IIIF manifests"

  # Replace the iiif manifest for the given register id
  # Replace the iiif manifest for the given register id
  task :manifest, [:register] => :environment do |t, args|
    include IiifHelper
    get_manifest(args[:register], replace=true)
  end

end
