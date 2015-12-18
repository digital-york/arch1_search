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

end