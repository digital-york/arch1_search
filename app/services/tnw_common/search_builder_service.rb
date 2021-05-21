module TnwCommon
  class SearchBuilderService
    attr :search_term, :start_date, :end_date, :archival_repository, :parrams

    def initialize(search_term:, start_date:, end_date:, archival_repository:)
      # "Bishop Auckland" => "*Bishop* AND *Auckland*"
      @search_term = search_term.gsub(/\b/, "*").gsub(/\s/, " AND ")
      # "" => "*"
      @start_date = start_date.empty? ? "*" : start_date
      @end_date = end_date.empty? ? "*" : end_date
      @archival_repository = archival_repository
      @params = {
        q: nil,
        fl: "id",
        rows: 0,
        sort: "",
        start: 0,
        facet: false,
        "facet.limit": nil,
        "facet.sort": nil,
        "facet.field": nil, # supply a string or an array
        fq: nil # supply a string or an array
      }
    end

    def query
      @params.merge({
        q: "has_model_ssim:Entry AND suggest:(#{@search_term})",
        fq: "entry_date_facet_ssim:[#{@start_date} TO #{end_date}]"
      })
    end
  end
end
