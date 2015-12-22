# added (ja)
class BrowseController < ApplicationController

  layout 'default_layout'
  include RegisterFolioHelper

  def index

  end

  # browse/registers
  def registers
    # Get collections
    @coll_list = get_collections
  end


end
