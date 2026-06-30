# Environment Format

## Rules

- Use `version` for deployed service references.
- Reference Git tags, not branches.
- Keep service mappings explicit per environment file.

## Example

```yaml
environment: preprod
services:
  api-back:
    version: v1.4.2
```
