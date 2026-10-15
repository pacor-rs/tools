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

## Tags are the contract

A pacor release embeds the tag it was written against and fetches templates from
that tag only:

```
https://raw.githubusercontent.com/pacor-rs/tools/refs/tags/<tag>/linux/<format>/<file>
```

`main` is therefore free to change at any time: an existing pacor build keeps
using the tag it pinned, so templates and the code that renders them always move
together. Nothing reaches a pacor version that does not understand it.

### When to tag

Create a new tag whenever the contract changes:

* a variable is added, removed or renamed;
* an existing variable is given a different meaning;
* a template starts requiring a variable that older pacor builds do not provide.

A template-only fix that keeps the same variables and the same meaning — a wrong
path, a typo — also needs a new tag, because the old tag's contents are what
existing builds keep downloading. Tags are never moved or deleted.

Then bump `TEMPLATE_REF` in `pacor-packaging-linux` to the new tag. The tag is
part of pacor's download cache path, so that bump is all it takes to invalidate
stale copies.

### Released tags

| Tag | Contract |
| --- | --- |
| `v1` | `APP_EXECUTABLE_NAME`, `APP_LIB_DIR`, `APP_DATA_DIR`, `APP_APPLICATION_ID` |
