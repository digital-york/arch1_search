require 'csv'

namespace :export do

	
  desc "Task for exporting all collection registers: 3b591b35w and h702q6403"
  desc "bundle exec rails \"export:all\""
  task :all, [:collection] => :environment do |t, args|
    include RegisterFolio
    include RegisterFolioHelper
  
		collection = "3b591b35w"
		puts "Export register belonging to Collection #{collection}"
		get_collections(collection).map do |register|
			data = []
			data = get_register(register[0])
			
			# Write the data to a CSV file
			save_csv("#{register[0]}", data)
		end

		collection = "h702q6403"
		puts "Export register belonging to Collection #{collection}"
		get_collections(collection).map do |register|
			data = []
			data = get_register(register[0])
			
			# Write the data to a CSV file
			save_csv("#{register[0]}", data)
		end
		
  end
	
  desc "Task for exporting Collection registers: 3b591b35w and h702q6403"
  desc "bundle exec rails \"export:collection[h702q6403]\""
  task :collection, [:collection] => :environment do |t, args|
    include RegisterFolio
    include RegisterFolioHelper
		
    data = get_collections(args[:register])

		# Write the data to a CSV file
		save_csv(args[:register], data)
  end

  desc "Task for exporting registers information by given register"
  desc "bundle exec rails \"export:register[dz010q943]\""
  task :register, [:register] => :environment do |t, args|
    include RegisterFolio
    include RegisterFolioHelper

    data = get_register(args[:register])
    
    # Write the data to a CSV file
    save_csv(args[:register], data)
  end

  def get_register(register)
    data = []
		folio_number = 0
    get_order(register).map { |s| s.split('/').last }.each do |i|
			folio_number += 1
			# puts "#{register}-#{i}"
      images = get_images_for_folio(i)
      alt_image = images.key?(:alt_image) ? images[:alt_image] : nil
      data << [i, folio_number, get_register_name(i), images[:folio_image], alt_image]
    end
    data
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

  def save_csv(file, data)
		headers = ["folio_id", "folio_number", "image_label", "image_path", "uv_image_path"]
    CSV.open("#{file}.csv", 'w', write_headers: true, headers: headers) do |csv|
      data.each do |row|
        csv << row
      end
    end
  end
end