require 'iiif/presentation'
require 'net/http'
require 'json'

module IiifHelper

  def get_manifest(pid, replace=false)
    begin
      register = Register.find(pid)

      if replace == true
        make_fedora_manifest(pid)
      else
        if register.manifest.content.nil?
          make_fedora_manifest(register.id)
          return register.manifest.content
        else
          register.manifest.content
        end
      end
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  def make_fedora_manifest(register_id)
    register = Register.find(register_id)
    begin
      register.manifest.content = StringIO.new(make_manifest(register.id))
      register.manifest.mime_type = 'application/json'
      register.manifest.preflabel = 'IIIF Manifest'
      register.save
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  def make_manifest(pid)
    begin
      sequence_and_canvases(pid, manifest_part(pid)).to_json(pretty: true)
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  def manifest_part(pid)
    begin
      @query_obj = SolrQuery.new
      resp = @query_obj.solr_query('id:"' + pid + '"', fl='reg_id_tesim,preflabel_tesim,thumbnail_url_tesim', rows=1)['response']['docs']
      seed = {
          '@id' => "http://#{ENV['SERVER']}/iiif/manifest/#{pid}",
          'label' => resp[0]['reg_id_tesim'][0],
          'description' => resp[0]['preflabel_tesim'][0],
          'attribution' => 'Made available by the University of York',
          'license' => 'http://creativecommons.org/licenses/by-sa/4.0/',
          'thumbnail' => 'http:' + resp[0]['thumbnail_url_tesim'][0]
      }

      manifest = IIIF::Presentation::Manifest.new(seed)
      manifest
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  def sequence_and_canvases(pid, manifest)
    seed = {
        '@id' => "http://#{ENV['SERVER']}/browse/registers?register_id=#{pid}",
        'label' => 'Ordered Sequence',
        'viewingDirection'=> 'left-to-right',
        'viewingHint' => 'paged'
    }

    sequence = IIIF::Presentation::Sequence.new(seed)

    @query_obj.solr_query('id:"' + pid + '/list_source"', fl='ordered_targets_ssim', rows=1)['response']['docs'][0]['ordered_targets_ssim'].each_with_index do |target, i|
      resp = @query_obj.solr_query('id:"' + target + '"', fl='preflabel_tesim', rows=1)['response']['docs']
      canvas = IIIF::Presentation::Canvas.new()
      canvas['@id'] = "http://#{ENV['SERVER']}/browse/registers?register_id=#{pid}&folio=#{i + 1}&folio_id=#{target}"
      width, height = get_info_json(get_image(target))
      canvas.width, canvas.height = width, height
      canvas.label = resp[0]['preflabel_tesim'].join


      begin
        img = IIIF::Presentation::Annotation.new(
            'resource' => IIIF::Presentation::ImageResource.new(
                '@id' => "http://#{ENV['SERVER']}/iiif/#{target}",
                'service' => {
                    '@id' => "http://#{ENV['SERVER']}/browse/registers?register_id=#{pid}&folio=#{i + 1}&folio_id=#{target}",
                    '@context' => 'http://iiif.io/api/image/2/context.json',
                    'profile' => 'http://iiif.io/api/image/2/level1.json'
                },
                'width' => width,
                'height' => height,
                'format' => 'image/jp2'
            ),
            'on' => "http://#{ENV['SERVER']}/browse/registers?register_id=#{pid}&folio=#{i + 1}&folio_id=#{target}"
        )
        canvas.images << img
      rescue => error
        log_error(__method__, __FILE__, error)
      end
      sequence.canvases << canvas
    end
    manifest.sequences << sequence
    manifest
  end

  def get_info_json(image)
    begin
      res = Net::HTTP.get_response('dlib.york.ac.uk', '/cgi-bin/iipsrv.fcgi?IIIF=' + image + '/info.json')
      json = JSON.parse res.body
      return json['width'], json['height']
    rescue => error
      log_error(__method__, __FILE__, error)
      return 100, 100
    end
  end

  def get_image(target)
    image = ''
    SolrQuery.new.solr_query('hasTarget_ssim:"'+ target + '"', fl='id,file_path_tesim', rows=1, 'preflabel_si asc')['response']['docs'].each do |img|
      image = img['file_path_tesim'].join
    end
    image
  end

  # Writes error message to the log
  def log_error(method, file, error)
    time = ''
    # Only add time for development log because production already outputs timestamp
    if Rails.env == 'development'
      time = Time.now.strftime('[%d/%m/%Y %H:%M:%S] ').to_s
    end
    Rails.logger.error "#{time}EXCEPTION IN #{file}, method='#{method}' [#{error}]"
  end
end
