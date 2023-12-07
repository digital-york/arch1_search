require 'iiif/presentation'
require 'net/http'
require 'json'

module IiifHelper
include RegisterFolioHelper
  def get_manifest(pid, replace = false)
    register = Register.find(pid)
    if replace == true
      make_fedora_manifest(pid)
    else
      if register.manifest.content.nil?
        make_fedora_manifest(register.id)
        register.manifest.content
      else
        register.manifest.content
      end
    end
  rescue StandardError => e
    log_error(__method__, __FILE__, e)
    raise
  end

  def make_fedora_manifest(register_id)
    register = Register.find(register_id)
    begin
      register.manifest.content = StringIO.new(make_manifest(register.id))
      register.manifest.mime_type = 'application/json'
      register.manifest.preflabel = 'IIIF Manifest'
      register.save
    rescue StandardError => e
      log_error(__method__, __FILE__, e)
      raise
    end
  end

  def make_manifest(pid)
    sequence_and_canvases(pid, manifest_part(pid)).to_json(pretty: true)
  rescue StandardError => e
    log_error(__method__, __FILE__, e)
    raise
  end

  def get_canvas(pid, replace = false)
    folio = Folio.find(pid)

    if replace == true
      make_fedora_canvas(pid)
    else
      if folio.canvas.content.nil?
        make_fedora_canvas(folio.id)
        folio.canvas.content
      else
        folio.canvas.content
      end
    end
  rescue StandardError => e
    log_error(__method__, __FILE__, e)
    raise
  end

  def make_fedora_canvas(folio_id)
    @query_obj = SolrQuery.new
    folio = Folio.find(folio_id)
    begin
      folio.canvas.content = StringIO.new(make_canvas(folio.id))
      folio.canvas.mime_type = 'application/json'
      folio.canvas.preflabel = 'IIIF Canvas'
      folio.save
    rescue StandardError => e
      log_error(__method__, __FILE__, e)
      raise
    end
  end

  def make_canvas(pid)
    canvas_builder(pid, nil).to_json(pretty: true)
  rescue StandardError => e
    log_error(__method__, __FILE__, e)
    raise
  end

  def manifest_part(pid)
    @query_obj = SolrQuery.new
    resp = @query_obj.solr_query('id:"' + pid + '"', fl = 'reg_id_tesim,preflabel_tesim,thumbnail_url_tesim', rows = 1)['response']['docs']
    seed = {
      '@id' => "#{ENV['SERVER']}/iiif/manifest/#{pid}",
      'label' => resp[0]['reg_id_tesim'][0],
      'description' => resp[0]['preflabel_tesim'][0],
      'attribution' => 'Made available by the University of York',
      'license' => 'http://creativecommons.org/licenses/by-sa/4.0/',
      'thumbnail' => "#{IIIF_ENV[Rails.env]['image_api_url']}#{get_thumb(pid)}"
    }

    manifest = IIIF::Presentation::Manifest.new(seed)
    manifest
  rescue StandardError => e
    log_error(__method__, __FILE__, e)
    raise
  end

  def sequence_and_canvases(pid, manifest)
    seed = {
      '@id' => "#{ENV['SERVER']}/browse/registers?register_id=#{pid}",
      'label' => 'Ordered Sequence',
      'viewingDirection' => 'left-to-right',
      'viewingHint' => 'paged'
    }

    sequence = IIIF::Presentation::Sequence.new(seed)

    @query_obj.solr_query('id:"' + pid + '/list_source"', fl = 'ordered_targets_ssim', rows = 1)['response']['docs'][0]['ordered_targets_ssim'].each_with_index do |target, i|
      sequence.canvases << canvas_builder(get_id(target), i)
    end
    manifest.sequences << sequence
    manifest
  end

  def canvas_builder(pid, i)
    resp = @query_obj.solr_query('id:"' + pid + '"', fl = 'preflabel_tesim,isPartOf_ssim', rows = 1)['response']['docs']
    canvas = IIIF::Presentation::Canvas.new
    if i.nil?
      targets = @query_obj.solr_query('id:"' + resp[0]['isPartOf_ssim'].join + '/list_source"', fl = 'ordered_targets_ssim', rows = 1)['response']['docs'][0]['ordered_targets_ssim']
      fol_num = "&folio=#{targets.find_index(pid) + 1}"
    else
      fol_num = "&folio=#{i + 1}"
    end
    canvas['@id'] = "#{ENV['SERVER']}/iiif/canvas/#{pid}"
    width, height = get_info_json(get_image(pid))
    canvas.width = width
    canvas.height = height
    canvas.label = resp[0]['preflabel_tesim'].join

    register_id =  resp[0]['isPartOf_ssim'][0]
    begin
      img = IIIF::Presentation::Annotation.new(
        'resource' => IIIF::Presentation::ImageResource.new(
          '@id' => "#{ENV['SERVER']}/iiif/#{pid}/full/full/0/default.jpg",
          'service' => {
            '@id' => "#{ENV['SERVER']}/iiif/#{pid}",
            '@context' => 'http://iiif.io/api/image/2/context.json',
            'profile' => 'http://iiif.io/api/image/2/level1.json'
          },
          'width' => width,
          'height' => height,
          'format' => 'image/jpeg'
        ),
        'on' => "#{ENV['SERVER']}/browse/registers?register_id=#{register_id}/#{fol_num}&folio_id=#{pid}"
      )
      canvas.images << img
      canvas
    rescue StandardError => e
      log_error(__method__, __FILE__, e)
    end
  end

  def get_info_json(image)
    net = Net::HTTP.new('dlib.york.ac.uk', 443)
    net.use_ssl = true
    res = net.get('/cgi-bin/iipsrv.fcgi?IIIF=' + image + '/info.json')
    json = JSON.parse res.body
    [json['width'], json['height']]
  rescue StandardError => e
    log_error(__method__, __FILE__, e)
    [100, 100]
  end

  def get_image(target)
    image = ''
    SolrQuery.new.solr_query('hasTarget_ssim:"' + target + '"', fl = 'id,file_path_tesim', rows = 1, 'preflabel_si asc')['response']['docs'].each do |img|
      image = img['file_path_tesim'].join
    end
    image
  end

  # Writes error message to the log
  def log_error(method, file, error)
    time = ''
    # Only add time for development log because production already outputs timestamp
    time = Time.now.strftime('[%d/%m/%Y %H:%M:%S] ').to_s if Rails.env == 'development'
    Rails.logger.error "#{time}EXCEPTION IN #{file}, method='#{method}' [#{error}]"
  end

  # Convert Solr stored ID from production/00/00/01/81/00000181d to 00000181d
  def get_id(o)
    id = (o.include? '/') ? o.rpartition('/').last : o
  end
end
