# Sparkle Provenance

- Version: 2.9.5
- Upstream: https://github.com/sparkle-project/Sparkle/releases/tag/2.9.5
- Release archive: `Sparkle-2.9.5.tar.xz`
- Archive SHA-256: `015336b601493e05c237964954bff6191370003d94edefe663724c88840d73cc`
- Retrieved: 2026-08-08

`Sparkle.framework`, the command-line tools, `LICENSE`, and `INSTALL` come from
that official archive. The universal framework remains inside the repository's
existing `Sparkle.xcframework` wrapper so both SwiftPM and the Xcode project use
the same pinned binary.

To update Sparkle, download the next official release archive, verify and record
its SHA-256 before extraction, replace only the vendored Sparkle files, and run
the focused build and signature checks. Never generate or rotate Battery Panic's
private update key as part of a framework update.
