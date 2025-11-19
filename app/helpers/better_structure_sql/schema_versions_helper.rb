# frozen_string_literal: true

module BetterStructureSql
  # View helper methods for schema versions display
  #
  # Provides formatting methods for rendering schema version attributes
  # in the web UI, including badges and icons for output modes and format types.
  module SchemaVersionsHelper
    # Formats output mode as a Bootstrap badge with icon
    #
    # @param mode [String] the output mode ('multi_file' or 'single_file')
    # @return [String] HTML-safe badge element with icon
    def format_output_mode(mode)
      case mode
      when 'multi_file'
        content_tag(:span, class: 'badge bg-info') do
          concat content_tag(:i, '', class: 'bi bi-folder')
          concat ' Multi-File'
        end
      when 'single_file'
        content_tag(:span, class: 'badge bg-secondary') do
          concat content_tag(:i, '', class: 'bi bi-file-earmark')
          concat ' Single File'
        end
      else
        content_tag(:span, 'Unknown', class: 'badge bg-warning')
      end
    end

    # Formats format type as a Bootstrap badge with icon
    #
    # SQL format uses blue badge with SQL icon, Ruby format uses green
    # badge with Ruby icon.
    #
    # @param format_type [String] the format type ('sql' or 'rb')
    # @return [String] HTML-safe badge element with icon
    def format_type_badge(format_type)
      bg_class = format_type == 'sql' ? 'bg-primary' : 'bg-success'
      icon_class = format_type == 'sql' ? 'bi-filetype-sql' : 'bi-filetype-rb'
      content_tag(:span, class: "badge #{bg_class}") do
        concat content_tag(:i, '', class: "bi #{icon_class}")
        concat " #{format_type.upcase}"
      end
    end
  end
end
