# frozen_string_literal: true

# MySQL adaptation: Stored procedures and triggers using MySQL syntax
class CreateStoredProceduresAndTriggers < ActiveRecord::Migration[8.1]
  def up
    # MySQL requires DELIMITER for procedures, but ActiveRecord can't handle DELIMITER.
    # Solution: Use client.query which can execute multi-statement procedures
    reversible do |dir|
      dir.up do
        # Drop if exists to allow re-running migration
        connection.execute('DROP PROCEDURE IF EXISTS update_product_stock')

        connection.execute(<<~SQL)
          CREATE PROCEDURE update_product_stock(
            IN product_id_param INT,
            IN quantity_param INT
          )
          BEGIN
            UPDATE products
            SET stock_quantity = stock_quantity + quantity_param
            WHERE id = product_id_param;
          END
        SQL

        # Create triggers
        connection.execute('DROP TRIGGER IF EXISTS update_order_total_after_insert')
        connection.execute(<<~SQL)
          CREATE TRIGGER update_order_total_after_insert
          AFTER INSERT ON order_items
          FOR EACH ROW
          BEGIN
            UPDATE orders
            SET total = (
              SELECT COALESCE(SUM(price * quantity), 0)
              FROM order_items
              WHERE order_id = NEW.order_id
            )
            WHERE id = NEW.order_id;
          END
        SQL

        connection.execute('DROP TRIGGER IF EXISTS update_order_total_after_update')
        connection.execute(<<~SQL)
          CREATE TRIGGER update_order_total_after_update
          AFTER UPDATE ON order_items
          FOR EACH ROW
          BEGIN
            UPDATE orders
            SET total = (
              SELECT COALESCE(SUM(price * quantity), 0)
              FROM order_items
              WHERE order_id = NEW.order_id
            )
            WHERE id = NEW.order_id;
          END
        SQL

        connection.execute('DROP TRIGGER IF EXISTS update_order_total_after_delete')
        connection.execute(<<~SQL)
          CREATE TRIGGER update_order_total_after_delete
          AFTER DELETE ON order_items
          FOR EACH ROW
          BEGIN
            UPDATE orders
            SET total = (
              SELECT COALESCE(SUM(price * quantity), 0)
              FROM order_items
              WHERE order_id = OLD.order_id
            )
            WHERE id = OLD.order_id;
          END
        SQL
      end
    end
  end

  def down
    execute 'DROP TRIGGER IF EXISTS update_order_total_after_delete'
    execute 'DROP TRIGGER IF EXISTS update_order_total_after_update'
    execute 'DROP TRIGGER IF EXISTS update_order_total_after_insert'
    execute 'DROP PROCEDURE IF EXISTS update_product_stock'
  end
end
