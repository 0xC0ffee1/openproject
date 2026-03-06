# App

## Directory Structure

- `app/components/` - ViewComponent-based UI components (Ruby + ERB)
- `app/contracts/` - Validation and authorization contracts
- `app/controllers/` - Rails controllers
- `app/models/` - ActiveRecord models
- `app/services/` - Service objects (business logic)
- `app/workers/` - Background job workers

## Code Style

### Ruby

- Follow [Ruby community style guide](https://github.com/bbatsov/ruby-style-guide)
- Use service objects for complex business logic (return `ServiceResult`)
- Use contracts for validation and authorization
- Keep controllers thin, models focused
- Document with [YARD](https://yardoc.org/)
- Write RSpec tests for all new features

### Templates

- Use ERB for server-rendered views
- Use ViewComponents for reusable UI (with Lookbook previews)
- Lint with erb_lint before committing

## Translations

- UI strings must use translation keys (never hard-coded)

## Linting

```bash
# Ruby
bundle exec rubocop                              # Check all files
bin/dirty-rubocop --uncommitted                  # Check only uncommitted changes

# ERB Templates
erb_lint {files}
```
