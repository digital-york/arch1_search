class IiifController < ApplicationController
  include IiifHelper
  layout 'default_layout'

  def index
    # get a list of registers so that we can show the manifest download button for each
    @manifests = Hash.new
    get_collections(nil).each do | coll |
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
      #pass to the download method
      download
    else
      image = get_image(params[:id])
      if image != ''
        if params[:region].nil? or params[:size].nil? or params[:rotation].nil? or params[:quality].nil? or
            params[:region] == '' or params[:size] == '' or params[:rotation] == '' or params[:quality] == ''
          redirect_to "http://dlib.york.ac.uk/cgi-bin/iipsrv.fcgi?IIIF=#{image}/info.json"
        # Let IIP on dlib handle incorrect params
        # IIP will crash on requests for regions bigger than the width/height of the image; could deal with that here
        else
          redirect_to "http://dlib.york.ac.uk/cgi-bin/iipsrv.fcgi?IIIF=#{image}/#{params[:region]}/#{params[:size]}/#{params[:rotation]}/#{params[:quality]}.jpg"
        end
      # If an incorrect id is requested, redirect to the 404 page
      else
        respond_to do |format|
          format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
          format.any { head :not_found }
        end
      end
    end
  end

  # iiif/manifest
  def manifest
    begin
      if params[:register_id].nil? or params[:register_id] == ''
        respond_to do |format|
          format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
          format.any { head :not_found }
        end
      else
        render :json => get_manifest(params[:register_id]), :type => 'application/json'
      end
    rescue => error
      log_error(__method__, __FILE__, error)
      respond_to do |format|
        format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
        format.any { head :not_found }
      end
    end
  end

  # iiif/download
  def download
    begin
      if params[:folio_id].nil? or params[:folio_id] == ''
        respond_to do |format|
          format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
          format.any { head :not_found }
        end
      else
        image = get_image(params[:folio_id])
        # restrict download size to 1000px
        data = open("http://dlib.york.ac.uk/cgi-bin/iipsrv.fcgi?IIIF=#{image}/full/1000,/0/default.jpg")
        send_data data.read, :filename => "#{params[:folio_id]}.jpg", :type => "image/jpeg", :disposition => 'attachment', :stream => 'true', :buffer_size => '4096'

      end
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  #whitelist params
  private
  # Using a private method to encapsulate the permissible parameters
  # is just a good pattern since you'll be able to reuse the same
  # permit list between create and update. Also, you can specialize
  # this method with per-user checking of permissible attributes.
  def iiif_params
    params.require(:iiif).permit(:id,:register_id,:folio_id)
  end
end
