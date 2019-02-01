class NorthernwayController < ApplicationController
  layout 'northernway_layout'

  before_filter :set_layout_flag

  # Set flag so that background image height is greater than the other pages
  # (see default_layout.html.erb)
  def set_layout_flag
    @is_home_page = true
  end

  def index; end
end
