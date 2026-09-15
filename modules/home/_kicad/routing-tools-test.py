"""Smoke-test the installed payload with KiCad's own Python environment."""

import sys
from pathlib import Path

root = Path(sys.argv[1])
version = sys.argv[2]
assert (root / "rust_router/grid_router.so").is_file(), "Rust router is not installed"

sys.path[:0] = [
    str(root / subdir)
    for subdir in ("", "py_router", "py_placer", "py_tools", "rust_router")
]

from startup_checks import run_all_checks

assert run_all_checks() == version

from grid_router import GridObstacleMap, GridRouter

start = (2, 2, 0)
end = (20, 2, 0)
router = GridRouter(via_cost=500, h_weight=1.0, turn_cost=10, layer_costs=[1000])
path, _, _ = router.route_multi(
    GridObstacleMap(1), [start], [end], 10000, False, 0, None, None, 0, 0
)
assert path and path[0] == start and path[-1] == end, path

import wx

from kicad_routing_plugin.deps_check import _missing_packages
from kicad_routing_plugin.action_plugin import KiCadRoutingToolsPlugin
from kicad_routing_plugin.swig_gui import RoutingDialog

assert not _missing_packages(), "Plugin would offer a runtime pip install"
assert issubclass(RoutingDialog, wx.Dialog)
plugin = KiCadRoutingToolsPlugin()
assert plugin.GetName() == "KiCadRoutingTools"
assert plugin.GetShowToolbarButton()
assert Path(plugin.GetIconFileName(False)).is_file()

# Native action registration requires a running KiCad application, not just
# pcbnew imported in Python. Check that separately in the PCB editor.
print(f"KiCadRoutingTools {version}: Rust routing, dependencies and GUI imports passed")
