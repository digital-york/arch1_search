module RdfType
  extend ActiveSupport::Concern
  
  included do
    property :rdftype, predicate: ::RDF::RDFV.type, multiple: true do |index|
      index.as :stored_searchable
    end
  end

end