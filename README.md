# tools

Build templates for [pacor](https://github.com/pacor-rs/pacor). A pacor release
fetches the files it needs from one pinned tag of this repository:

```
windows/nsis/**     NSIS installer script, plugins and per-language strings
windows/wix/**      WiX templates for the MSI installer (tag 1.1 and later)
linux/**            AppImage and DEB templates, plus the fallback icon set
```

## Template placeholders

Templates are rendered by the packaging tool before use. Every placeholder must
be replaced: a template that uses a variable pacor does not provide fails the
build instead of baking the placeholder into the generated source.

### Linux

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

### Windows (MSI)

`windows/wix/main.wxs` is rendered **once per locale**, because
`Product/@Language` carries the locale's LCID and an attribute cannot be
localized through a `.wxl` file.

| Placeholder | Meaning |
| --- | --- |
| `{{APP_NAME}}` | Project name from `pubspec.yaml`: the install directory and registry key. |
| `{{PRODUCT_VERSION}}` | Four-part numeric version, e.g. `1.0.0+1` becomes `1.0.0.1`. |
| `{{PRODUCT_LANGUAGE}}` | The locale's LCID (`1033`, `2052`, …). |
| `{{APP_EXECUTABLE}}` | Runner executable name; the shortcut target. |
| `{{APP_URL}}` | `[app].url`, used for `ARPURLINFOABOUT`. |
| `{{APP_ICON_PATH}}` | `windows/runner/resources/app_icon.ico`, used for `ARPPRODUCTICON`. |
| `{{UPGRADE_CODE}}` | Configured MSI upgrade code, or one derived from the application name and publisher. |
| `{{INSTALL_DIR_COMPONENT_GUID}}` `{{START_MENU_COMPONENT_GUID}}` `{{DESKTOP_COMPONENT_GUID}}` | Component GUIDs for the components the template itself declares. |
| `{{PAYLOAD_COMPONENT_GROUP}}` | Id of the component group that the generated `payload.wxs` fills (`AppPayload`). |

`windows/wix/culture.wxl.tmpl` is rendered once per locale and is the single
localization file `light -loc` receives; its `Culture` must match the
`-cultures:` value and the rendered file name.

| Placeholder | Meaning |
| --- | --- |
| `{{CULTURE}}` | WiX/.NET culture name: `en-us`, `zh-cn`, `zh-tw`, `en-gb`, `ja-jp`. |
| `{{MSI_CODEPAGE}}` | Code page of the package's string pool, e.g. `936`, or `65001` for UTF-8. |
| `{{APP_DISPLAY_NAME}}` `{{APP_PUBLISHER}}` `{{APP_DESCRIPTION}}` `{{APP_COPYRIGHT}}` | Localized metadata from `[app.i18n]`, falling back to the default locale. |
| `{{FEATURE_MAIN}}` `{{UNINSTALL_SHORTCUT}}` `{{DOWNGRADE_ERROR}}` | Wording owned by pacor. |

Things a WiX template has to respect, each of which cost a build failure once:

* the localization file must define every identifier `main.wxs` refers to with
  `!(loc.…)`, and `light` accepts only one localization per run — so a
  multi-locale project gets one MSI per locale, not one package;
* Windows Installer stores every string in one code page per package. Text the
  code page cannot represent fails with `LGHT0311` (`©` is not in code page 936,
  for example), which is why `{{MSI_CODEPAGE}}` belongs on the
  `WixLocalization` element rather than on `Product`;
* shortcut components are treated as user-profile components by ICE even in a
  per-machine package, so their keypaths must be `HKCU` registry values
  (`ICE38`, `ICE43`);
* `WixUI_InstallDir` already authors properties such as `ARPNOMODIFY`; writing
  them in the template duplicates the row and fails with `LGHT0091`;
* payload paths never appear in a template: pacor passes the build output
  through `candle -dSourceDir=<directory>` and the generated `payload.wxs`
  refers to `$(var.SourceDir)\…`, so component GUIDs do not depend on where the
  project was checked out;
* `-arch x64` and `Package/@Platform="x64"` belong together, otherwise the
  package registers in the 32-bit registry view and 64-bit directories trip
  `ICE80`.

## Tags are the contract

A pacor release embeds the tag it was written against and fetches templates from
that tag only:

```
https://raw.githubusercontent.com/pacor-rs/tools/refs/tags/<tag>/linux/<format>/<file>
```

`main` is therefore free to change at any time: an existing pacor build keeps
using the tag it pinned, so templates and the code that renders them always move
together. Nothing reaches a pacor version that does not understand it.

Tags are GNU-style version numbers (`MAJOR.MINOR`, optionally with a patch
level) without the `v` prefix: a backward-compatible addition — a new backend's
templates, say — is a minor bump, and an incompatible change is a major bump.
`v1` predates the convention and holds the tree that `1.0` would name.

### When to tag

Create a new tag whenever the contract changes:

* a variable is added, removed or renamed;
* an existing variable is given a different meaning;
* a template starts requiring a variable that older pacor builds do not provide.

A template-only fix that keeps the same variables and the same meaning — a wrong
path, a typo — also needs a new tag, because the old tag's contents are what
existing builds keep downloading. Tags are never moved or deleted.

Then bump `TEMPLATE_REF` in `crates/pacor-core/src/tools.rs`. The tag is part of
pacor's download cache path, so that bump is all it takes to invalidate stale
copies.

### Released tags

| Tag | Contract |
| --- | --- |
| `v1` | `APP_EXECUTABLE_NAME`, `APP_LIB_DIR`, `APP_DATA_DIR`, `APP_APPLICATION_ID`; `windows/nsis/**`. |
| `1.1` | `v1` plus the WiX placeholders listed above; `windows/nsis/**` is unchanged. |
