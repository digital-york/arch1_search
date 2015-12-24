class PlaceTerms

  include Qa::Authorities::WebServiceBase
  include TermsHelper

  attr_reader :subauthority

  def initialize(subauthority)
    @subauthority = subauthority
  end

  # Gets the ConceptScheme, etc
  def terms_id
    parse_terms_id_response(SolrQuery.new.solr_query(q='rdftype_tesim:"http://www.w3.org/2004/02/skos/core#ConceptScheme" AND preflabel_tesim:"places"','',1))
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
    parse_terms_id_response(SolrQuery.new.solr_query(q='inScheme_ssim:"' + terms_id + '" AND preflabel_tesim:"' + val + '"', fl='id','',1))
  end

  def search q
    parse_authority_response(SolrQuery.new.solr_query(q='inScheme_ssim:"' + terms_id + '" AND preflabel_tesim:"' + q + '"', fl='',1000))
  end

  private

  # Reformats the data received from the service
  def parse_authority_response(response)
    response['response']['docs'].map do |result|
      geo = TermsHelper::Geo.new
      #al = geo.adminlevel(result['parentADM1_tesim'].first,result['parentADM2_tesim'].first)
      { 'id' => result['id'],
        #'label' => "#{result['preflabel_tesim'].first} (#{al})",
        'label' => result['preflabel_tesim'].join,
        'countrycode' => if result['parent_country_tesim'] then result['parent_country_tesim'].join end,
        'parentADM1' => if result['parent_ADM1_tesim'] then result['parent_ADM1_tesim'].join end,
        'parentADM2' => if result['parent_ADM2_tesim'] then result['parent_ADM2_tesim'].join end,
        'parentADM3' => if result['parent_ADM3_tesim'] then result['parent_ADM3_tesim'].join end,
        'parentADM4' => if result['parent_ADM4_tesim'] then result['parent_ADM4_tesim'].join end,
        'place name' => if result['place_name_tesim'] then result['place_name_tesim'].join end,
        'featuretype' => if result['feature_code_tesim'] then result['feature_code_tesim'].join end
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
