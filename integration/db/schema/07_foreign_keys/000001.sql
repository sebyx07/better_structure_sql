ALTER TABLE categories ADD CONSTRAINT fk_rails_82f48f7407 FOREIGN KEY (parent_id) REFERENCES categories (id) ON DELETE CASCADE;

ALTER TABLE events ADD CONSTRAINT fk_rails_0cb5590091 FOREIGN KEY (user_id) REFERENCES users (id);

ALTER TABLE large_table_000 ADD CONSTRAINT fk_rails_4a0fe673f1 FOREIGN KEY (related_id) REFERENCES large_table_001 (id);

ALTER TABLE large_table_002 ADD CONSTRAINT fk_rails_10d4c7857f FOREIGN KEY (related_id) REFERENCES large_table_003 (id);

ALTER TABLE large_table_004 ADD CONSTRAINT fk_rails_403f789646 FOREIGN KEY (related_id) REFERENCES large_table_005 (id);

ALTER TABLE large_table_006 ADD CONSTRAINT fk_rails_0a2a5c7700 FOREIGN KEY (related_id) REFERENCES large_table_007 (id);

ALTER TABLE large_table_008 ADD CONSTRAINT fk_rails_2fe8a3e5c2 FOREIGN KEY (related_id) REFERENCES large_table_009 (id);

ALTER TABLE large_table_010 ADD CONSTRAINT fk_rails_8baf10fabf FOREIGN KEY (related_id) REFERENCES large_table_011 (id);

ALTER TABLE large_table_012 ADD CONSTRAINT fk_rails_8ff9e73b1c FOREIGN KEY (related_id) REFERENCES large_table_013 (id);

ALTER TABLE large_table_014 ADD CONSTRAINT fk_rails_c23a51d6d3 FOREIGN KEY (related_id) REFERENCES large_table_015 (id);

ALTER TABLE large_table_016 ADD CONSTRAINT fk_rails_6ff3f374a2 FOREIGN KEY (related_id) REFERENCES large_table_017 (id);

ALTER TABLE large_table_018 ADD CONSTRAINT fk_rails_95217f3d00 FOREIGN KEY (related_id) REFERENCES large_table_019 (id);

ALTER TABLE large_table_020 ADD CONSTRAINT fk_rails_4059e67133 FOREIGN KEY (related_id) REFERENCES large_table_021 (id);

ALTER TABLE large_table_022 ADD CONSTRAINT fk_rails_1750dd1c8c FOREIGN KEY (related_id) REFERENCES large_table_023 (id);

ALTER TABLE large_table_024 ADD CONSTRAINT fk_rails_64b98564cb FOREIGN KEY (related_id) REFERENCES large_table_025 (id);

ALTER TABLE large_table_026 ADD CONSTRAINT fk_rails_a24e0ff80a FOREIGN KEY (related_id) REFERENCES large_table_027 (id);

ALTER TABLE large_table_028 ADD CONSTRAINT fk_rails_37310c7788 FOREIGN KEY (related_id) REFERENCES large_table_029 (id);

ALTER TABLE large_table_030 ADD CONSTRAINT fk_rails_aa888a6236 FOREIGN KEY (related_id) REFERENCES large_table_031 (id);

ALTER TABLE large_table_032 ADD CONSTRAINT fk_rails_3b295accd5 FOREIGN KEY (related_id) REFERENCES large_table_033 (id);

ALTER TABLE large_table_034 ADD CONSTRAINT fk_rails_2b45e03f7f FOREIGN KEY (related_id) REFERENCES large_table_035 (id);

ALTER TABLE large_table_036 ADD CONSTRAINT fk_rails_17434a2d19 FOREIGN KEY (related_id) REFERENCES large_table_037 (id);

ALTER TABLE large_table_038 ADD CONSTRAINT fk_rails_4ce638a77b FOREIGN KEY (related_id) REFERENCES large_table_039 (id);

ALTER TABLE large_table_040 ADD CONSTRAINT fk_rails_cd44c375bc FOREIGN KEY (related_id) REFERENCES large_table_041 (id);

ALTER TABLE large_table_042 ADD CONSTRAINT fk_rails_061295adfe FOREIGN KEY (related_id) REFERENCES large_table_043 (id);

ALTER TABLE large_table_044 ADD CONSTRAINT fk_rails_1adeeaa1a6 FOREIGN KEY (related_id) REFERENCES large_table_045 (id);

ALTER TABLE large_table_046 ADD CONSTRAINT fk_rails_e606c0a7e9 FOREIGN KEY (related_id) REFERENCES large_table_047 (id);

ALTER TABLE large_table_048 ADD CONSTRAINT fk_rails_4e9b16baa9 FOREIGN KEY (related_id) REFERENCES large_table_049 (id);

ALTER TABLE order_items ADD CONSTRAINT fk_rails_e3cb28f071 FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE;

ALTER TABLE order_items ADD CONSTRAINT fk_rails_f1a29ddd47 FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT;

ALTER TABLE orders ADD CONSTRAINT fk_rails_f868b47f6a FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT;

ALTER TABLE posts ADD CONSTRAINT fk_rails_5b5ddfd518 FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE;

ALTER TABLE product_price_history ADD CONSTRAINT fk_rails_b70a9e116e FOREIGN KEY (product_id) REFERENCES products (id);

ALTER TABLE products ADD CONSTRAINT fk_rails_fb915499a4 FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT;

ALTER TABLE sessions ADD CONSTRAINT fk_rails_758836b4f0 FOREIGN KEY (user_id) REFERENCES users (id);
