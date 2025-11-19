# frozen_string_literal: true

module BetterStructureSql
  module SchemaVersionsHelper
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
