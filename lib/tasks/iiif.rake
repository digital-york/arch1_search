require 'json'
require 'fileutils'

namespace :iiif do
  desc "Task for IIIF manifests"

  # Replace Fedora copy of the iiif manifest for the given register id
  task :replace_manifest, [:register] => :environment do |t, args|
    include IiifHelper
    get_manifest(args[:register], replace=true)
  end

  # Generate and save iiif manifest for the given register id
  task :save_manifest, [:register] => :environment do |t, args|
    include IiifHelper
    manifest = make_manifest(args[:register])
    # puts manifest.to_json(pretty: true)
    save_manifest_as_json(manifest, args[:register])
  end

  desc "Task for saving all manifests for collections: 3b591b35w and h702q6403"
  desc "bundle exec rails \"export:save_all_manifests\""
  task :save_all_manifests, [:collection] => :environment do |t, args|
    include RegisterFolio
    include RegisterFolioHelper
    include IiifHelper
    include SearchesHelper
  
		collection = "3b591b35w"
		puts "Save manifests for registers belonging to Collection #{collection}"
		get_collections(collection).map do |register|
      puts "Processing #{register[0]}"
	    manifest = make_manifest(register[0])
      save_manifest_as_json(manifest, register[0])		
		end

		collection = "h702q6403"
		puts "Save manifests for registers belonging to Collection #{collection}"
		get_collections(collection).map do |register|
      puts "Processing #{register[0]}"
	    manifest = make_manifest(register[0])
      # puts manifest.to_json(pretty: true)
      save_manifest_as_json(manifest, register[0])		
		end
		
  end

  def save_manifest_as_json(manifest, dir)
    
    # Check if the folder exists, create it if not
    path = "./tmp/manifest/v2/#{dir}"
    FileUtils.mkdir_p(path) unless File.directory?(path)
  
    file_path = File.join(path, "manifest.json")
    
    File.open(file_path, "w") do |file|
      file.write(manifest)
    end
  end

  def get_collections(collection)
		data = []
    get_order(collection).map { |s| s.split('/').last }.each do |i|
			data << [i, get_register_name(i)]
			# print "\"#{i}\" "
      # print "\"#{get_register_name(i)}\" "
      # puts
    end
		data
  end
end
