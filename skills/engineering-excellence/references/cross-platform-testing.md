# Cross-Platform Testing

A change is verified on the platforms it claims, in those platforms' own runtimes. Reading a
script and reasoning about portability is not verification.

## What the host can run

| Host | Linux containers | Windows containers | macOS |
|---|---|---|---|
| Linux | yes, native | no: a Windows container needs a Windows host with a compatible kernel | no: a real Mac or a macOS CI runner |
| Windows with Docker Desktop | yes, through the Linux VM | yes, with Docker switched to Windows containers and an image matching the host build | no |
| macOS | yes, through the Linux VM | no | the host itself |

State which cell was used and which could not run. "Not runnable from this host" is an honest
result; "should work" is not a result.

## Linux row set

One image per family the project claims, tags pinned:

| Family | Example | Package manager | Watches for |
|---|---|---|---|
| Debian / Ubuntu | `debian:13`, `ubuntu:24.04` | apt | plain POSIX shell, GNU coreutils |
| Fedora / RHEL / Rocky | `fedora:latest`, `rockylinux:9` | dnf | SELinux, newer glibc, `curl` missing from minimal images |
| Arch and derivatives (CachyOS, Manjaro) | `archlinux:latest` | pacman | rolling packages, no `python` by default |
| openSUSE | `opensuse/tumbleweed` | zypper | different package names and version suffixes |
| Alpine | `alpine:latest` | apk | musl, busybox, no `bash` by default |

Derivatives count: distributions outside the supported list often resolve through `ID_LIKE`
(CachyOS reports `ID_LIKE=arch`), so test the mapping and not only the names.

## Recipe

```sh
docker run --rm -v "$PWD:/w:ro" -w /w <image> sh -ceu '
  <install dependencies with that distribution package manager>
  <run the exact test or entrypoint command>
'
```

- `--rm` always, and leave no container, layer or state behind.
- Mount read-only, or a scratch path when the test writes; never the repository itself.
- `sh -ceu` inside, so a failing step fails the row instead of being masked.
- Containers ship no `sudo`, no `systemd`, and often no `curl`, `git` or `node`: install what the
  test needs explicitly. A missing tool is a finding about the project's assumptions.
- Pull rows in parallel, but mind the machine's memory: many containers plus a build is how a
  16 GB host starts swapping.

## Multi-platform toolchains

- Node projects: `npm ci && npm test` and `npm pack` (packaging failures appear only there) in
  each container, plus `bun install && bun test` where bun is a supported runtime.
- Exercise the project's own entrypoints, not only the test suite: a CLI, a script, an installer.
- Windows hazards worth a row: spawning a `.cmd`/`.bat` shim without a shell (`ENOENT` even when
  the command resolves in a shell), `PATH` shim resolution, drive letters, CRLF, case-insensitive
  paths, locked files on `rename` (`EPERM`/`EBUSY`), reserved names.
- Shell hazards: `sh` versus `pwsh`, shebangs, quoting, `mktemp`/`$TMPDIR`, locale and UTF-8.
- When a project ships parallel implementations per platform (`.sh` and `.ps1`, or a Node
  launcher), every row must exercise each implementation: parity is a test, not a comment.

## Evidence

Per row record host, image tag, exact command, exit code and the output that proves the
assertion. Then record what could not run and why. A test against a fake dependency is not a
test against the real one; say which was used, because the fake can hide the very failure the
row exists to find.

## Cost

Containers are cheap per run and expensive in aggregate. Run the rows the change can affect,
keep the full matrix for release candidates, and reuse one base image across rows so the second
pull is free.
