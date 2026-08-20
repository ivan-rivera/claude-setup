# Models Changelog

Managed by the `/model-scout` skill. Append a dated entry whenever model
assignments change. Never edit history.

## 2026-08-20

Initial lineup, ported from the OMP harness model roles (`omp-setup`):

- Main model (subscription): `claude-sonnet-5` — replaces OMP `default: z-ai/glm-5.3`
- Advisor model: `opus` — replaces OMP `advisor: z-ai/glm-5.3`
- Fallback chain: `claude-opus-5` → `claude-haiku-4-5` — replaces OMP chain sonnet-4 → gemini-2.5-pro → gemini-2.5-flash
- OpenRouter switch-in models (bill OpenRouter credits):
  - `z-ai/glm-5.3` via `claude-or` / `claude-glm`
  - `google/gemini-3.7-flash` via `claude-or google/gemini-3.7-flash` / `claude-gemini`
  - `deepseek/deepseek-v4-flash-0731` via `claude-or deepseek/deepseek-v4-flash-0731` / `claude-deepseek`
- Agent models (Claude aliases): architect/security/legal → `opus`; frontend/backend/qa/finance/researcher/content-writer → `sonnet`; data-generator → `haiku`
