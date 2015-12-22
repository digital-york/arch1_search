class SearchesController < ApplicationController

  layout 'default_layout'

  def index

    begin

      # Set all the instance variables
      # These will also be passed back to the view page
      @search_term = params[:search_term]
      @page = params[:page]
      @section_type_facet = params[:section_type_facet]
      @subject_facet = params[:subject_facet]
      @person_as_written_facet = params[:person_as_written_facet]
      @place_as_written_facet = params[:place_as_written_facet]
      @display_type = params[:display_type]
      @number_of_rows = 0

      # This is how many characters need to be added before the search will work
      # Is turned off at the moment
      @minimum_search_chars = 0

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
      @person_as_written_facet_array = []
      @place_as_written_facet_array = []
      @subject_facet_array = []

      # Check if there are less than two characters entered into the search box
      # Note that this is for the server-side check and shouldn't happen in normal circumstances because there is a javascript check -->
      if @search_term != '*' && @search_term.length < @minimum_search_chars
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
        set_search_result_arrays
      end

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end

  def show

    begin

      # Create a new DbEntry model from the database tables
      @db_entry = DbEntry.new
      @db_entry.entry_id = params[:entry_id]

      # Populate db_entry with data from Solr
      get_solr_data(@db_entry)

      @folio_id = params[:folio_id]
      @folio_title = params[:folio_title]

      # @entry_list is used to get the tabs for the view page
      @entry_list = get_entry_list(@folio_id)

      @search_term = params[:search_term]
      @page = params[:page]

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

end
