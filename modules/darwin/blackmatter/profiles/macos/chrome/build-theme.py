#!/usr/bin/env python3
"""Generate a Chrome theme CRX2 extension from a base16 YAML color scheme."""

import argparse
import hashlib
import json
import os
import struct
import subprocess
import tempfile
import zipfile

import yaml


# base16 slot -> Chrome theme color property
COLOR_MAP = {
    "frame":                        "base00",
    "frame_inactive":               "base01",
    "frame_incognito":              "base01",
    "frame_incognito_inactive":     "base01",
    "toolbar":                      "base01",
    "tab_text":                     "base05",
    "tab_background_text":          "base04",
    "tab_background_text_inactive": "base03",
    "bookmark_text":                "base05",
    "toolbar_button_icon":          "base04",
    "omnibox_text":                 "base05",
    "omnibox_background":           "base00",
    "ntp_background":               "base00",
    "ntp_text":                     "base05",
    "ntp_link":                     "base0D",
    "ntp_header":                   "base02",
}


def hex_to_rgb(h: str) -> list[int]:
    """Convert a hex color string (with or without #) to [R, G, B]."""
    h = h.lstrip("#")
    return [int(h[i:i+2], 16) for i in (0, 2, 4)]


def load_scheme(path: str) -> dict[str, str]:
    """Load a base16 YAML scheme and return the palette dict."""
    with open(path) as f:
        data = yaml.safe_load(f)
    # Support both flat format (base00: "xxx") and nested (palette: {base00: "xxx"})
    if "palette" in data:
        return data["palette"]
    return {k: v for k, v in data.items() if k.startswith("base0")}


def build_manifest(scheme: dict[str, str], scheme_name: str) -> dict:
    """Build a Chrome theme manifest.json from base16 colors."""
    colors = {}
    for chrome_prop, base_slot in COLOR_MAP.items():
        colors[chrome_prop] = hex_to_rgb(scheme[base_slot])

    return {
        "manifest_version": 3,
        "version": "1.0",
        "name": f"Base16 {scheme_name}",
        "description": f"Auto-generated Chrome theme from base16 {scheme_name} scheme",
        "theme": {
            "colors": colors,
        },
    }


def make_zip(manifest: dict, workdir: str) -> str:
    """Create a zip file containing manifest.json, return path."""
    zip_path = os.path.join(workdir, "theme.zip")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("manifest.json", json.dumps(manifest, indent=2))
    return zip_path


def pem_to_der(pem_path: str, workdir: str) -> str:
    """Convert PEM private key to DER public key, return DER path."""
    der_path = os.path.join(workdir, "key.der")
    subprocess.run(
        ["openssl", "rsa", "-pubout", "-outform", "DER",
         "-in", pem_path, "-out", der_path],
        check=True, capture_output=True,
    )
    return der_path


def sign_zip(pem_path: str, zip_path: str, workdir: str) -> str:
    """Sign the zip with the PEM key, return signature path."""
    sig_path = os.path.join(workdir, "theme.sig")
    subprocess.run(
        ["openssl", "dgst", "-sha1", "-sign", pem_path,
         "-out", sig_path, zip_path],
        check=True, capture_output=True,
    )
    return sig_path


def build_crx(der_path: str, sig_path: str, zip_path: str, out_path: str):
    """Pack a CRX2 file: magic + version + pubkey_len + sig_len + pubkey + sig + zip."""
    with open(der_path, "rb") as f:
        pubkey = f.read()
    with open(sig_path, "rb") as f:
        sig = f.read()
    with open(zip_path, "rb") as f:
        zipdata = f.read()

    with open(out_path, "wb") as f:
        f.write(b"Cr24")                              # magic
        f.write(struct.pack("<I", 2))                  # version
        f.write(struct.pack("<I", len(pubkey)))        # pubkey length
        f.write(struct.pack("<I", len(sig)))           # signature length
        f.write(pubkey)
        f.write(sig)
        f.write(zipdata)


def compute_extension_id(der_path: str) -> str:
    """Compute Chrome extension ID: SHA256 of DER pubkey, first 32 hex chars, a-p encoded."""
    with open(der_path, "rb") as f:
        pubkey = f.read()
    digest = hashlib.sha256(pubkey).hexdigest()[:32]
    return "".join(chr(ord("a") + int(c, 16)) for c in digest)


def write_updates_xml(ext_id: str, crx_path: str, outdir: str):
    """Write updates.xml for Chrome's ExtensionInstallForcelist file:// protocol."""
    xml = f"""<?xml version='1.0' encoding='UTF-8'?>
<gupdate xmlns='http://www.google.com/update2/response' protocol='2.0'>
  <app appid='{ext_id}'>
    <updatecheck codebase='file://{crx_path}' version='1.0' />
  </app>
</gupdate>
"""
    with open(os.path.join(outdir, "updates.xml"), "w") as f:
        f.write(xml)


def main():
    parser = argparse.ArgumentParser(description="Build Chrome theme CRX from base16 scheme")
    parser.add_argument("--scheme", required=True, help="Path to base16 YAML scheme file")
    parser.add_argument("--key", required=True, help="Path to PEM private key")
    parser.add_argument("--outdir", required=True, help="Output directory")
    args = parser.parse_args()

    scheme = load_scheme(args.scheme)

    # Extract scheme name from YAML or filename
    with open(args.scheme) as f:
        raw = yaml.safe_load(f)
    scheme_name = raw.get("scheme", raw.get("name", os.path.splitext(os.path.basename(args.scheme))[0]))

    manifest = build_manifest(scheme, scheme_name)

    os.makedirs(args.outdir, exist_ok=True)

    with tempfile.TemporaryDirectory() as workdir:
        zip_path = make_zip(manifest, workdir)
        der_path = pem_to_der(args.key, workdir)
        sig_path = sign_zip(args.key, zip_path, workdir)

        crx_out = os.path.join(args.outdir, "theme.crx")
        build_crx(der_path, sig_path, zip_path, crx_out)

        ext_id = compute_extension_id(der_path)
        with open(os.path.join(args.outdir, "extension-id"), "w") as f:
            f.write(ext_id)

        write_updates_xml(ext_id, crx_out, args.outdir)

    print(f"Extension ID: {ext_id}")
    print(f"CRX: {crx_out}")


if __name__ == "__main__":
    main()
