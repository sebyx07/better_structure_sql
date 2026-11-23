CREATE OR REPLACE VIEW `active_accounts` AS
select `accounts`.`id` AS `id`,`accounts`.`code` AS `code`,'x;y' AS `label` from `accounts` where (`accounts`.`status` = 'active') WITH CASCADED CHECK OPTION;

CREATE OR REPLACE VIEW `a_active_account_codes` AS
select `active_accounts`.`code` AS `code` from `active_accounts`;

CREATE OR REPLACE VIEW `product_inventory` AS
select `products`.`id` AS `id`,`products`.`name` AS `name`,`products`.`price` AS `price`,`products`.`stock_quantity` AS `stock_quantity`,`categories`.`name` AS `category_name` from (`products` join `categories` on((`categories`.`id` = `products`.`category_id`))) where (`products`.`stock_quantity` > 0);

CREATE OR REPLACE VIEW `user_post_counts` AS
select `users`.`id` AS `user_id`,`users`.`email` AS `email`,count(`posts`.`id`) AS `post_count` from (`users` left join `posts` on((`posts`.`user_id` = `users`.`id`))) group by `users`.`id`,`users`.`email`;
