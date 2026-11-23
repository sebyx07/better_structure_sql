import { useEffect } from 'react';
import PropTypes from 'prop-types';

const SITE_NAME = 'BetterStructureSql';
const DEFAULT_TITLE = `${SITE_NAME} - Use SQL Databases to the Fullest`;
const DEFAULT_DESCRIPTION =
  'Clean, deterministic database schema dumps for Rails without pg_dump. Supports PostgreSQL, MySQL and SQLite with triggers, views, functions, schema versioning and multi-file output.';

// Keeps the document title and meta description in sync with the current page.
function Seo({ title = null, description = DEFAULT_DESCRIPTION }) {
  useEffect(() => {
    document.title = title ? `${title} - ${SITE_NAME}` : DEFAULT_TITLE;
    document.querySelector('meta[name="description"]')?.setAttribute('content', description);
  }, [title, description]);

  return null;
}

Seo.propTypes = {
  title: PropTypes.string,
  description: PropTypes.string,
};

export default Seo;
