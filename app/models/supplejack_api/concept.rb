# The majority of the Supplejack API code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ and 
# the Department of Internal Affairs. http://digitalnz.org/supplejack

module SupplejackApi
  class Concept
    include Support::Storable
    include Support::Searchable
    include Support::Harvestable
    include Support::FragmentHelpers
    include ActiveModel::SerializerSupport

    attr_accessor :should_index_flag
    
    # Associations
    embeds_many :fragments, cascade_callbacks: true, class_name: 'SupplejackApi::ApiConcept::ConceptFragment'
    embeds_one :merged_fragment, class_name: 'SupplejackApi::ApiConcept::ConceptFragment'

    # From storable
    store_in collection: 'concepts'
    index({ concept_id: 1 }, { unique: true })
    auto_increment :concept_id, session: 'strong'

    # TODO Move these indexes to ConceptFragment? 
    index label: 1
    index name: 1
    index gender: 1
    index dateOfBirth: 1
    index dateOfDeath: 1
    index type: 1

    # Callbacks
    before_save :merge_fragments

    # Scopes
    scope :active, where(status: 'active')
    scope :deleted, where(status: 'deleted')
    scope :suppressed, where(status: 'suppressed')
    scope :solr_rejected, where(status: 'solr_rejected')

    def active?
      self.status == 'active'
    end
  
    def should_index?
      return should_index_flag if !should_index_flag.nil?
      active?
    end

    def fragment_class
      SupplejackApi::ApiConcept::ConceptFragment
    end

  end
end
