CREATE FUNCTION `add_one`(x INT) RETURNS int
    DETERMINISTIC
RETURN x + 1;

CREATE PROCEDURE `bump_quantity`(IN account INT)
BEGIN
  DECLARE done INT DEFAULT 0;
  BEGIN
    UPDATE accounts SET quantity = quantity + 1 WHERE id = account;
  END;
  IF done = 0 THEN
    SELECT 1;
  END IF;
END;

CREATE PROCEDURE `update_product_stock`(
  IN product_id_param INT,
  IN quantity_param INT
)
BEGIN
  UPDATE products
  SET stock_quantity = stock_quantity + quantity_param
  WHERE id = product_id_param;
END;
