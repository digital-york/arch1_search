class HomePageController < ApplicationController
  layout 'simple_layout'

  before_action :set_layout_flag

  # Set flag so that background image height is greater than the other pages (see default_layout.html.erb)
  def set_layout_flag
    @is_home_page = true
  end
end
