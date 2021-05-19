module TnwCommon
    class SearchBuilderService
        attr :search_term, :start_date, :end_date, :archival_repository

        def initialize(search_term:, start_date:, end_date:, archival_repository:)
            # "Bishop Auckland" => "*Bishop* AND *Auckland*"
            @search_term = search_term.gsub(/\b/,"*").gsub(/\s/," AND ")
            # "" => "*"
            @start_date = start_date.empty? ? "*" : start_date
            @end_date = end_date.empty? ? "*" : end_date
            @archival_repository = archival_repository
        end

        def query
            return {
                q: "has_model_ssim:Entry AND suggest:(#{@search_term})", 
                fq: "entry_date_facet_ssim:[#{@start_date} TO #{end_date}]"
            } 
        end
        
    end
end
