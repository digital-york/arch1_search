class DbRelatedPlace < ActiveRecord::Base

  belongs_to :db_entry
  has_many :db_place_as_writtens
  has_many :db_place_types
  has_many :db_place_roles
  has_many :db_place_notes

  def add_rdf_types
    ['http://dlib.york.ac.uk/ontologies/borthwick-registers#RelatedPlace','http://schema.org/Place']
  end
end
