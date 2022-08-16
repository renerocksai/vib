# vib - view in browser

A minimalistic tool for [the aerc e-mail client](https://aerc-mail.org) that
displays messages piped from aerc in your favourite browser.

After contemplating writing a shell script for this purpose, I figured it would
only take a little longer to write it in zig, allowing me to share
shell-agnostic statically linked binaries. Just in case you're wondering 😊.

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

In your aerc's **binds.conf**, place your preferred shortcut in the `[view]`
section like this:

```console
[view]

# ... existing stuff ...

# on B, pipe the message part to vib
B = :pipe -b -p vib -e sensible-browser -c<Enter>
```

If `vib` is not in your path, you may optionally specify the full path to
vib like so:

```console
B = :pipe -b -p /home/rs/vib -e sensible-browser -c<Enter>
```

When you open a message now, **and select its HTML part**, you can view it in
the browser by pressing <kbd>B</kbd>.

Vib reads the message (part) piped to it from aerc, dumps it into a temporary
file, and launches a browser.

```
Options are:
  -e, --exec     : optional name of the executable (browser) to launch
  -p, --prefix   : optional prefix for temp file names. Default: vib-
  -t, --tmpdir   : temp dir to write to. Default: /tmp
  -o, --output   : optional path to write to instead of temp file
  -c, --cleanup  : delete all of vib's temp files before creating a new one

Examples:
vib -e sensible-browser
  Launch the sensible-browser, use defaults for all options.

vib -e firefox -c -t /tmp/vib-messages
  Delete vib's temp files from previous runs, then create a new one
  and launch firefox with the piped-in message.

vib -o /tmp/current-message.html
  Launch no browser, just write to /tmp/current-message.html
  This allows you to leave the browser open on the same page,
  while using vib to refresh the content.
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
