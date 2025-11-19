# frozen_string_literal: true

class CreateViewsAndTriggers < ActiveRecord::Migration[8.1]
  def up
    # Create a view for user statistics
    execute <<~SQL
      CREATE VIEW user_stats AS
      SELECT
        u.id,
        u.email,
        COUNT(DISTINCT p.id) AS post_count,
        COUNT(DISTINCT c.id) AS comment_count
      FROM users u
      LEFT JOIN posts p ON p.user_id = u.id
      LEFT JOIN comments c ON c.user_id = u.id
      GROUP BY u.id, u.email
    SQL

    # Create a trigger to update timestamps
    execute <<~SQL
      CREATE TRIGGER update_posts_updated_at
      AFTER UPDATE ON posts
      FOR EACH ROW
      BEGIN
        UPDATE posts
        SET updated_at = datetime('now')
        WHERE id = NEW.id;
      END
    SQL

    # Create a trigger for comment counts
    execute <<~SQL
      CREATE TRIGGER update_post_comment_count
      AFTER INSERT ON comments
      FOR EACH ROW
      BEGIN
        UPDATE posts
        SET updated_at = datetime('now')
        WHERE id = NEW.post_id;
      END
    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS user_stats'
    execute 'DROP TRIGGER IF EXISTS update_posts_updated_at'
    execute 'DROP TRIGGER IF EXISTS update_post_comment_count'
  end
end
