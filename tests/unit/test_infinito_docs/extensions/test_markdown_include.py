import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace


def _add_src_to_path() -> None:
    root = Path(__file__).resolve()
    while root != root.parent and not (root / "src").exists():
        root = root.parent
    sys.path.insert(0, str(root / "src"))


_add_src_to_path()

from infinito_docs.extensions.markdown_include import MarkdownIncludeDirective, setup  # noqa: E402


class _FakeReporter:
    def error(self, message, *args, **kwargs):
        return ("ERROR", message)


class _FakeStateMachine:
    def __init__(self) -> None:
        self.reporter = _FakeReporter()


class _FakeEnv:
    def __init__(self, base: Path) -> None:
        self._base = base

    def relfn2path(self, arg: str):
        p = (self._base / arg).resolve()
        return (arg, str(p))


class _FakeState:
    def __init__(self, env) -> None:
        self.document = SimpleNamespace(settings=SimpleNamespace(env=env))


class _FakeApp:
    def __init__(self) -> None:
        self.added = {}

    def add_directive(self, name: str, directive) -> None:
        self.added[name] = directive


class TestMarkdownInclude(unittest.TestCase):
    def test_setup_registers_directive(self) -> None:
        app = _FakeApp()
        setup(app)
        self.assertIn("markdown-include", app.added)
        self.assertIs(app.added["markdown-include"], MarkdownIncludeDirective)

    def test_run_missing_file_returns_error_node(self) -> None:
        with TemporaryDirectory() as td:
            env = _FakeEnv(Path(td))
            state = _FakeState(env)
            sm = _FakeStateMachine()

            d = MarkdownIncludeDirective(
                name="markdown-include",
                arguments=["nope.md"],
                options={},
                content=[],
                lineno=1,
                content_offset=0,
                block_text=".. markdown-include:: nope.md",
                state=state,
                state_machine=sm,
            )
            res = d.run()
            self.assertEqual(len(res), 1)
            self.assertEqual(res[0][0], "ERROR")
            self.assertIn("File not found", res[0][1])


if __name__ == "__main__":
    unittest.main()
