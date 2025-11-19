# frozen_string_literal: true

class CreateFunctionsAndTriggers < ActiveRecord::Migration[8.1]
  def up
    # Function to update updated_at timestamp
    execute <<~SQL
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # Function to validate email format
    execute <<~SQL
      CREATE OR REPLACE FUNCTION validate_email(email_text text)
      RETURNS boolean AS $$
      BEGIN
        RETURN email_text ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$';
      END;
      $$ LANGUAGE plpgsql IMMUTABLE;
    SQL

    # Function to calculate discount price
    execute <<~SQL
      CREATE OR REPLACE FUNCTION calculate_discount_price(
        original_price numeric,
        discount_percent numeric
      )
      RETURNS numeric AS $$
      BEGIN
        IF discount_percent IS NULL OR discount_percent = 0 THEN
          RETURN original_price;
        END IF;
        RETURN ROUND(original_price * (1 - discount_percent / 100), 2);
      END;
      $$ LANGUAGE plpgsql IMMUTABLE;
    SQL

    # Function to audit product price changes
    execute <<~SQL
      CREATE OR REPLACE FUNCTION audit_product_price_change()
      RETURNS TRIGGER AS $$
      BEGIN
        IF OLD.price IS DISTINCT FROM NEW.price THEN
          INSERT INTO product_price_history (product_id, old_price, new_price, changed_at)
          VALUES (NEW.id, OLD.price, NEW.price, CURRENT_TIMESTAMP);
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # Create audit table for price changes
    create_table :product_price_history do |t|
      t.references :product, null: false, foreign_key: true
      t.decimal :old_price, precision: 10, scale: 2
      t.decimal :new_price, precision: 10, scale: 2, null: false
      t.timestamp :changed_at, null: false
    end

    add_index :product_price_history, [:product_id, :changed_at]

    # Create triggers
    execute <<~SQL
      CREATE TRIGGER trigger_update_products_updated_at
        BEFORE UPDATE ON products
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    SQL

    execute <<~SQL
      CREATE TRIGGER trigger_audit_product_price
        AFTER UPDATE ON products
        FOR EACH ROW
        EXECUTE FUNCTION audit_product_price_change();
    SQL

    execute <<~SQL
      CREATE TRIGGER trigger_update_categories_updated_at
        BEFORE UPDATE ON categories
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    SQL
  end

  def down
    execute 'DROP TRIGGER IF EXISTS trigger_update_categories_updated_at ON categories;'
    execute 'DROP TRIGGER IF EXISTS trigger_audit_product_price ON products;'
    execute 'DROP TRIGGER IF EXISTS trigger_update_products_updated_at ON products;'

    drop_table :product_price_history

    execute 'DROP FUNCTION IF EXISTS audit_product_price_change();'
    execute 'DROP FUNCTION IF EXISTS calculate_discount_price(numeric, numeric);'
    execute 'DROP FUNCTION IF EXISTS validate_email(text);'
    execute 'DROP FUNCTION IF EXISTS update_updated_at_column();'
  end
end
