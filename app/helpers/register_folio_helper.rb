module RegisterFolioHelper

  # return the number of indexed entries
  def get_entry_count
    SolrQuery.new.solr_query('has_model_ssim:Entry')['response']['numFound']
  end

  # get the thumbnail image for the register
  def get_thumb(register)
    begin
      thumb = SolrQuery.new.solr_query("id:#{register}", 'thumbnail_url_tesim', 1)['response']['docs'][0]['thumbnail_url_tesim']
      if thumb.nil?
        #return a generic thumbnail
        'register_default.jpg'
      else
        thumb[0]
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

  def get_tile_sources_for_folio(fol)
    begin
      tile_sources = []
      @query_obj = SolrQuery.new
      response = @query_obj.solr_query('hasTarget_ssim:' + fol, 'file_path_tesim', 2, 'preflabel_si asc')['response']['docs']
      # get the file paths from the register
      tile_sources << "//dlib.york.ac.uk/cgi-bin/iipsrv.fcgi?DeepZoom=#{response[0]['file_path_tesim'][0]}.dzi"
      unless response[1].nil?
        session[:alt] = 'yes'
        tile_sources << "//dlib.york.ac.uk/cgi-bin/iipsrv.fcgi?DeepZoom=#{response[1]['file_path_tesim'][0]}.dzi"
      end
      tile_sources
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  def get_folio_name(fol)
    begin
      @query_obj = SolrQuery.new
      # get the file paths from the register
      reg = @query_obj.solr_query('id:' + fol, 'preflabel_tesim', 1, 'preflabel_si asc')['response']['docs'][0]['preflabel_tesim'][0]
      register = reg.split(' ')
      if register[0] == 'Abp' and register[1] == 'Reg'
        register_id = "Register #{register[2]}"
        i = 3
        while i < register.size
          register_id = "#{register_id} #{register[i]}"
          i = i + 1
        end
      else
        register_id = "#{register[0]} #{register[1]} #{register[2]}"
      end
      register_id

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
          q.solr_query('id:"' + o + '"', 'id,preflabel_tesim,reg_id_tesim', 1)['response']['docs'].map.each do |r|
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

end
