class SearchController < ApplicationController
  layout "simple_layout"

  def simple
    # Set all the instance variables
    # These will also be passed back to the view page
    @search_term = params[:search_term]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @archival_repository = params[:archival_repository]

    #What sanitasion do we need for search_term *, minimum list of caracters etc.?
    #if @search_term.nil? then @search_term = "" end
     
    # Initialise the arrays which display data on the page
    @partial_list_array = []
    # @section_type_facet_array = []
    # @person_same_as_facet_array = []
    # @place_same_as_facet_array = []
    # @subject_facet_array = []
    # @date_facet_array = []
    # @register_facet_array = []

    search_builder = TnwCommon::SearchBuilder.new(
      search_term: @search_term,
      start_date: @start_date,
      end_date: @end_date,
      archival_repository: @archival_repository
    )

  rescue => error
    log_error(__method__, __FILE__, error)
    raise
  end
end
