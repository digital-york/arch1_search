module RegisterFolio

  # Get the list of folios for a register
  # This is called repeated times; it would be nice to call once per register
  def set_order

    begin
      @order = SolrQuery.new.solr_query('id:"' + session[:register_id] + '/list_source"', 'ordered_targets_ssim', 1)['response']['docs'][0]['ordered_targets_ssim']
      @order.collect! do |element|
        get_id(element)
      end

      @order
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end

  # Set the first and last folio session variables - this is used to grey out
  # the '<' and '>' icons if the limits are reached
  def set_first_and_last_folio
    begin
      set_order
      session[:first_folio_id] = @order[0]
      session[:last_folio_id] = @order[@order.length-1]
        # Timings indicate that this step for 5A (the longest register) took 26s; the new code took 4s
        #register = Register.find(session[:register_id])
        #session[:first_folio_id] = register.ordered_folio_proxies.first.target_id
        #session[:last_folio_id] = register.ordered_folio_proxies.last.target_id
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  def get_register_name(reg)
    SolrQuery.new.solr_query('id:"' + reg + '"', 'preflabel_tesim', 1)['response']['docs'][0]['preflabel_tesim'][0]
  end

  # Set the folio and image session variables, e.g. when the '>' or '<' buttons are clicked
  # action = 'prev_tesim' or 'next_tesim'
  def set_folio_and_image(action, id)

    begin

      next_id = ''
      next_image = ''

      if action != nil #&& id != nil
        # convert the list of folios in order into a hash so we can access the position of our id
        set_order
        hash = Hash[@order.map.with_index.to_a]
        if action == 'next_tesim'
          next_id = @order[hash[id].to_i + 1]
        elsif action == 'prev_tesim'
          next_id = @order[hash[id].to_i - 1]
        end
      end

      q = SolrQuery.new
      # Set the folio image session variable

      q.solr_query('hasTarget_ssim:"' + next_id + '"', 'file_path_tesim', 1, sort='preflabel_si asc')['response']['docs'].map do |result|
        next_image = result['file_path_tesim'][0]
      end

      session[:alt_image] = []

      response = q.solr_query('hasTarget_ssim:"' + next_id + '"', fl='file_path_tesim', 2, 'preflabel_si asc')['response']

      if response['numFound'] > 1
        count = 0
        response['docs'].map do |result|
          if count == 0
            next_image = result['file_path_tesim'][0]
          else
            session[:alt_image] << result['file_path_tesim'][0]
          end
          count += 1
        end
      else
        q.solr_query('hasTarget_ssim:"' + next_id + '"', fl='file_path_tesim', 2, 'preflabel_si asc')['response']['docs'].map do |result|
          next_image = result['file_path_tesim'][0]
        end
      end

      session[:folio_id] = next_id
      session[:folio_image] = next_image

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end

  # set image and alt image (UV) in session
  def get_images_for_folio(folio_id)
    images = {}
    q = SolrQuery.new
    response = q.solr_query('has_model_ssim:Image and hasTarget_ssim:' + folio_id,
                            fl='preflabel_tesim,file_path_tesim',
                            2,
                            'preflabel_si asc')['response']
    if response['numFound'] > 0
      response['docs'].map do |result|
        if result['preflabel_tesim'].present?
          if result['preflabel_tesim'][0] == "Image (UV)"
            if result['file_path_tesim'].present?
              images[:alt_image] = result['file_path_tesim'][0]
            else
              images[:alt_image] = "Missing-alt-image-id-#{folio_id}"
            end
          else
            if result['file_path_tesim'].present?
              images[:folio_image] = result['file_path_tesim'][0]
            else
              images[:alt_image] = "Missing-folio-image-id-#{folio_id}"
            end
          end
        end
      end  
    end
    images
  end


    # Set @folio_list - this is used to display the folio drop-down list
  def set_folio_list

    begin

      @folio_list = []
      q = SolrQuery.new
      set_order
      # Get the list of folios in order
      @order.each_with_index do |o, i|
        q.solr_query('id:"' + o + '"', 'preflabel_tesim', rows=1)['response']['docs'].map.each do |res|
          num = i + 1
          @folio_list << [res['preflabel_tesim'][0], num.to_s]
        end
      end

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end

  # Return list of registers (fedora id, register id and title), in order
  # Don't use @order here as this is registers NOT folios
  def get_registers_in_order

    begin

      registers = Hash.new
      q = SolrQuery.new
      # Get the ordered list of registers

      q.solr_query('has_model_ssim:OrderedCollection', 'id',2)['response']['docs'].map.each do |result|
        collection = result['id']

        q.solr_query('id:"' + collection + '/list_source"', 'ordered_targets_ssim',1)['response']['docs'].map.each do |res|
          order = res['ordered_targets_ssim']
          order.each do |o|
            q.solr_query('id:"' + o + '"', 'id,preflabel_tesim,reg_id_tesim',45)['response']['docs'].map.each do |r|
              registers[r['id']] = [r['reg_id_tesim'][0], r['preflabel_tesim'][0]]
            end
          end
        end
      end

      registers

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end

  # Set the entry tab list (i.e. at the top of the form)
  def set_entry_list

    begin

      # This is an array of arrays ('id' and 'entry_no')
      @entry_list = []

      SolrQuery.new.solr_query(q='has_model_ssim:Entry AND folio_ssim:' + session[:folio_id], fl='id,entry_no_tesim', rows=1000, sort='entry_no_si asc')['response']['docs'].map.each do |result|
        id = result['id']
        entry_no = result['entry_no_tesim'].join
        temp = []
        temp[0] = id
        temp[1] = entry_no
        @entry_list << temp
      end

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end

  def get_entries(fol)
    begin
      session[:entries_exist] = []
      q = SolrQuery.new

      id = get_id(fol)

      current_entry_list = []
      q.solr_query('folio_ssim:"' + id + '"', 'id,entry_no_tesim', 100, 'entry_no_si asc')['response']['docs'].map.each do |result|
        #session[:entries_exist] << result['id']
        element_list = []
        id = result['id']
        entry_no = result['entry_no_tesim'].join
        element_list << id
        element_list << entry_no
        current_entry_list << element_list
      end
      # Sort entries by their numeric entry nos
      current_entry_list.sort! { |a, b|  a[1].to_i <=> b[1].to_i }
      current_entry_list.each do |entry|
        session[:entries_exist] << entry[0]
      end

      if session[:entries_exist] == []
        session[:entries_exist] = nil
      end
    end
  rescue => error
    log_error(__method__, __FILE__, error)
    raise
  end

  # get folio_id
  def get_folio(target)
    folio = SolrQuery.new.solr_query('id:"'+ target + '"',fl='folio_ssim',rows=1,'preflabel_si asc')['response']['docs'][0]['folio_ssim'][0]
    folio
  end

  def get_id(o)
    id = (o.include? '/') ? o.rpartition('/').last : o
  end

end