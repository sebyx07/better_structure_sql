CREATE OR REPLACE FUNCTION public.audit_product_price_change()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF OLD.price IS DISTINCT FROM NEW.price THEN
    INSERT INTO product_price_history (product_id, old_price, new_price, changed_at)
    VALUES (NEW.id, OLD.price, NEW.price, CURRENT_TIMESTAMP);
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_discount_price(original_price numeric, discount_percent numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  IF discount_percent IS NULL OR discount_percent = 0 THEN
    RETURN original_price;
  END IF;
  RETURN ROUND(original_price * (1 - discount_percent / 100), 2);
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_0(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.0 + 0;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_1(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.1 + 10;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_2(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.2 + 20;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_3(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.3 + 30;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_4(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.4 + 40;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_5(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.5 + 50;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_6(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.6 + 60;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_7(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.7 + 70;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_8(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.8 + 80;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_total_9(base_amount numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  -- Complex calculation to make function multi-line
  RETURN base_amount * 1.9 + 90;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_0()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_1()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_10()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_11()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_12()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_13()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_14()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_2()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_3()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_4()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_5()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_6()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_7()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_8()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp_9()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.uuid_generate_v8()
 RETURNS uuid
 LANGUAGE plpgsql
AS $function$
DECLARE
  timestamp timestamptz;
  microseconds int;
BEGIN
  timestamp := clock_timestamp();
  microseconds := (cast(extract(microseconds from timestamp)::int -
    (floor(extract(milliseconds from timestamp))::int * 1000) as double precision) * 4.096)::int;

  RETURN encode(
    set_byte(
      set_byte(
        overlay(uuid_send(gen_random_uuid())
          placing substring(int8send(floor(extract(epoch from timestamp) * 1000)::bigint) from 3)
          from 1 for 6
        ),
        6, (b'1000' || (microseconds >> 8)::bit(4))::bit(8)::int
      ),
      7, microseconds::bit(8)::int
    ),
    'hex')::uuid;
END
$function$;

CREATE OR REPLACE FUNCTION public.validate_email(email_text text)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  RETURN email_text ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.[A-Z|a-z]{2,}$';
END;
$function$;
