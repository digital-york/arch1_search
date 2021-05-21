require "rsolr"
# require 'rsolr-ext'

module TnwCommon
  class SolrQueryService
    attr_reader :query
    CONN = RSolr.connect(url: SOLR[Rails.env]["url"])

    def initialize(query:)
      @query = query
    end

    def get
        binding.pry
      CONN.get("select", params: @query)
    end
  end
end
