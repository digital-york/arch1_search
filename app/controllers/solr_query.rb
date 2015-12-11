require 'rubygems'
require 'rsolr'
require 'rsolr-ext'

class SolrQuery

  CONN = RSolr.connect :url => SOLR[Rails.env]['url']

  def solr_query(q, fl='id', rows=0, sort='', start=0 )

    CONN.get 'select', :params => {
                         :q=>q,
                         :fl=>fl,
                         :rows=>rows,
                         :sort=>sort,
                         :start=>start
                     }
  end

  def solr_query_facets

    CONN.find :q=>'*', :wt=>'json', :rows=>0, :fl=> 'facet_counts', :facets=>{:fields=>['section_type_facet', 'person_as_written_facet', 'place_as_written_facet', 'subject_facet']}

  end

end