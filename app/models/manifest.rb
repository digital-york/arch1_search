# require 'noid-rails'

class Manifest < ActiveFedora::File
  # include AssignId
  include ActiveFedora::WithMetadata

  metadata do
    property :preflabel, predicate: ::RDF::Vocab::SKOS.prefLabel, multiple: false do |index|
      index.as :stored_searchable, :sortable
    end
    configure type: RDF::URI.new('http://pcdm.org/models#File')
    configure type: RDF::URI.new('http://www.shared-canvas.org/ns/Manifest')
  end
end
