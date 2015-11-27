module SearchesHelper

  # Dereference id into a string for display purposes - e.g. test:101 -> 'abbey'
  def get_str_from_id(id, type)
    response = SolrQuery.new.solr_query(q='id:"' + id + '"', fl=type, rows='1')
    parse_terms_response(response, type);
  end

# General method to parse ids into strings (py)
  def parse_terms_response(response, type)

    str = ''

    response['response']['docs'].map do |result|
      if result['numFound'] != '0'
        str = result[type]
        if str.class == Array
          str = str.join() # 'join' is used to convert an array into a string because otherwise an error occurs
        end
      end
    end

    return str
  end

  # Set the folio and image session variables when the user selects an option from the drop-down list
  def get_folio_image(folio_id)

    folio_image = ''

    SolrQuery.new.solr_query('hasTarget_ssim:"' + folio_id + '"', 'file_path_tesim', 1)['response']['docs'].map do |result|
      folio_image = result['file_path_tesim'][0]
    end

    return folio_image
  end

end
