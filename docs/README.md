# docs/

User-facing material for Batamiga, served by GitHub Pages from this
folder.

- `index.html` — the presentation site. Self-contained, no build step,
  targets WCAG 2.1 AAA (contrast, keyboard navigation, semantics,
  `prefers-reduced-motion`, alt text). GitHub Pages serves it directly.
- `.nojekyll` — tells GitHub Pages to skip the Jekyll build and serve
  files as-is.
- `screenshot.png` — **to be added**: a real capture of EmulationStation
  running on the current image (A500 game list, and ideally a game
  running). Referenced by `index.html` and the README.

## Enabling GitHub Pages

Repository → Settings → Pages → Source: "Deploy from a branch",
branch `main`, folder `/docs`. The site then publishes at
`https://patrickjaillet.github.io/batamiga`.
