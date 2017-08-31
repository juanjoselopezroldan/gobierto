# frozen_string_literal: true

require_dependency "gobierto_participation"

module GobiertoParticipation
  class Contribution < ApplicationRecord
    include GobiertoCommon::Searchable
    include GobiertoCommon::Sluggable
    include GobiertoParticipation::Flaggable
    include GobiertoParticipation::Votable

    belongs_to :user
    belongs_to :site
    belongs_to :contribution_container
    has_many :comments, as: :commentable

    algoliasearch_gobierto do
      attribute :site_id, :updated_at, :title, :description
      searchableAttributes ["title", "description"]
      attributesForFaceting [:site_id]
      add_attribute :resource_path, :class_name
    end

    validates :title, :description, :user, :contribution_container, presence: true

    scope :sort_by_created_at, -> { reorder(created_at: :desc) }
    # scope :sort_by_votes , -> { reorder(hot_score: :desc) }

    def parameterize
      { slug: slug }
    end

    def attributes_for_slug
      [title]
    end

    def number_participants
      user_ids = comments.map(&:user_id) + votes.map(&:user_id)
      user_ids.uniq
      user_ids.size
    end

    def resource_path
      Rails.application.routes.url_helpers.gobierto_participation_process_process_contribution_container_process_contribution_path(
        process_id: contribution_container.process.slug,
        process_contribution_container_id: contribution_container.slug,
        id: slug
      )
    end

    def self.javascript_json
      all.to_json(only: :title, methods: [:resource_path])
    end
  end
end
