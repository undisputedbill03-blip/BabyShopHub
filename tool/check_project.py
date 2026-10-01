#!/usr/bin/env python3
"""
Static sanity checker for the BabyShopHub Flutter project.

This does NOT compile the app. There is no Dart/Flutter SDK in the environment
this was written in, so the real gate is `flutter analyze` on your own machine.
What this script does is catch the structural mistakes that are easy to make
across 70+ files and slow to find by eye:

  1. Unbalanced braces / parentheses / brackets in any .dart file
     (the classic sign of a truncated or mis-edited file), using a lexer that
     ignores delimiters inside strings and comments.
  2. Relative `import`/`export` targets that point at a file which does not
     exist (a broken import graph will not compile).
  3. Asset paths written in code (assets/...) that are missing on disk.
  4. pubspec.yaml basics: the dependencies the code imports are declared, and
     the asset folders are registered.
  5. Screen/Shell classes that are referenced (e.g. pushed as a route) but
     never defined anywhere in lib/ - the "I forgot to create that file" bug.

Exit code is 0 when nothing is flagged, 1 otherwise, so it can gate a script.
Run:  python3 tool/check_project.py
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"

# ANSI colours, disabled automatically when output is not a TTY.
_TTY = sys.stdout.isatty()
def _c(code: str, text: str) -> str:
    return f"\033[{code}m{text}\033[0m" if _TTY else text
def red(t: str) -> str: return _c("31", t)
def green(t: str) -> str: return _c("32", t)
def yellow(t: str) -> str: return _c("33", t)
def bold(t: str) -> str: return _c("1", t)

problems: list[str] = []
warnings: list[str] = []


def strip_strings_and_comments(src: str) -> str:
    """Return the source with string literals and comments blanked out, so a
    delimiter counter never trips over a brace inside a string or a `//` note.
    Newlines are preserved so line numbers stay meaningful."""
    out = []
    i = 0
    n = len(src)
    while i < n:
        ch = src[i]
        two = src[i:i + 2]

        # Line comment
        if two == "//":
            while i < n and src[i] != "\n":
                i += 1
            continue
        # Block comment
        if two == "/*":
            i += 2
            while i < n and src[i:i + 2] != "*/":
                if src[i] == "\n":
                    out.append("\n")
                i += 1
            i += 2
            continue
        # Raw strings r'...' / r"..."
        if ch == "r" and i + 1 < n and src[i + 1] in "'\"":
            quote = src[i + 1]
            i += 2
            while i < n and src[i] != quote:
                if src[i] == "\n":
                    out.append("\n")
                i += 1
            i += 1
            continue
        # Triple-quoted strings
        if two * 1 and src[i:i + 3] in ("'''", '"""'):
            triple = src[i:i + 3]
            i += 3
            while i < n and src[i:i + 3] != triple:
                if src[i] == "\n":
                    out.append("\n")
                i += 1
            i += 3
            continue
        # Normal strings, honouring escapes and $ interpolation braces.
        if ch in "'\"":
            quote = ch
            i += 1
            while i < n and src[i] != quote:
                if src[i] == "\\":
                    i += 2
                    continue
                # Blank out a ${...} interpolation entirely. The braces are
                # balanced against each other, so emitting neither of them
                # keeps the surrounding file's brace count correct.
                if src[i] == "$" and i + 1 < n and src[i + 1] == "{":
                    i += 2
                    depth = 1
                    while i < n and depth > 0:
                        if src[i] == "{":
                            depth += 1
                        elif src[i] == "}":
                            depth -= 1
                        out.append("\n" if src[i] == "\n" else " ")
                        i += 1
                    continue
                if src[i] == "\n":
                    out.append("\n")
                i += 1
            i += 1
            continue

        out.append(ch)
        i += 1
    return "".join(out)


def check_delimiters(path: Path, cleaned: str) -> None:
    pairs = {")": "(", "]": "[", "}": "{"}
    openers = set(pairs.values())
    stack: list[tuple[str, int]] = []
    line = 1
    for ch in cleaned:
        if ch == "\n":
            line += 1
        elif ch in openers:
            stack.append((ch, line))
        elif ch in pairs:
            if not stack or stack[-1][0] != pairs[ch]:
                rel = path.relative_to(ROOT)
                problems.append(
                    f"{rel}:{line}: unbalanced '{ch}' "
                    f"(no matching '{pairs[ch]}')")
                return
            stack.pop()
    if stack:
        opener, oline = stack[-1]
        rel = path.relative_to(ROOT)
        problems.append(
            f"{rel}:{oline}: '{opener}' is never closed")


