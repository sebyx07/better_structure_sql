ALTER TABLE order_items ADD CONSTRAINT fk_rails_e3cb28f071 FOREIGN KEY (order_id) REFERENCES orders (id);

ALTER TABLE order_items ADD CONSTRAINT fk_rails_f1a29ddd47 FOREIGN KEY (product_id) REFERENCES products (id);

ALTER TABLE orders ADD CONSTRAINT fk_rails_f868b47f6a FOREIGN KEY (user_id) REFERENCES users (id);

ALTER TABLE posts ADD CONSTRAINT fk_rails_5b5ddfd518 FOREIGN KEY (user_id) REFERENCES users (id);

ALTER TABLE products ADD CONSTRAINT fk_rails_fb915499a4 FOREIGN KEY (category_id) REFERENCES categories (id);
