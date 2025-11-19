CREATE PROCEDURE `update_product_stock`(
  IN product_id_param INT,
  IN quantity_param INT
)
BEGIN
  UPDATE products
  SET stock_quantity = stock_quantity + quantity_param
  WHERE id = product_id_param;
END;
