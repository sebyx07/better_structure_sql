import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';

const VERSION_FILE = fileURLToPath(
  new URL('../../lib/better_structure_sql/version.rb', import.meta.url)
);

// Reads the gem version from the gem source so the site never shows a stale one
export function readGemVersion() {
  const match = readFileSync(VERSION_FILE, 'utf8').match(/VERSION = '([^']+)'/);
  if (!match) {
    throw new Error(`Could not find VERSION in ${VERSION_FILE}`);
  }
  return match[1];
}