IMPORT_RE = re.compile(r"""^\s*(?:import|export)\s+['"]([^'"]+)['"]""", re.M)


def check_imports(path: Path, src: str) -> None:
    for target in IMPORT_RE.findall(src):
        if target.startswith("package:") or target.startswith("dart:"):
            continue
        resolved = (path.parent / target).resolve()
        if not resolved.exists():
            rel = path.relative_to(ROOT)
            problems.append(f"{rel}: import '{target}' does not resolve to a file")


ASSET_RE = re.compile(r"""['"](assets/[^'"]+\.[a-zA-Z0-9]+)['"]""")


def check_assets(path: Path, cleaned_src_with_strings: str) -> None:
    # Note: run against the ORIGINAL source (asset paths live inside strings).
    for asset in ASSET_RE.findall(cleaned_src_with_strings):
        # Skip interpolated paths (handled dynamically at runtime).
        if "$" in asset:
            continue
        if not (ROOT / asset).exists():
            rel = path.relative_to(ROOT)
            warnings.append(f"{rel}: asset '{asset}' not found on disk")


def main() -> int:
    dart_files = sorted(LIB.rglob("*.dart"))
    if not dart_files:
        print(red("No Dart files found under lib/."))
        return 1

    defined_classes: set[str] = set()
    referenced_screens: dict[str, Path] = {}
    class_def_re = re.compile(r"\b(?:class|enum|mixin)\s+([A-Z]\w+)")
    # A screen/shell referenced as a widget constructor call.
    screen_ref_re = re.compile(r"\b([A-Z]\w*(?:Screen|Shell))\s*\(")

    for path in dart_files:
        src = path.read_text(encoding="utf-8", errors="replace")
        cleaned = strip_strings_and_comments(src)

        check_delimiters(path, cleaned)
        check_imports(path, src)
        check_assets(path, src)

        for m in class_def_re.findall(cleaned):
            defined_classes.add(m)
        for m in screen_ref_re.findall(cleaned):
            referenced_screens.setdefault(m, path)

    # Any Screen/Shell class used but never declared in the project.
    for name, path in sorted(referenced_screens.items()):
        if name not in defined_classes:
            rel = path.relative_to(ROOT)
            problems.append(
                f"{rel}: references '{name}(...)' but no such class is "
                f"defined in lib/")

    check_pubspec(dart_files)

    # ---- report -------------------------------------------------------
    print(bold(f"Checked {len(dart_files)} Dart files under lib/.\n"))

    if warnings:
        print(yellow(f"{len(warnings)} warning(s):"))
        for w in warnings:
            print("  " + yellow("! ") + w)
        print()

    if problems:
        print(red(f"{len(problems)} problem(s) found:"))
        for p in problems:
            print("  " + red("x ") + p)
        print()
        print(red(bold("FAIL - fix the above, then run `flutter analyze`.")))
        return 1

    print(green(bold("OK - no structural problems found.")))
    print("This is a static check only; it does not replace `flutter analyze`\n"
          "or `flutter run`. Run those on a machine with the Flutter SDK.")
    return 0


def check_pubspec(dart_files: list[Path]) -> None:
    pub = ROOT / "pubspec.yaml"
    if not pub.exists():
        problems.append("pubspec.yaml is missing.")
        return
    text = pub.read_text(encoding="utf-8", errors="replace")

    # Which third-party packages does the code actually import?
    pkg_re = re.compile(r"""import\s+['"]package:([a-z0-9_]+)/""")
    used: set[str] = set()
    for path in dart_files:
        for pkg in pkg_re.findall(path.read_text(encoding="utf-8", errors="replace")):
            used.add(pkg)
    # `flutter` is provided by the SDK block, not a normal dependency line.
    used.discard("flutter")

    for pkg in sorted(used):
        # A loose check: the package name appears as a dependency key.
        if not re.search(rf"^\s+{re.escape(pkg)}\s*:", text, re.M):
            problems.append(
                f"pubspec.yaml: package '{pkg}' is imported in code but not "
                f"declared under dependencies.")

    # Assets: if code references assets/, pubspec should register the folder.
    if "assets/" in text:
        if not re.search(r"^\s*assets\s*:", text, re.M):
            warnings.append(
                "pubspec.yaml: no 'assets:' section found although asset "
                "paths are used in code.")


if __name__ == "__main__":
    sys.exit(main())
