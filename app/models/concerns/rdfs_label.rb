module RdfsLabel
  extend ActiveSupport::Concern
  
  included do
    property :rdfslabel, predicate: ::RDF::RDF.label, multiple: true do |index|
      index.as :stored_searchable
    end
  end

end