# frozen_string_literal: true

# MySQL adaptation: Stored procedures and triggers using MySQL syntax
class CreateStoredProceduresAndTriggers < ActiveRecord::Migration[8.1]
  def up
    # Create a stored procedure to update product stock
    execute <<~SQL
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

    # Create trigger to update order total when order items change
    execute <<~SQL
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

    execute <<~SQL
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

    execute <<~SQL
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

  def down
    execute 'DROP TRIGGER IF EXISTS update_order_total_after_delete;'
    execute 'DROP TRIGGER IF EXISTS update_order_total_after_update;'
    execute 'DROP TRIGGER IF EXISTS update_order_total_after_insert;'
    execute 'DROP PROCEDURE IF EXISTS update_product_stock;'
  end
end
