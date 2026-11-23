# frozen_string_literal: true

module BetterStructureSql
  # View helper methods for schema versions display
  #
  # Provides formatting methods for rendering schema version attributes
  # in the web UI, including badges and icons for output modes and format types.
  module SchemaVersionsHelper
    # Badge label, colour class and icon class per output mode
    OUTPUT_MODE_BADGES = {
      'multi_file' => %w[Multi-File text-bg-info bi-folder],
      'single_file' => ['Single File', 'text-bg-secondary', 'bi-file-earmark']
    }.freeze

    # Badge label, colour class and icon class per format type
    FORMAT_TYPE_BADGES = {
      'sql' => %w[SQL text-bg-primary bi-filetype-sql],
      'rb' => %w[RB text-bg-success bi-filetype-rb]
    }.freeze

    # Formats output mode as a Bootstrap badge with icon
    #
    # @param mode [String] the output mode ('multi_file' or 'single_file')
    # @return [String] HTML-safe badge element
    def format_output_mode(mode)
      schema_badge(OUTPUT_MODE_BADGES[mode])
    end

    # Formats format type as a Bootstrap badge with icon
    #
    # @param format_type [String] the format type ('sql' or 'rb')
    # @return [String] HTML-safe badge element
    def format_type_badge(format_type)
      schema_badge(FORMAT_TYPE_BADGES[format_type])
    end

    # Renders the creation time as a machine-readable <time> element
    #
    # @param version [SchemaVersion] the schema version
    # @return [String] HTML-safe time element
    def schema_version_timestamp(version)
      time_tag(version.created_at, version.created_at.strftime('%Y-%m-%d %H:%M:%S %Z'))
    end

    # Renders one previous/next entry of the index pagination
    #
    # @param label [String] the link text
    # @param page [Integer] the page the entry points to
    # @param enabled [Boolean] false renders a disabled, non-link entry
    # @return [String] HTML-safe list item
    def pagination_item(label, page, enabled:)
      return content_tag(:li, content_tag(:span, label, class: 'page-link'), class: 'page-item disabled') unless enabled

      link = link_to(label, schema_versions_path(page:), class: 'page-link')
      content_tag(:li, link, class: 'page-item')
    end

    private

    # Stored values never reach the markup: unknown ones render as "Unknown"
    def schema_badge(badge)
      label, colour_class, icon_class = badge || %w[Unknown text-bg-warning bi-question-circle]

      content_tag(:span, class: "badge #{colour_class}") do
        concat content_tag(:i, '', class: "bi #{icon_class}", 'aria-hidden': true)
        concat " #{label}"
      end
    end
  end
end
