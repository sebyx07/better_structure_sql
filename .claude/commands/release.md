---
description: Bump version, update changelog, build and publish gem, commit and push
argument-hint: [major|minor|patch|auto]
---

Analyze recent commits since last release to determine version bump (major/minor/patch), or use explicit argument. Update version.rb, move Unreleased to new version in CHANGELOG.md with timestamp, build gem, publish to RubyGems, create git tag, commit and push.

## Version Bump Rules (when auto)

**Major (x.0.0)**: Breaking changes, API removals, incompatible changes
- Keywords: BREAKING, remove, deprecate, incompatible, major refactor
- 10+ significant commits

**Minor (0.x.0)**: New features, enhancements, significant additions
- Keywords: add, feature, implement, new, support
- 3-9 commits or new feature additions

**Patch (0.0.x)**: Bug fixes, minor improvements, documentation
- Keywords: fix, update, improve, refactor, docs
- 1-2 commits or only fixes/docs

## Process

1. Analyze commits: `git log v{current}..HEAD --oneline`
2. Determine bump type from commit messages (or use argument)
3. Update `lib/better_structure_sql/version.rb`
4. Update CHANGELOG.md: Move Unreleased → new version with date, create new Unreleased section
5. Update version references:
   - `site/src/pages/GettingStarted/Installation.jsx` - Gemfile examples
   - `site/src/pages/GettingStarted/Configuration.jsx` - Code examples
   - `README.md` - Beta version notice, badges
   - `lib/generators/better_structure_sql/templates/better_structure_sql.rb` - Initializer template
6. Build: `gem build better_structure_sql.gemspec`
7. Publish: `gem push better_structure_sql-{version}.gem`
8. Commit: `git add -A && git commit -m "Release v{version}"`
9. Tag: `git tag -a v{version} -m "Release v{version}"`
10. Push: `git push && git push --tags`

## Arguments

- `auto` (default): Analyze commits and decide
- `major`: Force major version bump
- `minor`: Force minor version bump
- `patch`: Force patch version bump
