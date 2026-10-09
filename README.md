# wwn-gtk

Wawona's port of **GTK4** (GDK Wayland + GSK) and **`gtk4-demo`** to run under
Wawona on the Apple ecosystem and Android, App Store compliant.

> **Status: SKELETON.** flake + `registryFragment` skeleton + port plan only.
> Build stubs fail intentionally; the full port is downstream.

- Tracking issue: [#109](https://github.com/Wawona/Wawona/issues/109)
- Plan mirror: [`Wawona/docs/issues/gtk4-demo-port.md`](https://github.com/Wawona/Wawona/blob/development/docs/issues/gtk4-demo-port.md)
- Toolkit contract: [`toolkit-soft-path.md`](https://github.com/Wawona/Wawona/blob/development/docs/toolkit-soft-path.md)
- Conventions: [`2026-wwn-porting-convention.md`](https://github.com/Wawona/Wawona/blob/development/docs/2026-wwn-porting-convention.md)

## Scope

GTK4 is the shared foundation for `wwn-gnome`, `wwn-gtkgreet`, `wwn-gtklock`,
and GTK-based XFCE clients. Port it **once** here; consumers never re-vendor it.

| Piece | Attr | Notes |
|-------|------|-------|
| GTK4 library closure | `gtk4` | GDK Wayland backend, GSK renderers, GdkPixbuf, Pango, Cairo, Graphene, Epoxy |
| Demo client | `gtk4-demo` | upstream `demos/gtk-demo` → `gtk4_demo_main` |

Env contract: `GDK_BACKEND=wayland`.

## Delivery model

| Platform | Artifact | Launch | Renderer |
|----------|----------|--------|----------|
| macOS | `bin/gtk4-demo` | NSTask from Resources **or** in-process | Wayland; GL demos OK |
| iOS / iPadOS / visionOS | `libgtk4_demo.a` + `gtk4_demo_main` | in-process after install | Cairo/SHM first; GL behind `allowGpu` |
| tvOS | same archive | in-process | Cairo/SHM first; GL behind `allowGpu` (ANGLE). Never IOKit |
| watchOS | same archive | in-process | **Cairo/SHM only.** No Metal in the SDK, so no ANGLE/MoltenVK |
| Android | `libgtk4_demo.so` | exec or in-process | SHM first; GLES optional |
| Linux | host `gtk4-demo` | CI / compat-matrix baseline | reference |

Delivery is **core-bundled or Wasm package**. Never StoreKit ODR via `apt` (that
path was removed).

## Architecture

```text
zsh / Machines (after install / launch gtk4-demo)
  -> wawona_dispatch_inprocess("gtk4-demo")        # Apple mobile
  -> gtk4_demo_main(argc, argv)
       -> GTK4 (GDK Wayland)
       -> Cairo / wl_shm   (all platforms)
       -> GLES / ANGLE     (allowGpu platforms only)
       -> Wawona compositor (Smithay)
```

Registry keys: `gtk4` (library closure) and `gtk4-demo` (demo client recipes).
Entry symbol: `gtk4_demo_main`.

## Port plan

1. **Toolchain.** Consume `wwn-toolchain` substrate (glib, cairo, pango, pixman,
   libwayland, fontconfig, freetype, harfbuzz, fribidi, libpng, libxml2, pcre2,
   expat, xkbcommon). Add missing leaf libs to `wwn-toolchain`: `libffi`,
   `graphene`, `gdk-pixbuf`, `libepoxy` (GL only).
2. **GTK4 cross.** Build GTK4 **Wayland-only**:
   `-Dx11-backend=false -Dbroadway=false -Dintrospection=disabled
   -Daccesskit=disabled -Dtracker=disabled -Dcolord=disabled
   -Dprint-cups=disabled -Dcloudproviders=disabled -Dsysprof=disabled`.
   Sandbox-safe GSettings/schemas/icons (memory backend, bundled schemas).
3. **Compliance patches.** No JIT, no `fork+exec` of external binaries, no
   `dlopen` of arbitrary code, sandbox-safe paths. Replace D-Bus single-instance
   and a11y/portal assumptions with non-unique / no-op paths.
4. **Renderer ladder.** Cairo + `wl_shm` first (all targets). GSK `ngl` (GL) on
   `allowGpu` via `wwn-iland` + ANGLE. Never claim GL on watchOS.
5. **Registry.** Replace `dependencies/gtk4/stub.nix` and
   `dependencies/gtk4-demo/stub.nix` per platform; expose `gtk4-<target>` /
   `gtk4-demo-<target>`; flip `status: planned -> approved`.
6. **Integration.** Wawona flake input + `registryFragment` merge; gate in
   `mobile-platform-deps.nix` / `xcodegen.nix` only when the module is linked;
   dispatch `"gtk4-demo" -> gtk4_demo_main`; inject `GDK_BACKEND=wayland`.

## Wasm lane (separate repo)

The WASIX/WASI build lane for long-tail GTK packages is owned by **`wasinix`**
(producer of record). `wwn-gtk` owns the native Apple/Android port and the
`gtk4-demo` client source. Same split as `wwn-foot` (native) vs the wasm
producer.

## Licensing

Upstream GTK4 is **LGPL-2.1-or-later**; Pango/GLib/GdkPixbuf are LGPL-2.1+;
Cairo is LGPL-2.1+/MPL-1.1. Repo packaging/port glue follows the Wawona org
convention. Preserve upstream notices.
