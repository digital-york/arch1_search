class SearchesController < ApplicationController

  layout 'searches'

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

    # Get the data to display on the page (depending on the search term and page)
    #get_data(@search_term, @page)
    get_data2(@search_term, @page)

  end

  def show

    @db_entry = DbEntry.new
    @db_entry.entry_id = params[:entry_id]

    # Populate db_entry with data from Solr
    get_solr_data(@db_entry)

    @folio_id = params[:folio_id]

    # Used to get the Tabs for the view page
    @entry_list = get_entry_list(@folio_id)

    @search_term = params[:search_term]
    @page = params[:page]

  end

  def new
  end

  def edit
  end

  def create
  end

  def update
  end

  def destroy
  end

  def index2
  end
end
