#!/usr/bin/env python3
import sys
import gi
version, path = sys.argv[1:3]
gi.require_version("Gtk", version)
from gi.repository import Gtk
provider = Gtk.CssProvider()
provider.load_from_path(path)
print(f"PASS GTK {version} CSS {path}")
