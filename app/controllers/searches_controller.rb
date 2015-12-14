class SearchesController < ApplicationController

  layout 'default_layout'

  def index

    @search_term = params[:search_term]
    @page = params[:page]
    @number_of_rows = 0

if params[:rows_per_page] == nil
      @rows_per_page = 1
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
    if @search_term != '*' && @search_term.length < 0
      @error = true
      @page = 1
    else

    if @search_term == '*' then @search_term = '' end

    # Set the appropriate page
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
    set_search_result_arrays(@search_term, @page)
    set_facet_arrays
    end
  end

  def show

    @db_entry = DbEntry.new
    @db_entry.entry_id = params[:entry_id]

    # Populate db_entry with data from Solr
    get_solr_data(@db_entry)

    @folio_id = params[:folio_id]
    @folio_title = params[:folio_title]

    # Used to get the Tabs for the view page
    @entry_list = get_entry_list(@folio_id)

    @search_term = params[:search_term]
    @page = params[:page]

  end

end
