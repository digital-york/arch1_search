class EntryController < ApplicationController

  def index
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
      format.any { head :not_found }
    end
  end

  def show
    # get folio, redirect to search result page with params
    folio_id = get_folio(params[:id])
    if folio_id != ''
      redirect_to searches_show_path(entry_id: params[:id], folio_id: folio_id)
      # If an incorrect id is requested, redirect to the 404 page
    else
      respond_to do |format|
        format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
        format.any { head :not_found }
      end
    end
  end

  #whitelist params
  private
  # Using a private method to encapsulate the permissible parameters
  # is just a good pattern since you'll be able to reuse the same
  # permit list between create and update. Also, you can specialize
  # this method with per-user checking of permissible attributes.
  def entry_params
    params.require(:entry).permit(:id)
  end

end
