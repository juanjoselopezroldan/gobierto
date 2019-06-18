# frozen_string_literal: true

module GobiertoCommon
  class CustomField < ApplicationRecord
    include GobiertoCommon::Sortable

    belongs_to :site
    belongs_to :instance, polymorphic: true
    has_many :records, dependent: :destroy, class_name: "CustomFieldRecord"
    validates :name, presence: true

    enum field_type: { localized_string: 0,
                       string: 1,
                       localized_paragraph: 2,
                       paragraph: 3,
                       single_option: 4,
                       multiple_options: 5,
                       color: 6,
                       image: 7,
                       data_grid: 8,
                       vocabulary_options: 9,
                       plugin: 10 }

    scope :sorted, -> { order(position: :asc) }
    scope :localized, -> { where(field_type: [:localized_string, :localized_paragraph]) }
    scope :not_localized, -> { where.not(field_type: [:localized_string, :localized_paragraph]) }

    translates :name

    before_create :set_uid, :set_position
    after_validation :check_depending_uids

    def self.field_types_with_options
      field_types.select { |key, _| /option/.match(key) }
    end

    def self.field_types_with_vocabulary
      field_types.select { |key, _| /vocabulary/.match(key) }
    end

    def self.available_options
      [:single_select, :multiple_select, :tags]
    end

    def long_text?
      /paragraph/.match field_type
    end

    def self.searchable_fields
      [:localized_string, :string, :localized_paragraph, :paragraph]
    end

    def has_options?
      /option/.match?(field_type)
    end

    def has_vocabulary?
      if (plugin_type = options&.dig(*%w(configuration plugin_type))&.to_sym)
        self.class.has_vocabulary?(plugin_type)
      else
        /vocabulary/.match?(field_type)
      end
    end

    def has_localized_value?
      /localized/.match?(field_type)
    end

    def localized_options(locale)
      options.map do |id, translations|
        [translations[locale.to_s], id]
      end
    end

    def vocabulary_id
      return unless has_vocabulary? && options.present?

      options.dig "vocabulary_id"
    end

    def vocabulary
      site.vocabularies.find_by(id: vocabulary_id)
    end

    def configuration
      @configuration ||= OpenStruct.new(
        (options || {}).dig("configuration") || {}
      )
    end

    private

    def self.has_vocabulary?(plugin_type)
      plugin = CustomFieldPlugin.all.find { |p| p.type == plugin_type.to_sym }

      plugin && plugin.requires_vocabulary?
    end

    def set_uid
      self.uid ||= SecureRandom.uuid
    end

    def set_position
      self.position = begin
                        self.class.where(site_id: site_id, class_name: class_name).maximum(:position).to_i + 1
                      end
    end

    def check_depending_uids
      return unless changes[:uid].present?

      records.where("payload->>? IS NOT NULL", uid_was).each do |record|
        record.update_attribute(
          :payload,
          record.payload.tap do |hash|
            hash[uid] = hash.delete uid_was
          end
        )
      end
    end
  end
end
