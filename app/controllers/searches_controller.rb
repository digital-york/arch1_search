class SearchesController < ApplicationController

  def index

    puts params

    @search_term = params[:search_term]
    @page = params[:page]

    if params[:next] == 'true'
      @page = @page.to_i + 1
    elsif params[:previous] == 'true'
    puts 'previous!'
      @page = @page.to_i - 1
    else
      @page = 1
    end

    get_data(@search_term, @page)

  end

  def show

    @db_entry = DbEntry.new
    @db_entry.entry_id = params[:entry_id]

    # Populate db_entry with data from Solr
    get_solr_data(@db_entry)

    @folio_id = params[:folio_id]

    @entry_list = get_entry_list(@folio_id)

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
  puts "HERE2"
  end
end
