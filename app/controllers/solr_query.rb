require 'rubygems'
require 'rsolr'

class SolrQuery

  CONN = RSolr.connect :url => SOLR[Rails.env]['url']

  def solr_query(q, fl='id', rows=10, sort='', start=0 )

    CONN.get 'select', :params => {
                         :q=>q,
                         :fl=>fl,
                         :rows=>rows,
                         :sort=>sort,
                         :start=>start
                     }
  end

require 'rsolr-ext'

  CONN2 = RSolr::Ext.connect :url => SOLR[Rails.env]['url']

  def solr_query2

    CONN2.find :q=>'*', :wt=>'json', :rows=>0, :fl=> 'facet_counts', :facets=>{:fields=>['section_type_facet', 'person_as_written_facet', 'place_as_written_facet', 'subject_facet']}

  end

end