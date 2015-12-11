class SearchesController < ApplicationController

  layout 'default_layout'

  def index

    @search_term = params[:search_term]
    @page = params[:page]

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

    # Set the arrays which display the search results
    set_search_result_arrays(@search_term, @page)

    # Set the arrays which display the facets
    set_facet_arrays

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
