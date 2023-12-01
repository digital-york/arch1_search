module RegisterFolioHelper

  # return the number of indexed entries
  def get_entry_count
    SolrQuery.new.solr_query('has_model_ssim:Entry')['response']['numFound']
  end

  def get_folio_id_by_image_file_path(file_path)
    folio_id = SolrQuery.new.solr_query("file_path_tesim:\"#{file_path}\"",'hasTarget_ssim',1)['response']['docs'][0]['hasTarget_ssim'][0]
  end

  # get the thumbnail image for the register
  def get_thumb(register)
    begin
      thumb = SolrQuery.new.solr_query("id:#{register}", 'thumbnail_url_tesim', 1)['response']['docs'][0]['thumbnail_url_tesim']
      if thumb.nil?
        #return a generic thumbnail
        'register_default.jpg'
      else
        image_region = thumb[0].match(/jp2(.*)/)[1]
        folio_id = get_folio_id_by_image_file_path(thumb[0].match(/=(.*).jp2/)[1])
        "#{register}/objects/#{folio_id}#{image_region}"
      end
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end

  def get_order(reg)
    begin
      @query_obj = SolrQuery.new
      @query_obj.solr_query('id:"' + reg + '/list_source"', fl='ordered_targets_ssim', rows=1)['response']['docs'][0]['ordered_targets_ssim']
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  def get_tile_sources_for_register(reg)
    begin
      tile_sources = []
      @query_obj = SolrQuery.new
      # get the file paths from the register
      get_order(reg).each do |target|
        @query_obj.solr_query('hasTarget_ssim:' + target, 'file_path_tesim', 1, 'preflabel_si asc')['response']['docs'][0]['file_path_tesim']
        tile_sources << "//dlib.york.ac.uk/cgi-bin/iipsrv.fcgi?DeepZoom=#{@query_obj.solr_query('hasTarget_ssim:' + target, 'file_path_tesim', 1, 'preflabel_si asc')['response']['docs'][0]['file_path_tesim'][0]}.dzi"
      end
      tile_sources
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  # FixMe - images from /browse/registers?register_id=6d56zz38x
  def get_tile_sources_for_folio(fol)
    begin
      id = get_id(fol)
      image_uri = "#{IIIF[Rails.env]['image_api_url']}#{get_folio_image_iiif(id)}"
      tile_sources = []
      @query_obj = SolrQuery.new
      response = @query_obj.solr_query('hasTarget_ssim:' + id, 'file_path_tesim', 2, 'preflabel_si asc')['response']['docs']

      # get the file paths from the register
      tile_sources << "#{image_uri}/info.json"
      unless response[1].nil?
        session[:alt] = 'yes'
        tile_sources << "#{image_uri}.uv/info.json"
      end
      tile_sources
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  # Get the 'title' of the folio from the entry
  def get_folio_title(entry)
    begin
      @query_obj = SolrQuery.new
      # get the file paths from the register
      @query_obj.solr_query('id:' + entry, 'entry_folio_facet_ssim', 1)['response']['docs'][0]['entry_folio_facet_ssim'][0]

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  def get_collections(pid=nil)
    begin
      collections = Hash.new
      q = SolrQuery.new
      if pid.nil?
      # Get the collections
        q.solr_query('has_model_ssim:OrderedCollection', 'id,preflabel_tesim', 10, 'preflabel_si desc')['response']['docs'].map.each do |c|
        collections[c['id']] = [c['preflabel_tesim'][0]]
        end
      else
        # get the specified collection
        q.solr_query('has_model_ssim:OrderedCollection and id:' + pid, 'id,preflabel_tesim', 1, 'preflabel_si asc')['response']['docs'].map.each do |c|
          collections[c['id']] = [c['preflabel_tesim'][0]]
        end
      end
      collections
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  # Return list of registers (fedora id, register id and title), in order
  # Don't use @order here as this is registers NOT folios
  def get_registers_in_order(collection)
    begin
      # Get the collections so that we can get a list of registers in order
      registers = Hash.new
      q = SolrQuery.new
      q.solr_query('id:"' + collection + '/list_source"', 'ordered_targets_ssim', 2)['response']['docs'].map.each do |res|
        order = res['ordered_targets_ssim']
        order.each do |o|
          id = get_id(o)
          q.solr_query('id:"' + id + '"', 'id,preflabel_tesim,reg_id_tesim', 1)['response']['docs'].map.each do |r|
            registers[r['id']] = [r['reg_id_tesim'][0], r['preflabel_tesim'][0]]
          end
        end
      end
      registers
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  def get_id(o)
    id = (o.include? '/') ? o.rpartition('/').last : o
  end

end
