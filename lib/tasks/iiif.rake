namespace :iiif do
  desc "TODO"


  task :manifest, [:register] => :environment do |t, args|
    include IiifHelper
    get_manifest(args[:register], replace=true)
  end

  task :canvas, [:register] => :environment do |t, args|
    include IiifHelper
    #get_canvas(args[:register], replace=true)
    get_canvas("9s161698m", replace=true)
    get_canvas("zk51vh39d", replace=true)
    get_canvas("08612p429", replace=true)
    get_canvas("bc386j987", replace=true)
    g
  end
end
