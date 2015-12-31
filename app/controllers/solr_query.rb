require 'rubygems'
require 'rsolr'
require 'rsolr-ext'

# This class connects to solr and executes the query
# It uses default parameters, e.g. rows=10, if the parameters aren't passed to the method
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