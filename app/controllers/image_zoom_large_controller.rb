class ImageZoomLargeController < ApplicationController

  require 'net/http'

  layout 'image_zoom_large'

  def index
    @folio_id = params[:folio_id]
  end

  def alt

  end
end
