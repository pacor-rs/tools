# tools

## Template placeholders

The Linux templates are rendered by the packaging tool before use. These
variables must all be present, and the tool fails the build if a template uses
one it does not provide.

| Placeholder | Meaning |
| --- | --- |
| `{{APP_EXECUTABLE_NAME}}` | Executable name produced by `flutter build linux` (CMake `BINARY_NAME`). |
| `{{APP_LIB_DIR}}` | Directory containing `libapp.so` and the bundled libraries, relative to the directory that holds `usr/`. |
| `{{APP_DATA_DIR}}` | Directory containing `flutter_assets` and `icudtl.dat`, relative to the directory that holds `usr/`. |
| `{{APP_APPLICATION_ID}}` | Reverse-DNS GTK application id. |

`APP_LIB_DIR` and `APP_DATA_DIR` exist so that the runner and the installer
cannot disagree about the package layout. They are derived from the same
constants the installer uses:

| Target | `APP_LIB_DIR` | `APP_DATA_DIR` |
| --- | --- | --- |
| AppImage | `lib` | `data` |
| DEB | `lib/<executable>` | `share/<executable>` |

Note that the DEB payload uses `/usr/share` (architecture-independent data, per
the FHS) while the AppImage AppDir mirrors the Flutter bundle layout.
