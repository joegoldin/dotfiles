#!/usr/bin/env python3
"""Unit test for zen-bookmarks-to-nix.py — builds a synthetic places.sqlite,
runs the extractor, and validates the emitted Nix via nix-instantiate."""
import json
import os
import sqlite3
import subprocess
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(HERE, "zen-bookmarks-to-nix.py")


def make_places(path):
    c = sqlite3.connect(path)
    cur = c.cursor()
    cur.execute("CREATE TABLE moz_places (id INTEGER PRIMARY KEY, url TEXT)")
    cur.execute(
        "CREATE TABLE moz_bookmarks (id INTEGER PRIMARY KEY, type INTEGER, "
        "fk INTEGER, parent INTEGER, position INTEGER, title TEXT, guid TEXT)"
    )
    cur.execute("CREATE TABLE moz_keywords (id INTEGER PRIMARY KEY, keyword TEXT, place_id INTEGER)")
    # places
    cur.executemany("INSERT INTO moz_places (id, url) VALUES (?, ?)", [
        (10, "https://example.com"),
        (11, "place:type=6&sort=14"),      # smart folder -> skipped
        (12, "https://nix.dev"),
        (13, "https://kagi.com/search?q=%s"),
        (14, 'https://quotes.test/"weird"-${x}'),  # escaping
    ])
    # roots
    cur.executemany(
        "INSERT INTO moz_bookmarks (id, type, fk, parent, position, title, guid) VALUES (?,?,?,?,?,?,?)",
        [
            (1, 2, None, 0, 0, "", "root________"),
            (2, 2, None, 1, 0, "toolbar", "toolbar_____"),
            (3, 2, None, 1, 1, "menu", "menu________"),
            (4, 2, None, 1, 2, "unfiled", "unfiled_____"),
            # toolbar children
            (20, 1, 10, 2, 0, "Example", "b1__________"),
            (21, 3, None, 2, 1, None, "s1__________"),    # separator
            (22, 2, None, 2, 2, "Dev", "f1__________"),   # folder
            (23, 1, 11, 2, 3, "Smart", "b2__________"),   # place: -> skipped
            (24, 1, 14, 2, 4, "Weird", "b5__________"),   # escaping
            # folder child
            (30, 1, 12, 22, 0, "Nix", "b3__________"),
            # menu child
            (40, 1, 13, 3, 0, "Kagi", "b4__________"),
        ],
    )
    cur.execute("INSERT INTO moz_keywords (id, keyword, place_id) VALUES (1, 'k', 13)")
    c.commit()
    c.close()


def eval_nix(nix_path):
    out = subprocess.check_output(
        ["nix-instantiate", "--eval", "--strict", "--json", nix_path], text=True
    )
    return json.loads(out)


class TestExtractor(unittest.TestCase):
    def test_structure(self):
        with tempfile.TemporaryDirectory() as td:
            db = os.path.join(td, "places.sqlite")
            make_places(db)
            out = os.path.join(td, "bookmarks.nix")
            subprocess.check_call(
                ["python3", SCRIPT, "--profile", td, "--output", out]
            )
            data = eval_nix(out)

        # top level: toolbar dir, then menu items (Kagi), no Other (unfiled empty)
        toolbar = data[0]
        self.assertTrue(toolbar["toolbar"])
        self.assertEqual(toolbar["name"], "Bookmarks Toolbar")
        names = [n.get("name") if isinstance(n, dict) else n for n in toolbar["bookmarks"]]
        self.assertIn("Example", names)
        self.assertIn("separator", toolbar["bookmarks"])
        self.assertIn("Dev", names)
        self.assertNotIn("Smart", names)  # place: skipped
        # nested folder
        dev = next(n for n in toolbar["bookmarks"] if isinstance(n, dict) and n.get("name") == "Dev")
        self.assertEqual(dev["bookmarks"][0]["url"], "https://nix.dev")
        # escaping preserved
        weird = next(n for n in toolbar["bookmarks"] if isinstance(n, dict) and n.get("name") == "Weird")
        self.assertEqual(weird["url"], 'https://quotes.test/"weird"-${x}')
        # menu item with keyword, at top level
        kagi = next(n for n in data if isinstance(n, dict) and n.get("name") == "Kagi")
        self.assertEqual(kagi["keyword"], "k")
        self.assertEqual(kagi["url"], "https://kagi.com/search?q=%s")


if __name__ == "__main__":
    unittest.main()
