# Port stub for gtk4-demo (upstream demos/gtk-demo). Evaluates cleanly but
# fails the build with a clear message until the real port lands.
#
# Entry symbol: gtk4_demo_main (in-process dispatch on Apple mobile; NSTask on
# macOS; .so on Android).
{ ... }:
throw "wwn-gtk: gtk4-demo is not implemented yet (scaffold only). See README.md port plan."
