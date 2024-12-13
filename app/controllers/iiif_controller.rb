class IiifController < ApplicationController
  include IiifHelper
  include SearchesHelper
  include RegisterFolioHelper
  layout 'default_layout'

  def index
    # get a list of registers so that we can show the manifest download button for each
    @manifests = {}
    get_collections(nil).each do |coll|
      @manifests = get_registers_in_order(coll[0]).merge(@manifests)
    end
  end

  # Support IIIF Image api URI Syntax:
  # /{scheme}://{server}{/prefix}/{identifier}/{region}/{size}/{rotation}/{quality}.{format}
  def show
    if params[:id] == 'manifest'
      # pass to the manifest method
      manifest
    elsif params[:id] == 'download'
      # pass to the download method
      download
    else
      image_source = get_tile_sources_for_folio(params[:id])
      # Convert it to IIIF API v2
      image_url = image_source.first.gsub(/\/info\.json/,"").gsub(/iiif\/3\/ark/,"iiif/2/ark")
      if image_url != ''
        if params[:region].nil? || params[:size].nil? || params[:rotation].nil? || params[:quality].nil? ||
           (params[:region] == '') || (params[:size] == '') || (params[:rotation] == '') || (params[:quality] == '')
           redirect_to image_url
        # Let IIP on dlib handle incorrect params
        # IIP will crash on requests for regions bigger than the width/height of the image; could deal with that here
        else
          redirect_to "#{image_url}/#{params[:region]}/#{params[:size]}/#{params[:rotation]}/#{params[:quality]}.jpg"
        end
      # If an incorrect id is requested, redirect to the 404 page
      else
        respond_to do |format|
          format.html { render file: "#{Rails.root}/public/404", layout: false, status: :not_found }
          format.any { head :not_found }
        end
      end
    end
  end

  # iiif/manifest
  def manifest
    if params[:register_id].nil? || (params[:register_id] == '')
      respond_to do |format|
        format.html { render file: "#{Rails.root}/public/404", layout: false, status: :not_found }
        format.any { head :not_found }
      end
    else
      # get manifest saved at Fedora 2017/08, Canvases contains wrong URL on
      render json: get_manifest(params[:register_id]), type: 'application/json'
    end
  rescue StandardError => e
    log_error(__method__, __FILE__, e)
    respond_to do |format|
      format.html { render file: "#{Rails.root}/public/404", layout: false, status: :not_found }
      format.any { head :not_found }
    end
  end

  # iiif/canvas
  def canvas
    if params[:folio_id].nil? || (params[:folio_id] == '')
      respond_to do |format|
        format.html { render file: "#{Rails.root}/public/404", layout: false, status: :not_found }
        format.any { head :not_found }
      end
    else
      # get canvas saved at Fedora 2017/08
      # We have errors in URLs on saved canvas json file ine Fedora, we cannot save updated version due to broken functonality after ActieFedora upgrade 2019
      # render json: get_canvas(params[:folio_id]), type: 'application/json'
      # Build dynamicly canvas
      render json: canvas_builder(params[:folio_id],nil), type: 'application/json'
    end
  rescue StandardError => e
    log_error(__method__, __FILE__, e)
    respond_to do |format|
      format.html { render file: "#{Rails.root}/public/404", layout: false, status: :not_found }
      format.any { head :not_found }
    end
  end

  # iiif/download
  def download
    if params[:folio_id].nil? || (params[:folio_id] == '')
      respond_to do |format|
        format.html { render file: "#{Rails.root}/public/404", layout: false, status: :not_found }
        format.any { head :not_found }
      end
    else
      folio_id = get_id(params[:folio_id])
      # restrict download size to 1000px
      image_path = "#{IIIF_ENV[Rails.env]['image_api_url']}#{get_folio_image_iiif(folio_id)}/full/1000,/0/default.jpg" 
      data = URI.open(image_path)
      send_data data.read, filename: "#{folio_id}.jpg", type: 'image/jpeg', disposition: 'attachment', stream: 'true', buffer_size: '4096'

    end
  rescue StandardError => e
    log_error(__method__, __FILE__, e)
    raise
  end

  # whitelist params
  private

  # Using a private method to encapsulate the permissible parameters
  # is just a good pattern since you'll be able to reuse the same
  # permit list between create and update. Also, you can specialize
  # this method with per-user checking of permissible attributes.
  def iiif_params
    params.require(:iiif).permit(:id, :register_id, :folio_id)
  end

  def get_id(o)
    id = (o.include? '/') ? o.rpartition('/').last : o
  end
end
