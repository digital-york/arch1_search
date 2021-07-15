class ApplicationController < ActionController::Base
  helper Openseadragon::OpenseadragonHelper
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # include Solr
  include RegisterFolio
  include RegisterFolioHelper
  include TnwCommon::SimpleSearchHelper
end
