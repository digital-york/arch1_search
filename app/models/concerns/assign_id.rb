module AssignId
  extend ActiveSupport::Concern

  included do
    require 'active_fedora/noid'
  end

  # Called automatically by the noid service
  def assign_id
    noid_service.mint
  end

  # Use for direct containers (ldp:contains)
  def create_container_id(parent)
    if self.class.name == 'ContainedFile'
      "#{parent}/files/#{noid_service.mint}"
    else
      "#{parent}/#{self.class.name.pluralize.downcase}/#{noid_service.mint}"
    end
  end

  # Use for basic containers (ldp:contains)
  def create_id(parent)
    "#{parent}/#{noid_service.mint}"
  end

  private
  def noid_service
    @noid_service ||= ActiveFedora::Noid::Service.new
  end

end