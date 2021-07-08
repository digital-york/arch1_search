class SearchController < ApplicationController
  layout "simple_layout"

  def simple
    # Set all the instance variables
    # These will also be passed back to the view page
    # simple search
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @archival_repository = params[:archival_repository]
    # default search
    @search_term = params[:search_term]
    @page = params[:page]
    @register_facet = params[:register_facet]
    @section_type_facet = params[:section_type_facet]
    @subject_facet = params[:subject_facet]
    @person_same_as_facet = params[:person_same_as_facet]
    @place_same_as_facet = params[:place_same_as_facet]
    @date_facet = params[:date_facet]
    @display_type = params[:display_type]
    @number_of_rows = 0
    @search_type = params[:search_type]

    @display_type = "full display" if @display_type.nil?

    # This is how many characters need to be added before the search will work
    # Is turned off at the moment
    @minimum_search_chars = 3

    @search_term = "" if @search_term.nil?

    # Set rows_per_page = 10 by default
    @rows_per_page = if params[:rows_per_page].nil?
      10
    else
      params[:rows_per_page].to_i
    end

    # Initialise the arrays which display data on the page
    @partial_list_array = []

    # Check if there are less than minimum_search_chars entered into the search box
    # Note that this is for the server-side check and shouldn't happen in normal circumstances because there is a javascript check -->
    # Note that 'NO_SEARCH' is passed from the 'Search' link on the menu - i.e. don't search when coming from this link
    if (@search_term != "NO_SEARCH") && (@search_term != "*") && (@search_term.length < @minimum_search_chars)
      @error = true
      @page = 1

      # Else set the correct page and set the search result arrays
      # which are used by the view page
    else

      @search_term = "" if @search_term == "*"

      # Set the correct page
      @page = if params[:next] == "true"
        @page.to_i + 1
      elsif params[:previous] == "true"
        @page.to_i - 1
      elsif @page.nil? || @page == ""
        1
      else
        @page.to_i
      end

      # Set arrays which display data on the page
      # @search_type only set for browse searches
      if (@search_type == "subject") || (@search_type == "group") || (@search_type == "person") || (@search_type == "place")
        set_search_result_arrays(@search_type)
      else
        set_search_result_arrays
      end

      # If we come to this page from the 'Search' menu link, make sure to remove the search term otherwise it appears in the search box
      @search_term = "" if @search_term == "NO_SEARCH"
    end

  rescue => e
    log_error(__method__, __FILE__, e)
    raise
  end

  def advanced
      # Set all the instance variables
    # These will also be passed back to the view page
    # simple search
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @archival_repository = params[:archival_repository]
    # advanced search terms
    @all_sterms = params[:all_sterms]
    @exact_sterms = params[:exact_sterms]
    @any_sterms = params[:any_sterms]
    @none_sterms = params[:none_sterms]
    # other params
    @page = params[:page]
    @register_facet = params[:register_facet]
    @section_type_facet = params[:section_type_facet]
    @subject_facet = params[:subject_facet]
    @person_same_as_facet = params[:person_same_as_facet]
    @place_same_as_facet = params[:place_same_as_facet]
    @date_facet = params[:date_facet]
    @display_type = params[:display_type]
    @number_of_rows = 0
    @search_type = params[:search_type]

    # A hack until presentation code refactored.
    # @search_term used for highlights and 3 chars check
    @search_term = "#{@all_sterms} #{@exact_sterms} #{@any_sterms}"

    @display_type = "full display" if @display_type.nil?

    # This is how many characters need to be added before the search will work
    # Is turned off at the moment
    @minimum_search_chars = 3

    # Set rows_per_page = 10 by default
    @rows_per_page = if params[:rows_per_page].nil?
      10
    else
      params[:rows_per_page].to_i
    end

    # Initialise the arrays which display data on the page
    @partial_list_array = []

    # Check if there are less than minimum_search_chars entered into the search box
    # Note that this is for the server-side check and shouldn't happen in normal circumstances because there is a javascript check -->
    # Note that 'NO_SEARCH' is passed from the 'Search' link on the menu - i.e. don't search when coming from this link
    # Note @search_term NO SEARCH not implementd
    if (@search_term != "NO_SEARCH") && (@search_term != "*") && (@search_term.length < @minimum_search_chars)
      @error = true unless !@none_sterms.blank?
      @page = 1

      # Else set the correct page and set the search result arrays
      # which are used by the view page
    else

      @all_sterms = "" if @search_term == "*"

      # Set the correct page
      @page = if params[:next] == "true"
        @page.to_i + 1
      elsif params[:previous] == "true"
        @page.to_i - 1
      elsif @page.nil? || @page == ""
        1
      else
        @page.to_i
      end

      @search_type = "advanced" 
      @search_term = "#{@all_sterms} #{@exact_sterms} #{@any_sterms}"
      set_search_result_arrays(@search_type)
    end
    render layout: "advanced_layout"

  rescue => e
    log_error(__method__, __FILE__, e)
    raise  
  end

  def show
    # Create a new DbEntry model from the database tables
    @db_entry = DbEntry.new
    @db_entry.entry_id = params[:entry_id]

    # Populate db_entry with data from Solr
    get_solr_data(@db_entry)

    session[:folio_id] = params[:folio_id]
    @folio_id = params[:folio_id]
    @folio_title = if params[:folio_title].nil?
      get_folio_title(params[:entry_id])
    else
      params[:folio_title]
    end

    # @entry_list is used to get the tabs for the view page
    @entry_list = get_entry_list(@folio_id)

    @search_term = params[:search_term]
    @page = params[:page]
  rescue => e
    log_error(__method__, __FILE__, e)
    raise
  end
end
