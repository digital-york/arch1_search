class HomePageController < ApplicationController

  layout 'searches'
  before_filter :set_layout_flag

  # Set flag so that background image height is greater than in the other pages
  def set_layout_flag
    @flag = true
  end


  def index
  end

  def create
  end

  def edit
  end

  def new
  end

  def update
  end

  def destroy
  end

end