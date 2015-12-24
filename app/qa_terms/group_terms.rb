class GroupTerms

  include Qa::Authorities::WebServiceBase

  attr_reader :subauthority

  def initialize(subauthority)
    @subauthority = subauthority
  end

  # Gets the ConceptScheme, etc
  def terms_id
    parse_terms_id_response(SolrQuery.new.solr_query(q='rdftype_tesim:"http://www.w3.org/2004/02/skos/core#ConceptScheme" AND preflabel_tesim:"groups"','',1))
  end

  def all
    #sort_order = 'preflabel_si asc'
    #parse_authority_response(SolrQuery.new.solr_query(q='inScheme_ssim:"' + terms_id + '"',fl='',rows=1000,sort=sort_order))
    ['terms is not supported; use search or show']
  end

  def internal_all
    sort_order = 'preflabel_si asc'
    parse_authority_response(SolrQuery.new.solr_query(q='inScheme_ssim:"' + terms_id + '"',fl='',rows=5000,sort=sort_order))
  end

  def find id
    parse_authority_response(SolrQuery.new.solr_query(q='inScheme_ssim:"' + terms_id + '" AND id:"' + id + '"','',1))
  end

  def find_id val
    parse_terms_id_response(SolrQuery.new.solr_query(q='inScheme_ssim:"' + terms_id + '" AND preflabel_tesim:"' + val + '"', fl='id',1))
  end

  def search q
    parse_authority_response(SolrQuery.new.solr_query(q='inScheme_ssim:"' + terms_id + '" AND preflabel_tesim:"' + q + '"', fl='',1000))
  end

  private

  # Reformats the data received from the service
  def parse_authority_response(response)
    response['response']['docs'].map do |result|

      { 'id' => result['id'],
        'label' => result['preflabel_tesim'].join,
        'name' => if result['name_tesim'] then result['name_tesim'].join end,
        'dates' => if result['dates_tesim'] then result['dates_tesim'].join end,
        'qualifier' => if result['qualifier_tesim'] then result['qualifier_tesim'].join end,
        'note' => if result['note_tesim'] then result['note_tesim'].join end,
        'related_authority' => if result['related_authority_tesim'] then result['related_authority_tesim'] end,
        'variants' => if result['altlabel_tesim'] then result['altlabel_tesim'] end
      }
    end
  end

  def parse_terms_id_response(response)
    i = ''
    response['response']['docs'].map do |result|
      i = result['id']
    end
    i
  end

end
