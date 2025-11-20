# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Generates COMMENT ON statements for database objects
    #
    # Supports PostgreSQL and MySQL comment syntax.
    # MySQL uses ALTER TABLE syntax for table/column comments.
    class CommentGenerator < Base
      # Generates COMMENT ON statement
      #
      # @param comment_data [Hash] Comment metadata with :object_type, :object_name, :comment
      # @return [String] SQL statement
      def generate(comment_data)
        object_type = comment_data[:object_type]
        object_name = comment_data[:object_name]
        comment_text = comment_data[:comment]

        # Escape single quotes in comment
        escaped_comment = comment_text.gsub("'", "''")

        case object_type
        when :table
          generate_table_comment(object_name, escaped_comment)
        when :column
          generate_column_comment(object_name, escaped_comment)
        when :index
          generate_index_comment(object_name, escaped_comment)
        when :view
          generate_view_comment(object_name, escaped_comment)
        when :function
          generate_function_comment(object_name, escaped_comment)
        else
          raise ArgumentError, "Unknown object type: #{object_type}"
        end
      end

      private

      # Generate comment for table
      #
      # @param table_name [String] Table name
      # @param comment [String] Comment text (already escaped)
      # @return [String] SQL statement
      def generate_table_comment(table_name, comment)
        if mysql_adapter?(detect_adapter_name)
          # MySQL uses ALTER TABLE syntax
          "ALTER TABLE #{quote_identifier(table_name)} COMMENT '#{comment}';"
        else
          # PostgreSQL uses COMMENT ON
          "COMMENT ON TABLE #{quote_identifier(table_name)} IS '#{comment}';"
        end
      end

      # Generate comment for column
      #
      # @param column_identifier [String] Format: "table_name.column_name"
      # @param comment [String] Comment text (already escaped)
      # @return [String] SQL statement
      def generate_column_comment(column_identifier, comment)
        table_name, column_name = column_identifier.split('.')

        if mysql_adapter?(detect_adapter_name)
          # MySQL requires full column definition in ALTER TABLE
          # This is a limitation - we'd need to fetch column type, which is complex
          # For now, return a comment indicating manual update needed
          "-- MySQL column comment (requires full ALTER TABLE with column definition):\n" \
            "-- ALTER TABLE #{quote_identifier(table_name)} MODIFY COLUMN #{quote_identifier(column_name)} <type> COMMENT '#{comment}';"
        else
          # PostgreSQL supports COMMENT ON COLUMN
          "COMMENT ON COLUMN #{quote_identifier(table_name)}.#{quote_identifier(column_name)} IS '#{comment}';"
        end
      end

      # Generate comment for index
      #
      # @param index_name [String] Index name
      # @param comment [String] Comment text (already escaped)
      # @return [String] SQL statement
      def generate_index_comment(index_name, comment)
        # Only PostgreSQL supports index comments
        if mysql_adapter?(detect_adapter_name)
          '-- MySQL does not support index comments'
        else
          "COMMENT ON INDEX #{quote_identifier(index_name)} IS '#{comment}';"
        end
      end

      # Generate comment for view
      #
      # @param view_name [String] View name
      # @param comment [String] Comment text (already escaped)
      # @return [String] SQL statement
      def generate_view_comment(view_name, comment)
        # Only PostgreSQL supports view comments
        if mysql_adapter?(detect_adapter_name)
          '-- MySQL does not support view comments'
        else
          "COMMENT ON VIEW #{quote_identifier(view_name)} IS '#{comment}';"
        end
      end

      # Generate comment for function
      #
      # @param function_name [String] Function name
      # @param comment [String] Comment text (already escaped)
      # @return [String] SQL statement
      def generate_function_comment(function_name, comment)
        # Only PostgreSQL supports function comments
        if mysql_adapter?(detect_adapter_name)
          '-- MySQL does not support function comments'
        else
          "COMMENT ON FUNCTION #{quote_identifier(function_name)} IS '#{comment}';"
        end
      end
    end
  end
end
