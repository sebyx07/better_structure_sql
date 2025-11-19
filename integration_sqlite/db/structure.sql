SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

SET search_path TO "$user", public;

-- Tables

-- Views

CREATE VIEW main. AS
;

-- Schema Migrations
INSERT INTO "schema_migrations" (version) VALUES
('20250101000001'),
('20250101000002'),
('20250101000003'),
('20250101000004'),
('20250101000005'),
('20250101000006')
ON CONFLICT DO NOTHING;