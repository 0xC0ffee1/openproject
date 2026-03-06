# Frontend

## Directory Structure

- `frontend/src/` - Frontend code
  - `frontend/src/app/` - Legacy Angular modules/components
  - `frontend/src/stimulus/` - Stimulus controllers
  - `frontend/src/turbo/` - Turbo integration

## Configuration Files

- `frontend/eslint.config.mjs` - JavaScript/TypeScript linting
- `package.json` / `frontend/package.json` - Node.js dependencies

## Version Requirements

- Node: `^22.21.0` (see `package.json` engines)

## Setup

```bash
cd frontend && npm ci && cd ..   # Install Node packages
```

## Code Style

### JavaScript/TypeScript

- **New development**: Use Hotwire (Turbo + Stimulus) with server-rendered HTML
- **Legacy code**: Follow ESLint rules
- Prefer TypeScript over JavaScript
- Use [Primer Design System](https://primer.style/product/) via ViewComponent

## Linting

```bash
# JavaScript/TypeScript
cd frontend && npx eslint src/ && cd ..
```

## Testing

```bash
# Frontend (Jasmine/Karma)
cd frontend && npm test && cd ..
```
