namespace :test do
  desc "TODO"
  task faraday: :environment do
    require 'faraday'

    conn = Faraday.new(:url => 'http://dlib.york.ac.uk') do |faraday|
      faraday.request  :json             # form-encode POST params
      faraday.response :json, :content_type => 'application/json+ld'
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end

    response = conn.get '/cgi-bin/iipsrv.fcgi?IIIF=/usr/digilib-webdocs/digilibImages/HOA/current/A/20151203/Abp_Reg_01A_0043.jp2/info.json'
    puts JSON.parse eval(response.body)

  end

  task net: :environment do
    require 'net/http'

    res = Net::HTTP.get_response('dlib.york.ac.uk', '/cgi-bin/iipsrv.fcgi?IIIF=/usr/digilib-webdocs/digilibImages/HOA/current/A/20151203/Abp_Reg_01A_0043.jp2/info.json')
    json = JSON.parse res.body
    puts json['width']
    puts json['height']


  end

  task iiif: :environment do
    include IiifHelper
    get_manifest('2n49t181k', replace=true)
  end
end
