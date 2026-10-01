---
id: elm
name: "Elm (elm/html, Browser.element)"
aliases: [elm, elm-lang, elm-html, elm-ui, elm-architecture, tea]
detect:
  files: ["elm.json"]
  globs: ["src/**/*.elm"]
route: web-build
kind: web
where: local
toolchain: "elm 0.19.1 (official linux binary in ~/.cache/mockup-toolchains/elm/bin), ELM_HOME in the same folder, python3 to inline"
versions: "elm 0.19.1, elm/core 1.0.5, elm/html 1.0.0, elm/browser 1.0.2"
renderedBy: ["~/.cache/mockup-toolchains/elm/bin/elm", "<scratchpad>/elm"]
verified: 2026-10-01
verifiedBy: "verified by prifly sessions on 2026-10-01"
fixture: fixtures/elm
---

## Steps
1. Compiler, once, no sudo: `mkdir -p ~/.cache/mockup-toolchains/elm/bin && curl -sL https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz | gunzip > ~/.cache/mockup-toolchains/elm/bin/elm && chmod +x ~/.cache/mockup-toolchains/elm/bin/elm`. (macOS: `binary-for-mac-64-bit.gz`; the npm `elm` package also works.) Then `export PATH=~/.cache/mockup-toolchains/elm/bin:$PATH ELM_HOME=~/.cache/mockup-toolchains/elm/home`.
2. The project's own app: if it has an `elm.json`, compile the real sources from a scratch copy or in place with `--output` outside the repo, so nothing lands in it: `elm make src/Main.elm --optimize --output=<scratchpad>/elm.js` (add `elm-stuff/` cleanup only if it was not there before). Packages download from package.elm-lang.org on the first build (a few MB) and are cached in `ELM_HOME`.
3. An Elm app is a program, not a component: it needs a host page. Write `index.html` with `<div id="app">`, a `<style>`, the compiled JS in a `<script>` and `Elm.Main.init({ node: document.getElementById("app"), flags: ... })` in a second `<script>`. Inline with a script that replaces `</script` by `<\/script` inside the JS (the fixture's `build.sh` does it with python3, using a function-form replace so `$` in the JS survives).
4. Fixed invented data: put the model's seed in `init` (or pass it as flags); no `Time`, no `Random`, no `Http`.
5. `mockup-kit check page.html`, then `mcp__prifly__mockup` with `file`, `renderedBy: ["~/.cache/mockup-toolchains/elm/bin/elm", "<project folder>"]` (absolute paths), `check: true` first and the post without it. The fixture page is about 130 kB.

## Gotchas
- `Browser.application` and `Browser.document` need a real URL and history; in a file page, `Browser.element` is the right entry. Read the state from flags, not from `Url`.
- Compile with `--optimize` (smaller, about 130 kB for a board app) unless the project uses `Debug.log`/`Debug.toString`, which `--optimize` refuses: then use plain `elm make` and say so.
- A `port module` only needs `ports` if you want a JS control; Elm 0.19 forbids ports in packages and in `Browser.sandbox` programs, so use `Browser.element`.
- `elm make` writes `elm-stuff/` next to `elm.json`; a mockup must leave no file in the reader's checkout: copy the project to the scratchpad first, or pass `--output` and delete a `elm-stuff/` you created.
- No `elm-live`, no `elm reactor`, no network at run time: reactor serves a page from localhost, which a mockup cannot be.
- elm-ui (`mdgriffith/elm-ui`) injects its stylesheet at run time through the virtual DOM, so it is inlined by the compiled JS and needs nothing extra; web fonts it names are not fetched, so pick a system font stack or embed a font as a data URI.
- The picture waits for `window.__mockupReady`; set it false first and true in `requestAnimationFrame` after `Elm.Main.init` returns (Elm renders synchronously inside `init`).

## States
Port `hashChanged : (String -> msg) -> Sub msg` plus `flags: location.hash` for the first state, and `window.addEventListener("hashchange", ...)` calling `app.ports.hashChanged.send(location.hash)`. The model maps the hash (`#empty`, `#error`, anything else the populated board) in one `fromHash` function. A small bar above the app frame, labelled "Mockup control", holds the links; it is plain HTML outside Elm's node. `check: true` takes a path without a `#hash`, so check the other states on a copy whose `flags: location.hash` was replaced by `flags: "#empty"` and `"#error"` (sed).
