class TermsBase

  attr_reader :subauthority

  def initialize(subauthority)
    @subauthority = subauthority
  end

  # Gets the ConceptScheme, etc
  def terms_id
    parse_terms_id_response(SolrQuery.new.solr_query(q='rdftype_tesim:"http://www.w3.org/2004/02/skos/core#ConceptScheme" AND preflabel_tesim:"' + terms_list + '"','id',1))
  end

  def all
    # 'Languages' are sorted by id so that 'Latin' is first
    sort_order = 'preflabel_si asc'
    if terms_list == 'languages'
      sort_order = 'id asc'
    end
    parse_authority_response(SolrQuery.new.solr_query(q='inScheme_ssim:"' + terms_id + '"',fl='id,preflabel_tesim,definition_tesim,broader_tesim',rows=1000,sort=sort_order))
  end

  def find id
    parse_authority_response(SolrQuery.new.solr_query(q='inScheme_ssim:"' + terms_id + '" AND id:"' + id + '"',fl='id,preflabel_tesim,definition_tesim,broader_tesim','',1))
  end

  def find_id val
    parse_terms_id_response(SolrQuery.new.solr_query(q='inScheme_ssim:"' + terms_id + '" AND preflabel_tesim:"' + val + '"', fl='id',rows=1))
  end

  def find_value_string id
    parse_string(SolrQuery.new.solr_query(q='inScheme_ssim:"' + terms_id + '" AND id:"' + id + '"', fl='preflabel_tesim',rows=1))
  end

  def search q
    parse_authority_response(SolrQuery.new.solr_query(q='inScheme_ssim:"' + terms_id + '" AND preflabel_tesim:"' + q + '"',fl='id,preflabel_tesim,definition_tesim,broader_tesim',rows=1000))
  end

  # Dereference id into a string for display purposes - e.g. test:101 -> 'abbey'
  def get_str_from_id(id, type)
    response = SolrQuery.new.solr_query(q='id:"' + id + '"', fl=type, rows=1)
    parse_terms_response(response, type);
  end

  # Returns an array of hashes (top-level terms) which contain an array of hashes (middle-level terms), etc
  # These are dereferenced in the subjects pop-up to dispay the subject list
  def all_top_level_subject_terms

    # all_terms_list = []
    # middle_level_list = []
    # bottom_level_list = []

    top_level_list = parse_authority_response(SolrQuery.new.solr_query(q='istopconcept_tesim:true',fl='id,preflabel_tesim',rows=1000,sort='preflabel_si asc'))

    top_level_list.each_with_index do |t1, index|

      id = t1['id']

      middle_level_list = parse_authority_response(SolrQuery.new.solr_query(q='broader_tesim:' + id,fl='id,preflabel_tesim',rows=1000, sort='preflabel_si asc'))

      t1[:elements] = middle_level_list

      middle_level_list.each_with_index do |t2, index|

        id2 = t2['id']

        bottom_level_list = parse_authority_response(SolrQuery.new.solr_query(q='broader_tesim:' + id2,fl='id,preflabel_tesim',rows=1000, sort='preflabel_si asc'))

        t2[:elements] = bottom_level_list

      end

    end

    return top_level_list

  end

  # Returns an array of hashes (top-level terms) which contain an array of hashes (middle-level terms), etc
  # These are dereferenced in the subjects pop-up to dispay the subject list
  def get_subject_list_top_level

    top_level_list = parse_authority_response(SolrQuery.new.solr_query(q='istopconcept_tesim:true',fl='id,preflabel_tesim',rows=1000,sort='preflabel_si asc'))

    top_level_list.each_with_index do |t1, index|

      id = t1['id']

      second_level_list = parse_authority_response(SolrQuery.new.solr_query(q='broader_tesim:' + id,fl='id,preflabel_tesim',rows=1000, sort='preflabel_si asc'))

      t1[:elements] = second_level_list

      second_level_list.each_with_index do |t2, index|

        id2 = t2['id']

        third_level_list = parse_authority_response(SolrQuery.new.solr_query(q='broader_tesim:' + id2,fl='id,preflabel_tesim',rows=1000, sort='preflabel_si asc'))

        t2[:elements] = third_level_list
      end
    end

    return top_level_list
  end

  def get_subject_list_second_level(id)

    top_level_list = parse_authority_response(SolrQuery.new.solr_query(q='istopconcept_tesim:true AND id:' + id,fl='id,preflabel_tesim',rows=1000,sort='preflabel_si asc'))

    top_level_list.each do |t1|

      #id = t1['id']

      second_level_list = parse_authority_response(SolrQuery.new.solr_query(q='broader_tesim:' + id,fl='id,preflabel_tesim',rows=1000, sort='preflabel_si asc'))

      t1[:elements] = second_level_list

      second_level_list.each do |t2|

        id2 = t2['id']

        third_level_list = parse_authority_response(SolrQuery.new.solr_query(q='broader_tesim:' + id2,fl='id,preflabel_tesim',rows=1000, sort='preflabel_si asc'))

        t2[:elements] = third_level_list
      end
    end

    return top_level_list
  end


  private

  # Reformats the data received from the service
  def parse_authority_response(response)
    response['response']['docs'].map do |result|
      hash = {'id' => result['id'],
       'label' => if result['preflabel_tesim'] then result['preflabel_tesim'].join end,
       'definition' => if result['definition_tesim'] then result['definition_tesim'].join end
      }
      # Only add broader where it exists (ie. subjects)
      if result['broader_tesim']
        broader = result['broader_tesim'].join.split('/')
        hash['broader_id'] = broader[broader.length-1]
        hash['broader_label'] = find_value_string(broader[broader.length-1]).join
      end


      hash
    end
  end

  def parse_terms_id_response(response)
    id = ''
    response['response']['docs'].map do |result|
      id = result['id']
    end
    id
  end

  def parse_string(response)
    str = ''
    response['response']['docs'].map do |result|
      str = result['preflabel_tesim']
    end
    str
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

end
