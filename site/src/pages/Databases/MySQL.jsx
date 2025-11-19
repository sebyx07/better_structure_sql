import { Link } from 'react-router-dom';
import CodeBlock from '../../components/CodeBlock/CodeBlock';

function MySQL() {
  return (
    <div className="container my-4">
      <div className="row">
        <div className="col-lg-10 offset-lg-1">
          <div className="mysql-guide">
            <h1 className="mb-4">
              <i className="bi bi-database text-warning me-3" />
              MySQL Guide
            </h1>

            <div className="alert alert-info">
              <i className="bi bi-info-circle me-2" />
              MySQL 8.0+ support includes stored procedures, triggers, views, indexes, and CHECK constraints.
              BetterStructureSql cleanly dumps all these features!
            </div>

            <div className="alert alert-warning">
              <i className="bi bi-download me-2" />
              <strong>Getting Started:</strong>{' '}
              <Link to="/install" className="alert-link">Install Guide</Link>
              {' '}•{' '}
              <a href="https://rubygems.org/gems/better_structure_sql" className="alert-link" target="_blank" rel="noopener noreferrer">
                RubyGems
              </a>
              {' '}•{' '}
              <a href="https://dev.mysql.com/downloads/mysql/" className="alert-link" target="_blank" rel="noopener noreferrer">
                Install MySQL 8.0+
              </a>
            </div>

            <section className="mb-5">
              <h2 className="border-bottom pb-2 mb-3">MySQL Features</h2>
              <div className="row">
                <div className="col-md-6">
                  <h4>✅ Supported</h4>
                  <ul>
                    <li>Stored Procedures</li>
                    <li>Triggers (BEFORE/AFTER)</li>
                    <li>Views</li>
                    <li>Indexes (btree, hash, fulltext)</li>
                    <li>Foreign Keys</li>
                    <li>ENUM and SET types</li>
                    <li>CHECK Constraints (8.0.16+)</li>
                  </ul>
                </div>
                <div className="col-md-6">
                  <h4>❌ Not Supported</h4>
                  <ul>
                    <li>Extensions (MySQL doesn&apos;t have these)</li>
                    <li>Materialized Views</li>
                    <li>Custom Types (uses inline ENUM/SET)</li>
                    <li>Sequences (uses AUTO_INCREMENT)</li>
                  </ul>
                </div>
              </div>
            </section>

            {/* Stored Procedures */}
            <section className="mb-5">
              <h2 className="border-bottom pb-2 mb-3">
                <i className="bi bi-file-code me-2" />
                Stored Procedures for Business Logic
              </h2>
              <p className="lead">
                Move complex business logic into the database for consistency and performance.
              </p>

              <h4 className="mt-4">Example: Order Processing Procedure</h4>
              <CodeBlock language="ruby" filename="db/migrate/20240101000001_create_process_order_procedure.rb">
                {`class CreateProcessOrderProcedure < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE PROCEDURE process_order(
        IN p_order_id BIGINT,
        OUT p_success BOOLEAN,
        OUT p_message VARCHAR(255)
      )
      BEGIN
        DECLARE v_total DECIMAL(10,2);
        DECLARE v_user_balance DECIMAL(10,2);

        -- Start transaction
        START TRANSACTION;

        -- Calculate order total
        SELECT SUM(price * quantity) INTO v_total
        FROM order_items
        WHERE order_id = p_order_id;

        -- Get user balance
        SELECT balance INTO v_user_balance
        FROM users
        WHERE id = (SELECT user_id FROM orders WHERE id = p_order_id);

        -- Check if user has enough balance
        IF v_user_balance >= v_total THEN
          -- Deduct from balance
          UPDATE users
          SET balance = balance - v_total
          WHERE id = (SELECT user_id FROM orders WHERE id = p_order_id);

          -- Update order status
          UPDATE orders
          SET status = 'paid', total = v_total
          WHERE id = p_order_id;

          -- Log transaction
          INSERT INTO transactions (order_id, amount, created_at)
          VALUES (p_order_id, v_total, NOW());

          SET p_success = TRUE;
          SET p_message = 'Order processed successfully';
          COMMIT;
        ELSE
          SET p_success = FALSE;
          SET p_message = 'Insufficient balance';
          ROLLBACK;
        END IF;
      END
    SQL
  end

  def down
    execute 'DROP PROCEDURE IF EXISTS process_order'
  end
end`}
              </CodeBlock>

              <h5 className="mt-4">Call from Rails</h5>
              <CodeBlock language="ruby">
                {`# Call the stored procedure
result = ActiveRecord::Base.connection.execute(
  "CALL process_order(#{order.id}, @success, @message)"
)

# Get output parameters
output = ActiveRecord::Base.connection.execute(
  "SELECT @success AS success, @message AS message"
).first

if output['success']
  flash[:notice] = output['message']
else
  flash[:error] = output['message']
end`}
              </CodeBlock>

              <div className="alert alert-success mt-3">
                <strong>Benefits:</strong>
                <ul className="mb-0">
                  <li>💰 Complex calculations in one database call</li>
                  <li>🔒 Transactional integrity guaranteed</li>
                  <li>🚀 Better performance (no network roundtrips)</li>
                  <li>📋 Reusable across different applications</li>
                </ul>
              </div>
            </section>

            {/* Triggers */}
            <section className="mb-5">
              <h2 className="border-bottom pb-2 mb-3">
                <i className="bi bi-lightning me-2" />
                Triggers for Automatic Updates
              </h2>
              <p className="lead">
                Automatically maintain data integrity and update related records.
              </p>

              <h4 className="mt-4">Example: Auto-Calculate Order Totals</h4>
              <CodeBlock language="ruby" filename="db/migrate/20240101000002_create_order_total_trigger.rb">
                {`class CreateOrderTotalTrigger < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE TRIGGER calculate_order_total
      BEFORE UPDATE ON orders
      FOR EACH ROW
      BEGIN
        DECLARE item_total DECIMAL(10,2);

        -- Calculate total from order items
        SELECT COALESCE(SUM(price * quantity), 0) INTO item_total
        FROM order_items
        WHERE order_id = NEW.id;

        -- Apply discount if any
        IF NEW.discount_percent > 0 THEN
          SET NEW.total = item_total * (1 - NEW.discount_percent / 100);
        ELSE
          SET NEW.total = item_total;
        END IF;

        -- Update timestamp
        SET NEW.updated_at = NOW();
      END
    SQL
  end

  def down
    execute 'DROP TRIGGER IF EXISTS calculate_order_total'
  end
end`}
              </CodeBlock>

              <h4 className="mt-4">Example: Inventory Management</h4>
              <CodeBlock language="ruby" filename="db/migrate/20240101000003_create_inventory_trigger.rb">
                {`class CreateInventoryTrigger < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE TRIGGER update_inventory
      AFTER INSERT ON order_items
      FOR EACH ROW
      BEGIN
        -- Decrease stock quantity
        UPDATE products
        SET stock_quantity = stock_quantity - NEW.quantity,
            updated_at = NOW()
        WHERE id = NEW.product_id;

        -- Log inventory change
        INSERT INTO inventory_logs (
          product_id, change_amount, reason, created_at
        ) VALUES (
          NEW.product_id, -NEW.quantity, 'order', NOW()
        );

        -- Alert if stock is low
        IF (SELECT stock_quantity FROM products WHERE id = NEW.product_id) < 10 THEN
          INSERT INTO alerts (message, created_at)
          VALUES (
            CONCAT('Low stock for product ID ', NEW.product_id),
            NOW()
          );
        END IF;
      END
    SQL
  end

  def down
    execute 'DROP TRIGGER IF EXISTS update_inventory'
  end
end`}
              </CodeBlock>

              <div className="alert alert-success mt-3">
                <strong>Benefits:</strong>
                <ul className="mb-0">
                  <li>✅ Data consistency enforced at database level</li>
                  <li>🔄 Automatic updates - no application code needed</li>
                  <li>📊 Real-time inventory tracking</li>
                  <li>⚡ Fast - executes immediately on insert/update</li>
                </ul>
              </div>
            </section>

            {/* Full-Text Search */}
            <section className="mb-5">
              <h2 className="border-bottom pb-2 mb-3">
                <i className="bi bi-search me-2" />
                Full-Text Search
              </h2>
              <p className="lead">
                Fast text searching across large datasets using MySQL&apos;s FULLTEXT indexes.
              </p>

              <CodeBlock language="ruby" filename="db/migrate/20240101000004_add_fulltext_search.rb">
                {`class AddFulltextSearch < ActiveRecord::Migration[7.0]
  def up
    # Add FULLTEXT index
    execute <<-SQL
      CREATE FULLTEXT INDEX idx_products_fulltext
      ON products(name, description, tags)
    SQL
  end

  def down
    execute 'DROP INDEX idx_products_fulltext ON products'
  end
end`}
              </CodeBlock>

              <h5 className="mt-4">Use in Rails Models</h5>
              <CodeBlock language="ruby" filename="app/models/product.rb">
                {`class Product < ApplicationRecord
  # Natural language search
  scope :fulltext_search, ->(query) {
    where(
      "MATCH(name, description, tags) AGAINST(? IN NATURAL LANGUAGE MODE)",
      query
    ).order(
      Arel.sql("MATCH(name, description, tags) AGAINST('#{connection.quote(query)}' IN NATURAL LANGUAGE MODE) DESC")
    )
  }

  # Boolean search (with +required -excluded)
  scope :boolean_search, ->(query) {
    where(
      "MATCH(name, description, tags) AGAINST(? IN BOOLEAN MODE)",
      query
    )
  }
end

# Usage:
Product.fulltext_search('wireless charging')
Product.boolean_search('+wireless +fast -slow')  # Must have wireless and fast, exclude slow`}
              </CodeBlock>

              <div className="alert alert-success mt-3">
                <strong>Benefits:</strong>
                <ul className="mb-0">
                  <li>🚀 Much faster than LIKE queries on large tables</li>
                  <li>📊 Relevance ranking built-in</li>
                  <li>🔍 Boolean search operators (+required -excluded)</li>
                  <li>💪 Scales to millions of records</li>
                </ul>
              </div>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
}

export default MySQL;
