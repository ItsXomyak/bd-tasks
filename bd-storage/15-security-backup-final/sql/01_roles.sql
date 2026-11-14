DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_reader') THEN DROP OWNED BY app_reader; END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_writer') THEN DROP OWNED BY app_writer; END IF;
END $$;
DROP ROLE IF EXISTS app_reader;
DROP ROLE IF EXISTS app_writer;

CREATE ROLE app_reader LOGIN PASSWORD :'reader_pw';
CREATE ROLE app_writer LOGIN PASSWORD :'writer_pw';

GRANT CONNECT ON DATABASE seattle_library TO app_reader, app_writer;
GRANT USAGE ON SCHEMA public TO app_reader, app_writer;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

GRANT SELECT ON titles, checkout_facts, subjects, title_subjects TO app_reader;

GRANT SELECT ON titles, checkout_facts, subjects, title_subjects TO app_writer;
GRANT INSERT, UPDATE ON checkout_facts TO app_writer;
GRANT INSERT ON titles TO app_writer;
GRANT USAGE ON SEQUENCE checkout_facts_fact_id_seq, titles_title_id_seq TO app_writer;
