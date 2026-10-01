# prifly-mockup-elm

A mockup recipe for **Elm** web apps, for prifly sessions. When a session is asked
to mock up a screen of an Elm project, the recipe tells it how to compile the real app with the real `elm make`, pack
it into one self-contained HTML page and post it with `mcp__prifly__mockup`.

## Use it in prifly

This repo is a prifly extension. In prifly, open **Extensions**, install from the git URL
`https://github.com/jimmy927/prifly-mockup-elm.git`, then enable it. Sessions then get the recipe from
`mcp__prifly__mockup_recipe` (layer order: project `.prifly/mockup-stacks/` > user folder > enabled extensions >
built-in). A project can also copy `mockup-stacks/elm.md` into its own `.prifly/mockup-stacks/`.

## The recipe

`mockup-stacks/elm.md` says: install the official Elm 0.19.1 binary into `~/.cache/mockup-toolchains/elm` (no sudo),
compile the project with `elm make --optimize` to a JS file outside the checkout, inline it with the CSS into a host
page that calls `Elm.Main.init` (`Browser.element`; flags and a port carry the state from `location.hash`), set
`window.__mockupReady`, and post the one file (about 130 kB for the proof app). It lists what cost time (no
`Browser.application` in a file page, `--optimize` versus `Debug`, leaving no `elm-stuff/` behind) and how empty and
error states sit behind a mockup control outside the app frame. `mockup-stacks/fixtures/elm/` is the small proof
project, a task board; its `build.sh` rebuilds the page.

## Check

```
bun scripts/check.ts
```

validates every recipe's frontmatter against the schema prifly's loader uses. Inside a prifly checkout,
`bun run mockup-stacks:check --dir <path-to-this-repo>/mockup-stacks` runs the full checker on this folder and also builds the fixture (needs `elm` on the PATH).

## Screenshots

![The recipe card in prifly](docs/prifly-card.png)

![The mockup opened in prifly](docs/prifly-open.png)

## License

MIT, see [LICENSE](LICENSE).
