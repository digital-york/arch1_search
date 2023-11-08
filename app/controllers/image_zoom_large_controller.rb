class ImageZoomLargeController < ApplicationController

  require 'net/http'

  layout 'image_zoom_large'

  def index
    @folio_uri = params[:folio_uri]
  end

end
