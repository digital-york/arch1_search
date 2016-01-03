# added (ja)
require 'iiif/presentation'
require 'faraday'
require 'faraday_middleware'
require 'json'

module IiifHelper

  def make_manifest(pid)
    @query_obj = SolrQuery.new
    canvas(pid,manifest(pid)).to_json(pretty: true)
  end

  def manifest(pid)
    resp = @query_obj.solr_query('id:"' + pid + '"',fl='reg_id_tesim,preflabel_tesim,thumbnail_url',rows=1)['response']['docs']

    seed = {
        '@id' => 'http://example.com/manifest',
        'label' => resp[0]['reg_id_tesim'],
        'description' => resp[0]['preflabel_tesim'],
        'attribution' => 'Made available by the University of York',
        'license' => 'http://creativecommons.org/licenses/by-sa/4.0/',
        'thumbnail' => resp[0]['thumbnail_url_tesim']
    }

    manifest = IIIF::Presentation::Manifest.new(seed)
    manifest
  end

  def canvas(pid,manifest)

    @query_obj.solr_query('id:"' + pid + '/list_source"',fl='ordered_targets_ssim',rows=1)['response']['docs'][0]['ordered_targets_ssim'].each_with_index do |target, i|
      resp = @query_obj.solr_query('id:"' + target + '"',fl='preflabel_tesim',rows=1)['response']['docs']
      canvas = IIIF::Presentation::Canvas.new()
      canvas['@id'] = "http://episcopal.york.ac.uk/browse/registers?register_id=#{pid}&folio=#{i + 1}?folio_id=#{target}"
      image = ''
      @query_obj.solr_query('hasTarget_ssim:"'+ target + '"',fl='id,file_path_tesim',rows=1,'preflabel_si asc')['response']['docs'].each do |img|
        image = img['file_path_tesim'].join
        #if i == 0
        #get_info_json(image)
        #end

        canvas.width = 3000 # TODO required
        canvas.height = 4000 # TODO required
      end
      canvas.label = resp[0]['preflabel_tesim']
      canvas['on'] = "http://episcopal.york.ac.uk/browse/registers?register_id=#{pid}&folio=#{i + 1}?folio_id=#{target}"

      begin
        img = IIIF::Presentation::Annotation.new(
            'resource' => IIIF::Presentation::ImageResource.new(
                '@id' => "http://dlib.york.ac.uk/cgi-bin/iipsrv.fcgi?IIIF/#{image}/info.json",
                'service' => {
                    '@id' => "http://episcopal.york.ac.uk/browse/registers?register_id=#{pid}&folio=#{i + 1}?folio_id=#{target}",
                    '@context' => 'http://iiif.io/api/image/2/context.json',
                    'profile' => 'http://iiif.io/api/image/2/level1.json'
                },
                'format' => 'image/jp2'
            )
        )
        canvas.images << img
      rescue
      end
      manifest.sequences << canvas
    end
    puts manifest.to_json(pretty: true)
    #manifest
  end

  def get_info_json(image)

    conn = Faraday.new(:url => 'http://dlib.york.ac.uk') do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :json, :content_type => 'application/json+ld'
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end

## GET ##

    response = conn.get '/cgi-bin/iipsrv.fcgi?IIIF=' + image + '/info.json'
    #response = conn.get
    puts response.body
    #puts ActiveSupport::JSON.decode(response.body)
    #JSON.parse(ActiveSupport::JSON.decode(response.body).gsub('\"', '"'))
  end
end
