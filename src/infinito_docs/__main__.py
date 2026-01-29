from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


def parse_makefile_targets(makefile_path: Path) -> dict[str, str]:
    targets: dict[str, str] = {}
    pattern = re.compile(r"^([\w%\-]+):")

    lines = makefile_path.read_text(encoding="utf-8").splitlines(True)

    for idx, line in enumerate(lines):
        match = pattern.match(line)
        if not match:
            continue

        target = match.group(1)
        desc = ""
        for prev in range(idx - 1, -1, -1):
            prev_line = lines[prev].strip()
            if prev_line.startswith("#"):
                desc = prev_line.lstrip("# ").strip()
                break
            if prev_line:
                break

        targets[target] = desc

    return targets


def run_make_command(make_target: str, repo_root: Path) -> int:
    """
    Run `make <target>` in the repo root and stream output.
    Returns process exit code.
    """
    proc = subprocess.Popen(
        ["make", make_target],
        cwd=str(repo_root),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    assert proc.stdout is not None
    assert proc.stderr is not None

    for line in proc.stdout:
        print(line, end="")
    for line in proc.stderr:
        print(line, end="", file=sys.stderr)

    return proc.wait()


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv

    repo_root = Path.cwd()
    makefile_path = repo_root / "Makefile"
    if not makefile_path.exists():
        print("Error: Makefile not found in current working directory.", file=sys.stderr)
        return 2

    parser = argparse.ArgumentParser(
        prog="infinito-sphinx",
        description="Proxy to Makefile targets with auto-generated help from Makefile comments",
    )
    subparsers = parser.add_subparsers(dest="command", help="Available Makefile targets")

    targets = parse_makefile_targets(makefile_path)
    for target, desc in targets.items():
        subparsers.add_parser(target, help=desc)

    args = parser.parse_args(argv)

    if not args.command:
        parser.print_help()
        return 0

    return run_make_command(args.command, repo_root)


if __name__ == "__main__":
    raise SystemExit(main())
