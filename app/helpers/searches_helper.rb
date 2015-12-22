module SearchesHelper

  # Dereference id into a string for display purposes - e.g. test:101 -> 'abbey'
  def get_str_from_id(id, type)
    response = SolrQuery.new.solr_query(q='id:"' + id + '"', fl=type, rows='1')
    parse_terms_response(response, type);
  end

  # General method to parse 'response' data into a string (used by get_str_from_id method above)
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

  # Return the folio_image location for the particular folio_id
  def get_folio_image(folio_id)

    folio_image = ''

    SolrQuery.new.solr_query('hasTarget_ssim:"' + folio_id + '"', 'file_path_tesim', 1)['response']['docs'].map do |result|
      folio_image = result['file_path_tesim'][0]
    end

    return folio_image
  end

  # Construct place same_as string for the view / edit pages
  def get_place_same_as(same_as)

    response = SolrQuery.new.solr_query(q='id:' + same_as, fl='preflabel_tesim', rows='1')

    place_same_as = nil

    response['response']['docs'].map do |result|

      place_same_as = result['preflabel_tesim'][0]

      if place_same_as == nil
        place_same_as = "ERROR"
      end
    end

    return place_same_as
  end

  # Construct person same_as string for the view / edit pages
  def get_person_same_as(same_as)

    response = SolrQuery.new.solr_query(q='id:' + same_as, fl='preflabel_tesim', rows='1')

    person_same_as = nil

    response['response']['docs'].map do |result|

      person_same_as = result['preflabel_tesim'][0]

      if person_same_as == nil
        person_same_as = "ERROR"
      end

    end

    return person_same_as
  end

end
