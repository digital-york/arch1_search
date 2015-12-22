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

  # Set the first and last folio session variables - this is used to grey out
  # the '<' and '>' icons if the limits are reached
  def set_first_and_last_folio

    @order = SolrQuery.new.solr_query('id:"' + session[:register_id] + '/list_source"', 'ordered_targets_ssim', 1)['response']['docs'][0]['ordered_targets_ssim']
    session[:first_folio_id] = @order[0]
    session[:last_folio_id] = @order[@order.length-1]
    # Timings indicate that this step for 5A (the longest register) took 26s; the new code took 4s
    #register = Register.find(session[:register_id])
    #session[:first_folio_id] = register.ordered_folio_proxies.first.target_id
    #session[:last_folio_id] = register.ordered_folio_proxies.last.target_id

  end

  # Set the folio and image session variables when the user selects an option from the drop-down list
  def set_folio_and_image_drop_down

    folio_id = params[:folio_id].strip

    session[:folio_id] = folio_id
    session[:alt_image] = []

    if folio_id == ''
      session[:folio_image] = ''
    else
      q = SolrQuery.new
      response = q.solr_query('hasTarget_ssim:"' + session[:folio_id] + '"', fl='file_path_tesim', 2, 'preflabel_si asc')['response']

      if response['numFound'] > 1
        count = 0
        response['docs'].map do |result|
          if count == 0
            session[:folio_image] = result['file_path_tesim'][0]
          else
            session[:alt_image] << result['file_path_tesim'][0]
          end
          count += 1
        end
      else
        q.solr_query('hasTarget_ssim:"' + session[:folio_id] + '"', fl='file_path_tesim', 2, 'preflabel_si asc')['response']['docs'].map do |result|
          session[:folio_image] = result['file_path_tesim'][0]
        end
      end
    end
  end

  # Set the folio and image session variables, e.g. when the '>' or '<' buttons are clicked
  # action = 'prev_tesim' or 'next_tesim'
  def set_folio_and_image(action, id)

    next_id = ''
    next_image = ''

    if action != nil #&& id != nil
      # convert the list of folios in order into a hash so we can access the position of our id
      hash = Hash[@order.map.with_index.to_a]
      if action == 'next_tesim'
        next_id = @order[hash[id].to_i + 1]
      elsif action == 'prev_tesim'
        next_id = @order[hash[id].to_i - 1]
      end
    end

    # Set the folio image session variable
    SolrQuery.new.solr_query('hasTarget_ssim:"' + next_id + '"', 'file_path_tesim', 1, sort='preflabel_si asc')['response']['docs'].map do |result|
      next_image = result['file_path_tesim'][0]
    end

    session[:alt_image] = []

    q = SolrQuery.new
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
  end

  # Set the next (or previous) folio and image session variables (when the '>' or '<' buttons are clicked)
  # action = 'prev_tesim' or 'next_tesim'
  def set_folio_and_image_browse(action, id)

    next_id = ''
    next_image = ''

    if action != nil and id != nil
      # convert the list of folios in order into a hash so we can access the position of our id
      hash = Hash[@order.map.with_index.to_a]
      if action == 'next_tesim'
        next_id = @order[hash[id].to_i + 1]
      elsif action == 'prev_tesim'
        next_id = @order[hash[id].to_i - 1]
      end
    end

    # Set the browse image
    SolrQuery.new.solr_query('hasTarget_ssim:"' + next_id + '"', 'file_path_tesim', 1)['response']['docs'].map do |result|
      next_image = result['file_path_tesim'][0]
    end

    session[:browse_id] = next_id
    session[:browse_image] = next_image
  end

  # Set @folio_list - this is used to display the folio drop-down list
  def set_folio_list

    @folio_list = []
    folio_hash = {}
    q = SolrQuery.new
    @order = q.solr_query('id:"' + session[:register_id] + '/list_source"', 'ordered_targets_ssim', 1)['response']['docs'][0]['ordered_targets_ssim']
    # Get the list of folios in order
    @order.each do |o|
      q.solr_query('id:"' + o + '"', 'id,preflabel_tesim', rows=1)['response']['docs'].map.each do |res|
        folio_hash[res['id']] = res['preflabel_tesim'].join()
        @folio_list += [[res['id'], folio_hash[res['id']]]]
      end
    end
  end

  # Determines which message is displayed when the user clicks the 'Continue' button
  def is_entry_on_next_folio

    next_folio_id = ''

    # First get the next_folio_id...
    # convert the list of folios in order into a hash so we can access the position of our id
    hash = Hash[@order.map.with_index.to_a]
    next_folio_id = @order[hash[session[:folio_id]].to_i + 1]


    @is_entry_on_next_folio = false

    # Then determine if an entry exists
    if next_folio_id != nil
      SolrQuery.new.solr_query('folio_ssim:"' + next_folio_id + '"', 'id', 1)['response']['docs'].map do |result|
        @is_entry_on_next_folio = true
      end
    end

    # Return value
    @is_entry_on_next_folio
  end

  # Determines if the 'Continues on next folio' row and 'Continues' button are to be displayed
  def is_last_entry(entry)
    @is_last_entry = false
    if entry != nil
      max_entry_no = get_max_entry_no_for_folio
      if entry.entry_no.to_i >= max_entry_no.to_i
        @is_last_entry = true
      end
    end
  end

  # Determines if this is the last entry on a folio which is continued from the previous folio
  # i.e. the previous folio 'continues_on' field is populated
  def is_last_entry_for_continues_on(entry)
    @is_last_entry_for_continues_on = false
    if entry != nil
      SolrQuery.new.solr_query('continues_on_tesim:' + session[:folio_id], 'id', 1, 'entry_no_si asc')['response']['docs'].map do |result|
        entry_count = SolrQuery.new.solr_query('folio_ssim:' + session[:folio_id], 'id', 100, 'id asc')['response']['docs'].map.size
        if entry_count <= 1
          @is_last_entry_for_continues_on = true
        end
      end
    end
  end

  # Determines if the 'New Entry' Tab and '(continues)' text are to be displayed
  def set_folio_continues_id

    @folio_continues_id = ''

    q = SolrQuery.new

    q.solr_query('folio_ssim:"' + session[:folio_id] + '"', 'id', 100)['response']['docs'].each do |result|
      entry_id = result['id']
      q.solr_query('id:"' + entry_id + '"', 'continues_on_tesim,entry_no_tesim', 1)['response']['docs'].each do |result|
        if result['continues_on_tesim'] != nil
          @folio_continues_id = result['entry_no_tesim'].join()
        end
      end
    end

    return @folio_continues_id
  end

  # Get the max entry no for the folio
  # i.e used to automate the entry no when adding a new entry
  def get_max_entry_no_for_folio

    max_entry_no = 0

    SolrQuery.new.solr_query('folio_ssim:"' + session[:folio_id] + '"', 'entry_no_tesim', 100)['response']['docs'].each do |result|

      entry_no = result['entry_no_tesim'].join('').to_i

      if entry_no > max_entry_no
        max_entry_no = entry_no
      end
    end

    # Return max_entry_no
    max_entry_no
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

  # Set the entry tab list (i.e. at the top of the form)
  def set_entry_list

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
  end

end
