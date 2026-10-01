# Contributing

Improvements to the Elm recipe are welcome: a fix for a gotcha, a newer Elm or package version, an elm-ui or
`elm-pages` note, a better fixture.

- A recipe describes what **actually worked** in a mockup that was built and posted. Name only versions you ran, and
  update `verified` and `verifiedBy` when you re-verify.
- Keep it short: numbered steps a session can follow, then gotchas, then states.
- Invented data only. No private paths (use `~` or `<scratchpad>`), machine names, addresses or company names.
- The fixture is sources only (no `elm-stuff/`, no `dist/`) and builds in under two minutes.
- Run `bun scripts/check.ts` before opening a pull request; CI runs the same.

The recipe format is documented in prifly's `apps/desktop-host/mockup-stacks/recipes/README.md`.
