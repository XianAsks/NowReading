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
  # target. Most of these are genuinely dead (nothing in the HTML links to
  # them), but hyperref's anchor counter can occasionally alias two unrelated
  # locations to the same "x1-..." id, which gives pandoc's EPUB output
  # duplicate ids and empty-content nav entries that fail EPUB validation
  # (RSC-005/RSC-007) -- UNLESS the id is a real link target, e.g. from this
  # document's own \tableofcontents or \label/\ref cross-references, in which
  # case removing it breaks that link instead (RSC-012). So strip an empty
  # "x1-..." anchor only when no href="#that-id" exists anywhere in the file;
  # anchors actually pointed to (including the "cite.0@<key>" ones biblatex
  # uses to link a citation to its reference-list entry, which are never
  # empty and so untouched by this regex anyway) are left alone.
  perl -0777 -pi -e '
    my %needed;
    $needed{$1} = 1 while /href="#([^"]+)"/g;
    s/<(span|a)\s+id="(x1-[^"]*)">\s*<\/\1>/$needed{$2} ? $& : ""/ge;
  ' "$SRC.html"
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

  # pandoc's own EPUB3 nav.xhtml (the navigation document, distinct from this
  # document's in-body \tableofcontents) copies each heading's raw inner HTML
  # -- including the now-necessarily-preserved empty "x1-..." anchors that
  # make the in-body TOC and \label/\ref links work -- into its link text.
  # Duplicating an empty anchor there is harmless for navigation but fails
  # EPUBCheck (RSC-005: "Spans within nav elements must contain text"), so
  # unzip the just-built EPUB, strip empty id spans/anchors from nav.xhtml
  # only, and repackage: mimetype first and stored (uncompressed), per the
  # EPUB OCF spec.
  EPUBTMP="$(mktemp -d)"
  unzip -q "$SRC.epub" -d "$EPUBTMP"
  # nav.xhtml is serialized as proper XHTML, where an empty element is
  # self-closing (<span id="..." />) rather than open/close, unlike the loose
  # HTML tex4ht produced -- so match both forms.
  perl -0777 -pi -e '
    s/<(span|a)\s+id="[^"]*">\s*<\/\1>//g;
    s/<(span|a)\s+id="[^"]*"\s*\/>//g;
  ' "$EPUBTMP/EPUB/nav.xhtml"
  rm -f "$SRC.epub"
  (cd "$EPUBTMP" && zip -q -X -0 "$OLDPWD/$SRC.epub" mimetype && \
   zip -q -X -r -D "$OLDPWD/$SRC.epub" . -x mimetype)
  rm -rf "$EPUBTMP"
fi

echo "== Cleaning intermediate files =="
rm -f "$SRC".{aux,log,bbl,bcf,blg,out,run.xml,4ct,4tc,idv,lg,tmp,xref,dvi}
rm -f "$SRC.html" "$SRC.css"

echo "Done: $SRC.pdf and $SRC.epub"
