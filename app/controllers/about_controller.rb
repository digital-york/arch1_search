# added (ja)
class AboutController < ApplicationController
  layout 'simple_layout'

  def index; end

  def registers
    render template: 'about/registers'
  end

  def further_resources
    render template: 'about/further_resources'
  end

  def search_help
    render template: 'about/search_help'
  end

  def technology
    render template: 'about/technology'
  end
end
