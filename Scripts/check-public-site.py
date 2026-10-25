#!/usr/bin/env python3
"""Read-only smoke check of the *public* FoldReady host, not GitHub Pages.

Only checks verifiable HTTP content and an asset. This cannot assert a
particular git SHA until the VPS deploy embeds provenance in its export.
"""
from __future__ import annotations

import argparse
from hashlib import sha256
from html.parser import HTMLParser
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import urljoin, urlparse
from urllib.request import Request, urlopen

DEFAULT_URL = "https://foldready.memolabs.dev/"
EXPECTED_HEADLINE = "Know what breaks when your iPhone app resizes."
EXPECTED_SAMPLE = "Fewer false alarms. Clearer decisions."
MAX_HTML = 1024 * 1024
TIMEOUT = 20


class VisibleHTML(HTMLParser):
    """Extract headings, option labels and styles without JS execution."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.headings: list[str] = []
        self.options: list[str] = []
        self.stylesheets: list[str] = []
        self._capture: str | None = None
        self._pieces: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attr = dict(attrs)
        if tag in ("h1", "h2", "option"):
            self._capture = tag
            self._pieces = []
        if tag == "link" and "stylesheet" in (attr.get("rel") or "").split():
            if attr.get("href"):
                self.stylesheets.append(attr["href"])

    def handle_data(self, data: str) -> None:
        if self._capture:
            self._pieces.append(data)

    def handle_endtag(self, tag: str) -> None:
        if tag == self._capture:
            text = " ".join(" ".join(self._pieces).split())
            if tag == "option":
                self.options.append(text)
            else:
                self.headings.append(text)
            self._pieces = []
            self._capture = None


def inspect_home(html: str) -> tuple[VisibleHTML, list[str]]:
    parser = VisibleHTML()
    parser.feed(html)
    errors: list[str] = []
    if EXPECTED_HEADLINE not in parser.headings:
        errors.append("homepage missing expected H1 (possible stale public export)")
    if EXPECTED_SAMPLE not in parser.headings:
        errors.append("homepage missing reviewed-example heading")
    if not parser.stylesheets:
        errors.append("homepage missing CSS stylesheet link")
    return parser, errors


def inspect_request_page(html: str) -> list[str]:
    parser = VisibleHTML()
    parser.feed(html)
    errors = []
    if not any("Human source review" in item and "$349" in item for item in parser.options):
        errors.append("request page missing $349 source-only review option")
    if not any("runtime testing or fixes" in item for item in parser.options):
        errors.append("request page missing separately quoted runtime validation option")
    if "mailto:hello@memolabs.dev" not in html:
        # Mailto lives in the client JS, not in prerendered HTML; don't assert it.
        pass
    return errors


def get_text(url: str) -> tuple[str, str | None]:
    req = Request(url, headers={"User-Agent": "FoldReady-public-smoke/1.0"})
    with urlopen(req, timeout=TIMEOUT) as response:
        if response.status != 200:
            raise ValueError(f"{url}: HTTP {response.status}")
        data = response.read(MAX_HTML + 1)
        if len(data) > MAX_HTML:
            raise ValueError(f"{url}: HTML too large")
        charset = response.headers.get_content_charset() or "utf-8"
        return data.decode(charset), response.headers.get("Last-Modified")


def check(base_url: str) -> list[str]:
    if urlparse(base_url).scheme != "https":
        return ["public host must use HTTPS"]
    origin = base_url.rstrip("/") + "/"
    failures: list[str] = []
    for path, inspector in [("", inspect_home), ("get-scored/", inspect_request_page)]:
        url = urljoin(origin, path)
        try:
            document, last_modified = get_text(url)
            digest = sha256(document.encode("utf-8")).hexdigest()[:16]
            print(f"OK HTTP 200 {url} sha256-prefix={digest} last-modified={last_modified or 'unknown'}")
            result = inspector(document)
            if path == "":
                parsed, errors = result
                failures.extend(errors)
                if parsed.stylesheets:
                    css_url = urljoin(origin, parsed.stylesheets[0])
                    if urlparse(css_url).netloc != urlparse(origin).netloc:
                        failures.append("stylesheet points outside production host")
                    else:
                        try:
                            css, _ = get_text(css_url)
                            if not css.strip():
                                failures.append("first stylesheet returned empty content")
                            else:
                                print(f"OK CSS asset {css_url}")
                        except (HTTPError, URLError, ValueError, UnicodeError) as exc:
                            failures.append(f"stylesheet unavailable: {exc}")
            else:
                failures.extend(result)
        except (HTTPError, URLError, ValueError, UnicodeError) as exc:
            failures.append(f"cannot retrieve {url}: {exc}")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default=DEFAULT_URL)
    args = parser.parse_args()
    failures = check(args.url)
    if failures:
        for failure in failures:
            print(f"FAIL: {failure}", file=sys.stderr)
        return 1
    print("Public FoldReady host smoke check passed (content, not deployment SHA).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
