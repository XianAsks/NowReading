# A Reader's Companion to *1929*

A spoiler-free character/institution guide and chapter reference for
listeners of Andrew Ross Sorkin's *1929: Inside the Greatest Crash in Wall
Street History — and How It Shattered a Nation* (Viking, 2025). Built as a
single LaTeX document, published as both PDF and EPUB.

This is a fan-made study aid, not authorized, reviewed, or endorsed by the
author or publisher. See the document's own "Notes on This Document" section
(the last section before the References) for the full editorial policy —
what's spoiler-free and why, and exactly which claims come from the book
itself versus from secondary sources. This README covers the mechanics of
building it; that section covers the mechanics of what's *in* it.

## Contents

| File | Purpose |
|---|---|
| `sorkin-1929-reader-companion.tex` | The document source. |
| `references.bib` | BibTeX bibliography, cited inline via numbered `\autocite`s. |
| `build.sh` | Builds both the PDF and EPUB editions (see below). |
| `sorkin-1929-reader-companion.pdf` | Built PDF, tracked in git. |
| `sorkin-1929-reader-companion.epub` | Built EPUB, tracked in git. |

The PDF and EPUB are committed alongside the source so they're available
without a LaTeX toolchain on hand. If you edit the `.tex` or `.bib`, rebuild
and commit the regenerated PDF/EPUB in the same change — nothing regenerates
them automatically.

## Building

```sh
./build.sh
```

Requires, at minimum:

- A TeX Live install with `pdflatex`, `biber`, and the packages the document
  uses (`biblatex`, `titlesec`, `enumitem`, `hyperref`, `textcomp`, etc.) —
  on Debian/Ubuntu: `texlive-latex-base texlive-latex-recommended
  texlive-latex-extra texlive-fonts-recommended texlive-bibtex-extra biber`.
- `htlatex` (part of `tex4ht`; on Debian/Ubuntu it ships inside
  `texlive-plain-generic`) for the EPUB fallback path.
- `pandoc` for the EPUB fallback path's final HTML → EPUB3 conversion.
- `perl`, `zip`, and `unzip` for the EPUB build's post-processing steps.

Optional but recommended for verifying a build:

- `poppler-utils` (`pdftoppm`) to render PDF pages as images for a visual check.
- `epubcheck` (a Java tool; needs a JRE) to validate the EPUB against the
  spec: `java -jar /path/to/epubcheck.jar sorkin-1929-reader-companion.epub`.
  The committed EPUB validates with 0 errors/warnings under EPUBCheck 4.2.6.

`build.sh` prefers `tex4ebook` for the EPUB (a CTAN package that wraps
`htlatex`/`make4ht` and packages a spec-compliant EPUB directly) and uses it
automatically if it's on `PATH`. It isn't installable in every environment —
CTAN, where it ships from, is blocked by some network egress policies, and
it isn't packaged for Debian/Ubuntu's apt repositories — so when it's
missing, the script falls back to driving the same underlying tools by hand:
`htlatex → biber → htlatex → pandoc`, plus two post-processing passes
documented inline in `build.sh` that work around real bugs hit getting there
(a hyperref/tex4ht anchor-collision issue, and a pandoc nav-generation
quirk). If you're building somewhere with CTAN access, installing
`tex4ebook` via `tlmgr` will produce a nicer-packaged EPUB (custom cover
support, etc.) with no changes to this script needed.

Everything the build touches beyond the tracked files above (`.aux`, `.log`,
`.bbl`, `.toc`, the intermediate `.html`/`.css` from the `htlatex` path,
etc.) is deleted at the end of `build.sh` and listed in `.gitignore` as a
backstop.

## EPUB pagination

EPUB has no fixed pages — a reading app computes them from your font size
and screen, and most apps (Apple Books, Google Play Books, etc.) can toggle
between paginated and continuous-scroll display of the same file. The
per-section split you'll see if you unzip the EPUB (`ch001.xhtml`,
`ch002.xhtml`, …) exists so the table of contents can jump to a specific
section; it doesn't force pagination, and scroll mode flows across those
files with no visible seam.

## Sourcing methodology

Summarized here for anyone browsing the repo without opening the PDF; the
document's own "Notes on This Document" section is the canonical version and
should be kept in sync with this summary if either changes.

The document draws on two distinct tiers of source material, kept separate
rather than blended:

1. **Secondary sources** (publisher copy, reviews, press interviews,
   reader/study-guide summaries) — behind the "About," "Cast of Characters,"
   "Cast of Institutions," and "Chapter-by-Chapter Narrative Outline"
   sections, drafted before the book's own text or full table of contents
   was available to this project.
2. **The book's own front matter** (a publisher preview PDF covering the
   front matter through the Prologue, and a VitalSource table-of-contents
   export) — behind "The Cast of Characters and the Companies They Kept"
   (a direct reproduction of the book's own cast list) and "Chapter Titles"
   (the real chapter titles, each paired with independently researched
   historical context for that date rather than a summary of the chapter's
   actual contents, which weren't available beyond the Prologue).

Every specific claim is cited inline to the relevant tier; `references.bib`
notes, per entry, which sources were fetched directly versus consulted only
via search-index excerpts (some source pages are blocked by this project's
authoring environment's network policy, e.g. ursummary.com and
vitalsource.com's own site — see the `note` field on those `.bib` entries).
