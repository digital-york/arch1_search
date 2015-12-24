module RegisterFolioHelper

  # get the thumbnail image for the register
  def get_thumb(register)

    thumb = SolrQuery.new.solr_query("id:#{register}", 'thumbnail_url_tesim', 1)['response']['docs'][0]['thumbnail_url_tesim']
    if thumb.nil?
      #return a generic thumbnail
      'register_default.jpg'
    else
      thumb[0]
    end

  end

  def get_order(reg)
    @query_obj = SolrQuery.new
    @query_obj.solr_query('id:"' + reg + '/list_source"',fl='ordered_targets_ssim',rows=1)['response']['docs'][0]['ordered_targets_ssim']
  end

  def get_tile_sources_for_register(reg)
    tile_sources = []
    @query_obj = SolrQuery.new
    # get the file paths from the register
    get_order(reg).each do | target |
      @query_obj.solr_query('hasTarget_ssim:' + target,'file_path_tesim',1,'preflable_si asc')['response']['docs'][0]['file_path_tesim']
      tile_sources << "http://dlib.york.ac.uk/cgi-bin/iipsrv.fcgi?DeepZoom=#{@query_obj.solr_query('hasTarget_ssim:' + target,'file_path_tesim',1,'preflabel_si asc')['response']['docs'][0]['file_path_tesim'][0]}.dzi"
    end
    tile_sources
  end

  def get_tile_sources_for_folio(fol)
    tile_sources = []
    @query_obj = SolrQuery.new
    response = @query_obj.solr_query('hasTarget_ssim:' + fol,'file_path_tesim',2,'preflabel_si asc')['response']['docs']
    # get the file paths from the register
    tile_sources << "http://dlib.york.ac.uk/cgi-bin/iipsrv.fcgi?DeepZoom=#{response[0]['file_path_tesim'][0]}.dzi"
    unless response[1].nil?
      session[:alt] = 'yes'
      tile_sources << "http://dlib.york.ac.uk/cgi-bin/iipsrv.fcgi?DeepZoom=#{response[1]['file_path_tesim'][0]}.dzi"
    end
    tile_sources
  end

  def get_folio_name(fol)
    @query_obj = SolrQuery.new
    # get the file paths from the register
    @query_obj.solr_query('id:' + fol,'preflabel_tesim',1,'preflabel_si asc')['response']['docs'][0]['preflabel_tesim'][0]
  end

  def get_collections
    collections = Hash.new
    q = SolrQuery.new
    # Get the collections
    q.solr_query('has_model_ssim:OrderedCollection', 'id,preflabel_tesim', 10, 'preflabel_si asc')['response']['docs'].map.each do |c|
      collections[c['id']] = [c['preflabel_tesim'][0]]
    end
    collections
  end

  # Return list of registers (fedora id, register id and title), in order
  # Don't use @order here as this is registers NOT folios
  def get_registers_in_order(collection)
    # Get the collections so that we can get a list of registers in order
    registers = Hash.new
    q = SolrQuery.new
    q.solr_query('id:"' + collection + '/list_source"', 'ordered_targets_ssim', 100)['response']['docs'].map.each do |res|
      order = res['ordered_targets_ssim']
      order.each do |o|
        q.solr_query('id:"' + o + '"', 'id,preflabel_tesim,reg_id_tesim', 1)['response']['docs'].map.each do |r|
          registers[r['id']] = [r['reg_id_tesim'][0], r['preflabel_tesim'][0]]
        end
      end
    end
    registers
  end

end
