CREATE TRIGGER trigger_update_categories_updated_at BEFORE UPDATE ON public.categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_large_table_000_update_timestamp BEFORE UPDATE ON public.large_table_000 FOR EACH ROW EXECUTE FUNCTION update_timestamp_0();

CREATE TRIGGER trg_large_table_001_update_timestamp BEFORE UPDATE ON public.large_table_001 FOR EACH ROW EXECUTE FUNCTION update_timestamp_1();

CREATE TRIGGER trg_large_table_002_update_timestamp BEFORE UPDATE ON public.large_table_002 FOR EACH ROW EXECUTE FUNCTION update_timestamp_2();

CREATE TRIGGER trg_large_table_003_update_timestamp BEFORE UPDATE ON public.large_table_003 FOR EACH ROW EXECUTE FUNCTION update_timestamp_3();

CREATE TRIGGER trg_large_table_004_update_timestamp BEFORE UPDATE ON public.large_table_004 FOR EACH ROW EXECUTE FUNCTION update_timestamp_4();

CREATE TRIGGER trg_large_table_005_update_timestamp BEFORE UPDATE ON public.large_table_005 FOR EACH ROW EXECUTE FUNCTION update_timestamp_5();

CREATE TRIGGER trg_large_table_006_update_timestamp BEFORE UPDATE ON public.large_table_006 FOR EACH ROW EXECUTE FUNCTION update_timestamp_6();

CREATE TRIGGER trg_large_table_007_update_timestamp BEFORE UPDATE ON public.large_table_007 FOR EACH ROW EXECUTE FUNCTION update_timestamp_7();

CREATE TRIGGER trg_large_table_008_update_timestamp BEFORE UPDATE ON public.large_table_008 FOR EACH ROW EXECUTE FUNCTION update_timestamp_8();

CREATE TRIGGER trg_large_table_009_update_timestamp BEFORE UPDATE ON public.large_table_009 FOR EACH ROW EXECUTE FUNCTION update_timestamp_9();

CREATE TRIGGER trg_large_table_010_update_timestamp BEFORE UPDATE ON public.large_table_010 FOR EACH ROW EXECUTE FUNCTION update_timestamp_10();

CREATE TRIGGER trg_large_table_011_update_timestamp BEFORE UPDATE ON public.large_table_011 FOR EACH ROW EXECUTE FUNCTION update_timestamp_11();

CREATE TRIGGER trg_large_table_012_update_timestamp BEFORE UPDATE ON public.large_table_012 FOR EACH ROW EXECUTE FUNCTION update_timestamp_12();

CREATE TRIGGER trg_large_table_013_update_timestamp BEFORE UPDATE ON public.large_table_013 FOR EACH ROW EXECUTE FUNCTION update_timestamp_13();

CREATE TRIGGER trg_large_table_014_update_timestamp BEFORE UPDATE ON public.large_table_014 FOR EACH ROW EXECUTE FUNCTION update_timestamp_14();

CREATE TRIGGER trigger_audit_product_price AFTER UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION audit_product_price_change();

CREATE TRIGGER trigger_update_products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
