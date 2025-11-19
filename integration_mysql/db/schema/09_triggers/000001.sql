CREATE TRIGGER `update_order_total_after_delete` AFTER DELETE ON `order_items` FOR EACH ROW BEGIN
  UPDATE orders
  SET total = (
    SELECT COALESCE(SUM(price * quantity), 0)
    FROM order_items
    WHERE order_id = OLD.order_id
  )
  WHERE id = OLD.order_id;
END;

CREATE TRIGGER `update_order_total_after_insert` AFTER INSERT ON `order_items` FOR EACH ROW BEGIN
  UPDATE orders
  SET total = (
    SELECT COALESCE(SUM(price * quantity), 0)
    FROM order_items
    WHERE order_id = NEW.order_id
  )
  WHERE id = NEW.order_id;
END;

CREATE TRIGGER `update_order_total_after_update` AFTER UPDATE ON `order_items` FOR EACH ROW BEGIN
  UPDATE orders
  SET total = (
    SELECT COALESCE(SUM(price * quantity), 0)
    FROM order_items
    WHERE order_id = NEW.order_id
  )
  WHERE id = NEW.order_id;
END;
