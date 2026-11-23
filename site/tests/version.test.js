// @vitest-environment node
import { describe, it, expect } from 'vitest';
import { readGemVersion } from '../scripts/gemVersion';
import GEM_VERSION from '../src/version';

describe('gem version', () => {
  it('is read from the gem source', () => {
    expect(readGemVersion()).toMatch(/^\d+\.\d+\.\d+/);
    expect(GEM_VERSION).toBe(readGemVersion());
  });
});
