"""Build a BepInEx server tree from an r2modman/Thunderstore profile code.

Runs inside a fixed-output derivation. A profile pins exact package versions
and Thunderstore versions are immutable, so the output only depends on the
code and the exclude list.

usage: valheim-modpack.py <code> <out> [excluded Author-Package ...]
"""

import base64
import io
import pathlib
import re
import subprocess
import sys
import zipfile

import yaml

BASE = "https://thunderstore.io"
BEPINEX = "denikson-BepInExPack_Valheim"
# r2modman routes these folders wherever they appear in a package; anything
# else lands in plugins/<package>
PER_PACKAGE = {"plugins", "patchers", "monomod"}


def download(url):
    # curl rather than urllib: python's ssl fails on thunderstore's chain in the sandbox
    return subprocess.run(
        ["curl", "-fsSL", "--retry", "5", "--retry-all-errors", "-A", "nix-valheim-modpack", url],
        check=True,
        stdout=subprocess.PIPE,
    ).stdout


def entries(archive):
    """Yield (path parts, zip entry) for every file, with windows separators fixed."""
    for entry in archive.infolist():
        name = entry.filename.replace("\\", "/")
        if entry.is_dir() or name.endswith("/"):
            continue
        parts = tuple(p for p in name.split("/") if p not in ("", "."))
        if ".." in parts or not parts:
            raise ValueError(f"unsafe zip path: {entry.filename}")
        yield parts, entry


def write(archive, entry, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(archive.read(entry))


def route(package, parts):
    """Where a package file goes relative to BepInEx/, following r2modman's rules."""
    for i, part in enumerate(parts[:-1]):
        folder = part.lower()
        if folder in PER_PACKAGE:
            return (folder, package, *parts[i + 1 :])
        if folder == "config":
            return ("config", *parts[i + 1 :])
    return ("plugins", package, *parts)


def main(code, out, *exclude):
    out = pathlib.Path(out)
    exclude = set(exclude)

    raw = download(f"{BASE}/api/experimental/legacyprofile/get/{code}/").splitlines()
    if len(raw) < 2 or raw[0].strip() != b"#r2modman":
        raise ValueError(f"{code} is not an r2modman profile code")
    profile = zipfile.ZipFile(io.BytesIO(base64.b64decode(raw[-1])))
    manifest = yaml.safe_load(profile.read("export.r2x"))
    print(f"profile: {manifest.get('profileName')}", flush=True)

    mods = [m for m in manifest["mods"] if m.get("enabled", True)]
    names = {m["name"] for m in mods}
    if BEPINEX not in names:
        raise ValueError(f"profile does not contain {BEPINEX}")
    if unknown := exclude - names:
        raise ValueError(f"excluded mods not in profile: {', '.join(sorted(unknown))}")

    installed = []
    for mod in mods:
        package = mod["name"]
        if package in exclude:
            print(f"skip {package}", flush=True)
            continue
        if not re.fullmatch(r"[\w]+-[\w]+", package):
            raise ValueError(f"bad package name: {package}")
        author, name = package.split("-", 1)
        v = mod["version"]
        version = f"{v['major']}.{v['minor']}.{v['patch']}"
        print(f"install {package} {version}", flush=True)
        installed.append(f"{package} {version}")

        archive = zipfile.ZipFile(io.BytesIO(download(f"{BASE}/package/download/{author}/{name}/{version}/")))
        for parts, entry in entries(archive):
            if package == BEPINEX:
                # the pack wraps the game-root layout in a folder of the same name
                if parts[0] == "BepInExPack_Valheim" and len(parts) > 1:
                    write(archive, entry, out.joinpath(*parts[1:]))
            else:
                write(archive, entry, out.joinpath("BepInEx", *route(package, parts)))

    # the profile carries config/ plus files r2modman found next to plugins
    for parts, entry in entries(profile):
        if parts[0] == "config" and len(parts) > 1:
            write(profile, entry, out.joinpath("BepInEx", *parts))
        elif parts[0] == "BepInEx" and len(parts) > 1:
            write(profile, entry, out.joinpath(*parts))

    (out / "mods.txt").write_text("".join(f"{line}\n" for line in installed))


if __name__ == "__main__":
    main(*sys.argv[1:])
