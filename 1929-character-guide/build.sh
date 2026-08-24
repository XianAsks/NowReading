#!/usr/bin/env bash
# Build the PDF and EPUB editions of the 1929 reader companion.
#
# PDF:  pdflatex -> biber -> pdflatex -> pdflatex
# EPUB: tex4ebook, if installed, is used directly (it wraps make4ht/htlatex and
#       packages the result as a spec-compliant EPUB with proper OPF/NCX metadata).
#       tex4ebook ships from CTAN, not from Ubuntu's apt repositories or TeX Live's
#       Debian packaging, so on a machine without CTAN/tlmgr access this script
#       falls back to the same underlying engine tex4ebook itself uses --
#       htlatex (tex4ht) -> biber -> htlatex -> pandoc (HTML to EPUB) -- which
#       produces a readable, valid EPUB from the same .tex/.bib source but with
#       plainer packaging (no custom cover, simpler nav) than tex4ebook would.
set -euo pipefail
cd "$(dirname "$0")"

SRC="sorkin-1929-reader-companion"
TITLE="A Reader's Companion to 1929"
AUTHOR="Claude (Sonnet 5), Anthropic"

echo "== PDF =="
pdflatex -interaction=nonstopmode -halt-on-error "$SRC.tex"
biber "$SRC"
pdflatex -interaction=nonstopmode -halt-on-error "$SRC.tex"
pdflatex -interaction=nonstopmode -halt-on-error "$SRC.tex"

echo "== EPUB =="
if command -v tex4ebook >/dev/null 2>&1; then
  tex4ebook -f epub3 "$SRC.tex"
else
  echo "tex4ebook not found; falling back to htlatex + pandoc (see comment above)."
  htlatex "$SRC.tex" "xhtml,charset=utf-8" " -cunihtf -utf8"
  biber "$SRC"
  htlatex "$SRC.tex" "xhtml,charset=utf-8" " -cunihtf -utf8"
  # hyperref/tex4ht emit an empty <span id="x1-..."></span> or <a id="x1-..."></a>
  # anchor (its internal page/section numbering scheme) before nearly every
  # heading and cross-reference, purely so pdflatex-style internal links have a
  # target. Left in place, hyperref's anchor counter can alias across unrelated
  # locations, giving pandoc's EPUB output duplicate ids and empty-content nav
  # entries that fail EPUB validation (RSC-005/RSC-007). Strip only these "x1-"
  # anchors -- NOT the "cite.0@<key>" anchors biblatex uses to link each in-text
  # citation to its numbered reference-list entry, which must survive intact.
  perl -0777 -pi -e 's/<(span|a)\s+id="x1-[^"]*">\s*<\/\1>//g' "$SRC.html"
  # --epub-title-page=false: use the .tex source's own \maketitle title page
  # instead of pandoc's auto-generated one.
  # --split-level=3: without an explicit split point, pandoc 3.1.3 keeps this
  # document as a single content file and its nav.xhtml generation for that
  # case is buggy here -- internal links resolve to "text/" with no filename
  # (EPUBCheck RSC-007). Splitting into one file per \section (level 3 in
  # tex4ht's output: title > section > subsection) avoids that code path
  # entirely and validates clean under EPUBCheck.
  pandoc "$SRC.html" \
    --from=html --to=epub3 \
    --metadata title="$TITLE" \
    --metadata author="$AUTHOR" \
    --metadata lang=en \
    --epub-title-page=false \
    --split-level=3 \
    --css="$SRC.css" \
    -o "$SRC.epub"
fi

echo "== Cleaning intermediate files =="
rm -f "$SRC".{aux,log,bbl,bcf,blg,out,run.xml,4ct,4tc,idv,lg,tmp,xref,dvi}
rm -f "$SRC.html" "$SRC.css"

echo "Done: $SRC.pdf and $SRC.epub"
