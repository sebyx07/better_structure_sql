# frozen_string_literal: true

module BetterStructureSql
  class Formatter
    attr_reader :config

    def initialize(config = BetterStructureSql.configuration)
      @config = config
    end

    def format(content)
      sections = parse_sections(content)
      formatted = sections.map { |section| format_section(section) }

      if config.add_section_spacing
        formatted.join("\n\n")
      else
        formatted.join("\n")
      end
    end

    def format_section(section)
      # Normalize whitespace
      lines = section.split("\n").map(&:rstrip)

      # Remove excessive blank lines
      lines = collapse_blank_lines(lines)

      lines.join("\n")
    end

    private

    def parse_sections(content)
      # Split content into logical sections based on SQL comments and statement types
      content.split(/(?=--\s+\w+\n)/).reject(&:empty?)
    end

    def collapse_blank_lines(lines)
      result = []
      previous_blank = false

      lines.each do |line|
        current_blank = line.strip.empty?

        if current_blank
          result << line unless previous_blank
        else
          result << line
        end

        previous_blank = current_blank
      end

      result
    end
  end
end
