CREATE TRIGGER `accounts_default_quantity` BEFORE INSERT ON `accounts` FOR EACH ROW BEGIN
  IF NEW.quantity = 0 THEN
    SET NEW.quantity = 1;
  END IF;
END;

CREATE TRIGGER `accounts_default_note` BEFORE INSERT ON `accounts` FOR EACH ROW SET NEW.note = coalesce(NEW.note, 'n');

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

CREATE TRIGGER `update_order_total_after_delete` AFTER DELETE ON `order_items` FOR EACH ROW BEGIN
  UPDATE orders
  SET total = (
    SELECT COALESCE(SUM(price * quantity), 0)
    FROM order_items
    WHERE order_id = OLD.order_id
  )
  WHERE id = OLD.order_id;
END;
