#!/usr/bin/env python3
"""Export and verify a signed Mac App Store package using local signing assets."""
import datetime
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
TEAM = "9A2S27Y6C4"
BUNDLE = "com.breakfastclub.panicatthepantry"


def run(*args):
    return subprocess.run([str(a) for a in args], check=True, capture_output=True).stdout


def main():
    required = ("PANTRY_APP_IDENTITY", "PANTRY_INSTALLER_IDENTITY", "PANTRY_PROFILE")
    missing = [name for name in required if not os.environ.get(name)]
    if missing:
        raise SystemExit("Set local signing configuration: " + ", ".join(missing))
    profile = Path(os.environ["PANTRY_PROFILE"]).expanduser().resolve()
    if not profile.is_file():
        raise SystemExit("The specified distribution provisioning profile does not exist.")
    data = plistlib.loads(run("/usr/bin/security", "cms", "-D", "-i", profile))
    permissions = data.get("Entitlements", {})
    app_id = permissions.get("com.apple.application-identifier", permissions.get("application-identifier"))
    if TEAM not in data.get("TeamIdentifier", []) or app_id != TEAM + "." + BUNDLE:
        raise SystemExit("The provisioning profile belongs to a different team or app.")
    if data.get("ProvisionedDevices") or permissions.get("get-task-allow") or permissions.get("com.apple.security.get-task-allow"):
        raise SystemExit("Use an App Store distribution profile, not a development/ad hoc profile.")
    if data["ExpirationDate"] <= datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None):
        raise SystemExit("The provisioning profile has expired.")
    output = ROOT / "build/app-store"
    output.mkdir(parents=True, exist_ok=True)
    package = output / "Panic at the Pantry.pkg"
    if package.exists():
        raise SystemExit("A package already exists at " + str(package) + "; move it aside before rebuilding.")
    with tempfile.TemporaryDirectory(prefix="export-", dir=output) as temp:
        temp = Path(temp)
        project = temp / "game"
        shutil.copytree(ROOT / "game", project, ignore=shutil.ignore_patterns(".godot", ".DS_Store"))
        preset = project / "export_presets.cfg"
        before, options = preset.read_text().split("[preset.1.options]", 1)
        replacements = {
            "codesign/identity": os.environ["PANTRY_APP_IDENTITY"],
            "codesign/installer_identity": os.environ["PANTRY_INSTALLER_IDENTITY"],
            "codesign/provisioning_profile": str(profile),
            "application/version": os.environ.get("PANTRY_BUILD_NUMBER", "2"),
        }
        for key, value in replacements.items():
            pattern = re.compile(r"^" + re.escape(key) + r"=.*$", re.MULTILINE)
            options, count = pattern.subn(lambda _: key + "=" + json.dumps(value), options)
            if count != 1:
                raise SystemExit("Expected one export setting for " + key)
        preset.write_text(before + "[preset.1.options]" + options)
        print("Exporting the signed App Store package...", flush=True)
        engine = ROOT / ".tools/Godot.app/Contents/MacOS/Godot"
        subprocess.run([str(engine), "--headless", "--path", str(project), "--export-release", "Mac App Store", str(package)], check=True)
        run("/usr/sbin/pkgutil", "--check-signature", package)
        expanded = temp / "expanded"
        run("/usr/sbin/pkgutil", "--expand-full", package, expanded)
        apps = list(expanded.rglob("*.app"))
        if len(apps) != 1:
            raise SystemExit("Expected one application in the exported package.")
        app = apps[0]
        info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
        if info.get("LSMinimumSystemVersion") != "13.0":
            raise SystemExit("The app must declare the App Store required LSMinimumSystemVersion (13.0).")
        run("/usr/bin/codesign", "--verify", "--deep", "--strict", app)
        entitlements = plistlib.loads(run("/usr/bin/codesign", "-d", "--entitlements", ":-", app))
        expected = {
            "com.apple.security.app-sandbox": True,
            "com.apple.developer.team-identifier": TEAM,
            "com.apple.application-identifier": TEAM + "." + BUNDLE,
        }
        for key, value in expected.items():
            if entitlements.get(key) != value:
                raise SystemExit("Unexpected signed entitlement: " + key)
        for key in ("com.apple.security.get-task-allow", "com.apple.security.network.client", "com.apple.security.network.server", "com.apple.security.cs.disable-library-validation"):
            if entitlements.get(key):
                raise SystemExit("Unexpected release entitlement: " + key)
        if not (app / "Contents/embedded.provisionprofile").is_file():
            raise SystemExit("The signed app is missing its provisioning profile.")
        if (app / "Contents/embedded.provisionprofile").read_bytes() != profile.read_bytes():
            raise SystemExit("The embedded provisioning profile does not match the selected profile.")
    print("Verified package: " + str(package))


if __name__ == "__main__":
    main()
