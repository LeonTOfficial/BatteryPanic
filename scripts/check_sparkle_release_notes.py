#!/usr/bin/env python3
"""Validate the navigation-safe cue used by future Sparkle release notes."""

from __future__ import annotations

import argparse
import re
import sys
from html.parser import HTMLParser
from pathlib import Path


PUBLIC_NOTES_ROOT = "https://leontofficial.github.io/BatteryPanic/sparkle-release-notes"
VERSION_PATTERN = re.compile(r"^\d+\.\d+\.\d+$")
VOID_ELEMENTS = {
    "area",
    "base",
    "br",
    "col",
    "embed",
    "hr",
    "img",
    "input",
    "link",
    "meta",
    "param",
    "source",
    "track",
    "wbr",
}


class ReleaseNotesParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.stack: list[tuple[str, dict[str, str]]] = []
        self.ids: dict[str, list[tuple[str, dict[str, str]]]] = {}
        self.fragment_links: list[str] = []
        self.script_count = 0
        self.fallback_forms: list[dict[str, str]] = []
        self.fallback_submit_buttons: list[dict[str, str]] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attributes = {name: value or "" for name, value in attrs}
        element_id = attributes.get("id")
        if element_id:
            self.ids.setdefault(element_id, []).append((tag, attributes))

        href = attributes.get("href", "")
        if tag == "a" and href.startswith("#"):
            self.fragment_links.append(href)

        if tag == "script":
            self.script_count += 1

        classes = set(attributes.get("class", "").split())
        if tag == "form" and "scroll-cue-form" in classes:
            self.fallback_forms.append(attributes)

        inside_fallback = any(
            ancestor_tag == "form"
            and "scroll-cue-form" in set(ancestor_attrs.get("class", "").split())
            for ancestor_tag, ancestor_attrs in self.stack
        )
        if tag == "button" and inside_fallback and attributes.get("type") == "submit":
            self.fallback_submit_buttons.append(attributes)

        if tag not in VOID_ELEMENTS:
            self.stack.append((tag, attributes))

    def handle_startendtag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        self.handle_starttag(tag, attrs)
        if tag not in VOID_ELEMENTS:
            self.handle_endtag(tag)

    def handle_endtag(self, tag: str) -> None:
        for index in range(len(self.stack) - 1, -1, -1):
            if self.stack[index][0] == tag:
                del self.stack[index:]
                return


def validate(path: Path, *, template: bool) -> list[str]:
    errors: list[str] = []
    try:
        source = path.read_text(encoding="utf-8")
    except OSError as error:
        return [f"cannot read file: {error}"]

    parser = ReleaseNotesParser()
    parser.feed(source)
    parser.close()

    duplicate_ids = sorted(element_id for element_id, elements in parser.ids.items() if len(elements) > 1)
    if duplicate_ids:
        errors.append(f"duplicate ids: {', '.join(duplicate_ids)}")

    changes = parser.ids.get("changes", [])
    if len(changes) != 1 or changes[0][0] != "section":
        errors.append('expected exactly one <section id="changes">')

    cue = parser.ids.get("scroll-cue", [])
    if len(cue) != 1 or cue[0][0] != "button":
        errors.append('expected exactly one <button id="scroll-cue">')
    else:
        cue_attrs = cue[0][1]
        if cue_attrs.get("type") != "button":
            errors.append('scroll cue must use type="button"')
        if cue_attrs.get("popovertarget") != "scroll-cue-state":
            errors.append('scroll cue must target "scroll-cue-state"')
        if cue_attrs.get("aria-controls") != "changes":
            errors.append('scroll cue must declare aria-controls="changes"')
        if "href" in cue_attrs:
            errors.append("scroll cue must not have an href")

    state = parser.ids.get("scroll-cue-state", [])
    if len(state) != 1 or state[0][1].get("popover") != "manual":
        errors.append('expected one #scroll-cue-state element with popover="manual"')

    if parser.fragment_links:
        errors.append(
            "fragment-only links are unsafe in Sparkle: " + ", ".join(parser.fragment_links)
        )

    if parser.script_count:
        errors.append("release-note cue must work without JavaScript")

    if len(parser.fallback_forms) != 1:
        errors.append("expected exactly one .scroll-cue-form fallback")
    else:
        fallback = parser.fallback_forms[0]
        if fallback.get("method", "").lower() != "get":
            errors.append('fallback form must use method="get"')

        if template:
            expected_action = f"{PUBLIC_NOTES_ROOT}/__VERSION__/#changes"
        else:
            version = path.parent.name
            if not VERSION_PATTERN.fullmatch(version):
                errors.append("release-note directory must be a semantic version such as 0.7.1")
                expected_action = None
            else:
                expected_action = f"{PUBLIC_NOTES_ROOT}/{version}/#changes"

        if expected_action is not None and fallback.get("action") != expected_action:
            errors.append(f"fallback action must be {expected_action}")

    if len(parser.fallback_submit_buttons) != 1:
        errors.append("fallback form must contain exactly one submit button")

    required_css = (
        "@supports selector(body:has(#scroll-cue-state:popover-open))",
        "body:has(#scroll-cue-state:popover-open) .intro",
        "body:has(#scroll-cue-state:popover-open) .changes",
        "@media (prefers-reduced-motion: reduce)",
    )
    for snippet in required_css:
        if snippet not in source:
            errors.append(f"missing required CSS: {snippet}")

    if "Scroll down to see all changes" not in source:
        errors.append("missing the accessible scroll-cue label")

    if template:
        if "__VERSION__" not in source:
            errors.append("template must retain the __VERSION__ placeholder")
    else:
        if "__VERSION__" in source:
            errors.append("release notes still contain the __VERSION__ placeholder")
        if "Replace this" in source:
            errors.append("release notes still contain template copy")

    return errors


def main() -> int:
    argument_parser = argparse.ArgumentParser()
    argument_parser.add_argument(
        "--template",
        action="store_true",
        help="allow the __VERSION__ and editorial placeholders in the canonical template",
    )
    argument_parser.add_argument("paths", nargs="+", type=Path)
    arguments = argument_parser.parse_args()

    failed = False
    for path in arguments.paths:
        errors = validate(path, template=arguments.template)
        if errors:
            failed = True
            for error in errors:
                print(f"{path}: {error}", file=sys.stderr)
        else:
            print(f"Sparkle release notes OK: {path}")

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
