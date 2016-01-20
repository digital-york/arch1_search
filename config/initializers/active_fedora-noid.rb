require 'active_fedora/noid'

ActiveFedora::Noid.configure do |config|
  # Specify a different template for your repository's NOID IDs
  # To use ':' the namespace must be set in Fedora (fedora-node-types.cnd)
  # config.template = 'test:.zd'
  # config.template = 'yorkabp:.zd'
  # 30/9/2015 - agreed to use default noids
  config.statefile = ENV['NOID_PATH'] + 'noid-minter-state'
end

ActiveFedora::Base.translate_uri_to_id = ActiveFedora::Noid.config.translate_uri_to_id
ActiveFedora::Base.translate_id_to_uri = ActiveFedora::Noid.config.translate_id_to_uri
