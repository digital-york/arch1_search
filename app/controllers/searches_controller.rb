require 'tnw_common/solr/solr_query'
require 'tnw_common/tna/tna_search'

class SearchesController < ApplicationController

  layout 'default_layout'

  def index

    begin

      # Set all the instance variables
      # These will also be passed back to the view page
      @search_term = params[:search_term]
      @page = params[:page]
      @register_facet= params[:register_facet]
      @section_type_facet = params[:section_type_facet]
      @subject_facet = params[:subject_facet]
      @person_same_as_facet = params[:person_same_as_facet]
      @place_same_as_facet = params[:place_same_as_facet]
      @date_facet = params[:date_facet]
      @display_type = params[:display_type]
      @number_of_rows = 0
      @search_type = params[:search_type]

      if @display_type == nil
        @display_type = 'full display'
      end

      # This is how many characters need to be added before the search will work
      # Is turned off at the moment
      @minimum_search_chars = 3

      if @search_term == nil then @search_term = '' end

      # Set rows_per_page = 10 by default
      if params[:rows_per_page] == nil
        @rows_per_page = 10
      else
        @rows_per_page = params[:rows_per_page].to_i
      end

      # Initialise the arrays which display data on the page
      @partial_list_array = []
      @section_type_facet_array = []
      @person_same_as_facet_array = []
      @place_same_as_facet_array = []
      @subject_facet_array = []
      @date_facet_array = []
      @register_facet_array = []

      # Check if there are less than minimum_search_chars entered into the search box
      # Note that this is for the server-side check and shouldn't happen in normal circumstances because there is a javascript check -->
      # Note that 'NO_SEARCH' is passed from the 'Search' link on the menu - i.e. don't search when coming from this link
      if @search_term != 'NO_SEARCH' and @search_term != '*' and @search_term.length < @minimum_search_chars
        @error = true
        @page = 1

        # Else set the correct page and set the search result arrays
        # which are used by the view page
      else

        if @search_term == '*' then
          @search_term = ''
        end

        # Set the correct page
        if params[:next] == 'true'
          @page = @page.to_i + 1
        elsif params[:previous] == 'true'
          @page = @page.to_i - 1
        elsif @page == nil || @page == ''
          @page = 1
        else
          @page = @page.to_i
        end

        # Set arrays which display data on the page
        # @search_type only set for browse searches
        if @search_type == 'subject' or @search_type == 'group' or @search_type == 'person' or @search_type == 'place'
          set_search_result_arrays(@search_type)
        else
          set_search_result_arrays
        end

        # If we come to this page from the 'Search' menu link, make sure to remove the search term otherwise it appears in the search box
        if @search_term == 'NO_SEARCH' then @search_term = '' end
      end

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end

  def show
    solr_server = TnwCommon::Solr::SolrQuery.new(SOLR[Rails.env]['url'])
    tna_search = TnwCommon::Tna::TnaSearch.new(solr_server)

    begin
      if not params[:entry_id].blank?
        # Create a new DbEntry model from the database tables
        @db_entry = DbEntry.new
        @db_entry.entry_id = params[:entry_id]

        # Populate db_entry with data from Solr
        get_solr_data(@db_entry)

        session[:folio_id] = params[:folio_id]
        @folio_id = params[:folio_id]
        if params[:folio_title].nil?
          @folio_title = get_folio_title(params[:entry_id])
        else
          @folio_title = params[:folio_title]
        end


        # @entry_list is used to get the tabs for the view page
        @entry_list = get_entry_list(@folio_id)

        @search_term = params[:search_term]
        @page = params[:page]
      elsif not params[:document_id].blank?
        @document_id = params[:document_id]
        @document_json = tna_search.get_document_json(@document_id)
        @tna_place_of_datings = tna_search.get_place_of_datings(@document_id)
        @tna_places = tna_search.get_tna_places(@document_id)
        @dates = tna_search.get_dates(@document_id)
      end

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

end
