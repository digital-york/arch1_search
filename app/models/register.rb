class Register < ActiveFedora::Base
  include ThumbnailUrl
  include AssignRdfTypes
  include SkosLabels
  include Generic
  include AssignId
  include RdfType
  include DCTerms
  # require 'active_fedora/aggregation'

  # has_many :folios, :dependent => :destroy
  # belongs_to :ordered_collection, predicate: ::RDF::DC.isPartOf
  # accepts_nested_attributes_for :folios, :allow_destroy => true, :reject_if => :all_blank
  # ordered_aggregation :folios, through: :list_source
  # directly_contains :associated_files, has_member_relation: ::RDF::URI.new("http://pcdm.org/models#hasFile"), class_name: 'ContainedFile'

  # contains 'manifest', predicate: ::RDF::URI.new('http://pcdm.org/models#hasFile'), class_name: 'Manifest'
  # deprecated AF > 9.3. When commented out it behaves as
  # [1] pry(#<IiifController>)> register.manifest.class
  # => ActiveFedora::File
  # Access to File content works
  # [5] pry(#<IiifController>)> register.manifest.content.size
  # => 514052
  # Access to preflable doesn't work as per property at manifest.rb model
  # Access to checksum and get_fixity doesn't wotk https://www.rubydoc.info/gems/active-fedora/ActiveFedora/File

  # Experiemnt with different assosiations, no errors but no method to read Manifest content
  # directly_contains :manifest, has_member_relation: ::RDF::URI.new('http://pcdm.org/models#hasFile'), class_name: 'Manifest'
  # [4] pry(#<IiifController>)> register.manifest.inspect
  # => "[]"
  # [5] pry(#<IiifController>)> register.manifest.class
  # => ActiveFedora::Associations::ContainerProxy

  property :reg_id, predicate: ::RDF::URI.new('http://dlib.york.ac.uk/ontologies/borthwick-registers#reference'), multiple: false do |index|
    index.as :stored_searchable, :sortable
  end

  property :access_provided_by, predicate: ::RDF::URI.new('http://data.archiveshub.ac.uk/def/accessProvidedBy'), multiple: false do |index|
    index.as :stored_searchable
  end
end
