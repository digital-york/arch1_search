module Generic
  extend ActiveSupport::Concern

  included do
    property :former_id, predicate: ::RDF::URI.new('http://dlib.york.ac.uk/ontologies/generic#formerIdentifier'), multiple: true do |index|
      index.as :stored_searchable
    end
    property :approved, predicate: ::RDF::URI.new('http://dlib.york.ac.uk/ontologies/generic#approved'), multiple: false do |index|
      index.as :stored_searchable
    end
    property :rules, predicate: ::RDF::URI.new('http://dlib.york.ac.uk/ontologies/generic#rules'), multiple: false do |index|
      index.as :stored_searchable
    end
    # boolean
    property :istopconcept, predicate: ::RDF::URI.new('http://dlib.york.ac.uk/ontologies/generic#isTopConcept'), multiple: false do |index|
      index.as :stored_searchable
    end
  end
end