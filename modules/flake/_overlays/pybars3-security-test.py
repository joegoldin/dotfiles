"""Regression coverage for CVE-2026-119716 and adjacent code-generation paths."""

import builtins
import unittest

from pybars import Compiler


class TestQuotedNames(unittest.TestCase):
    def test_bracketed_argument_cannot_execute_python(self):
        calls = []
        builtins._pybars_security_probe = lambda: calls.append(True)
        key = "x', __import__('builtins')._pybars_security_probe(), 'x"
        try:
            template = Compiler().compile("{{identity [" + key + "]}}")
            result = template({key: "safe"}, helpers={"identity": lambda _, value: value})
            self.assertEqual(calls, [], "template path executed Python")
            self.assertEqual(str(result), "safe")
        finally:
            del builtins._pybars_security_probe

    def test_bracketed_paths_preserve_special_characters(self):
        for key in ["a'b", 'a"b', "a\\b", "a\nb", "café"]:
            for expression, context in [
                ("[" + key + "]", {key: "safe"}),
                ("outer.[" + key + "]", {"outer": {key: "safe"}}),
                ("identity [" + key + "]", {key: "safe"}),
                ("identity outer.[" + key + "]", {"outer": {key: "safe"}}),
                ("identity ([" + key + "])", {}),
            ]:
                with self.subTest(key=key, expression=expression):
                    template = Compiler().compile("{{{" + expression + "}}}")
                    result = template(context, helpers={
                        "identity": lambda _, value: value,
                        key: lambda _: "safe",
                    })
                    self.assertEqual(str(result), "safe")

    def test_partial_names_preserve_special_characters(self):
        for key in ["a'b", "a\\b"]:
            with self.subTest(key=key):
                compiler = Compiler()
                template = compiler.compile("{{> [" + key + "]}}")
                result = template({}, partials={key: compiler.compile("safe")})
                self.assertEqual(str(result), "safe")


if __name__ == "__main__":
    unittest.main()
