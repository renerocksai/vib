
# vib - view in browser

A minimalistic tool for [the aerc e-mail client](https://aerc-mail.org) that
displays messages piped from aerc in your favourite browser.

# Contributing

There's a [mailing list](https://lists.sr.ht/~renerocksai/vib) to send
patches to, discuss, etc. If you're used to GitHub's pull-request workflow,
[check out this page](https://man.sr.ht/~renerocksai/migrate-to-sourcehut/PR.md)
to see how to send me pull-requests or maybe even better-suited alternatives
(patch-sets).

# Getting it

You can download vib from its [refs
page](https://git.sr.ht/~renerocksai/vib/refs). Pick the latest version,
e.g. `v0.1.0`, then download the executable for your operating system.

Binary downloads are named with the following postfixes:

- `--aarch64-macos.gz` : for macOS ARM (e.g. M1)
- `--aarch64-x86_64-linux.gz` : for Linux
- `--aarch64-x86_64-macos.gz` : for Intel Macs
- `--aarch64-x86_64-windows.exe.zip` : for Windows

After downloading, extract the `.gz` files like this:

```console
gunzip vib-v0.1.0--x86_64-linux.gz
```

**Note:** You might want to rename the executable to `vib` (without the
version and platform information), or create an `vib` symlink for it.

On Windows, right-click on the `.zip` file and choose "Extract all..." from the
context menu. After that, you may want to right-click and rename the extracted
file to `vib.exe`.

# Usage

After [downloading](#getting-it) or [building it](#building-it), and making sure
the `vib` command is in your PATH, configure aerc to use vib:

In your aerc's **binds.conf**, ...

TO BE WRITTEN

```console
```

If `vib` is not in your path, you may optionally specify the full path to
vib like so:

```console
```

Vib reads the message (part) piped to it from aerc, dumps it into a temporary
file, and launches a browser.

```
Options are:
  -e, --exec     : name of the executable (browser) to launch.
  -s, --max-size : max size of memory for input. Default: 10MB
  -p, --prefix   : optional prefix for temp file names. Default: vib-
  -t, --tmpdir   : temp dir to write to. Default: /tmp
  -o, --output   : optional path to write to instead of temp file

Examples:
vib -e sensible-browser

vib -e sensible-browser -t /tmp/vib-messages

vib -o /tmp/current-message.html
  Launch no browser, just write to /tmp/current-message.html
  This allows you to leave the browser open on the same page,
  while using vib
```

# Building it

Make sure you have [zig 0.9.1](https://ziglang.org/download/) installed. Then
run:

```console
zig build
```

This will produce `vib` in the `./zig-out/bin/` directory. From there,
**copy it to a directory in your PATH**, e.g. in my case: `~/bin`.

# Tested with

- zig 0.9.1
- aerc 0.11.0
- on Linux: NixOS 22.05 ([patched for aerc 0.11.0 instead of
  0.10.0](https://sr.ht/~renerocksai/nixpkgs/))
