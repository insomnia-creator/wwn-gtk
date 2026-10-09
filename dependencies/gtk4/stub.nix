# Port stub for the GTK4 library closure (GDK Wayland + GSK). Evaluates cleanly
# but fails the build with a clear message until the real port lands.
#
# Phase 1 target: GSK_RENDERER=cairo + wl_shm (all targets, including watchOS).
# GL (GSK ngl) is added later on allowGpu targets via wwn-iland.
{ ... }:
throw "wwn-gtk: GTK4 closure is not implemented yet (scaffold only). See README.md port plan."
