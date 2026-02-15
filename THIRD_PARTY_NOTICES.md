# Third-Party Notices

This repository includes third-party software with licenses different from this repository's MIT license.

## Mongoose (Cesanta)

- Upstream source (submodule): `third_party/mongoose/` (pinned to tag 7.20)
- Local adapter layer: `Sources/Mongoose/` (config, shims, modulemap)
- Upstream project: https://github.com/cesanta/mongoose
- Copyright: Sergey Lyubka, Cesanta Software Limited
- Declared in source header: dual-licensed under **GPL-2.0-only OR commercial**
- SPDX identifier in source: `GPL-2.0-only OR commercial`

### What this means for distribution

If you distribute binaries/firmware that include Mongoose, choose one licensing path:

1. **GPL-2.0-only path**
   - Comply with GPLv2 requirements for distribution.
   - Include GPLv2 license text in your distribution (see `COPYING.GPL-2.0` in this repository).
   - Preserve copyright/license notices.
   - Provide complete corresponding source code (including modifications and build scripts) as required by GPLv2.

2. **Commercial path**
   - Obtain a commercial license from Cesanta.
   - Distribute according to your commercial license terms.

Commercial licensing information: https://www.mongoose.ws/licensing/

---

This file is informational and not legal advice.
