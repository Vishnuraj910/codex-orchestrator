#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import subprocess
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLUGIN = ROOT / "plugins" / "orchestrator-pattern"
SKILL = PLUGIN / "skills" / "orchestrator-pattern"


def fail(message: str) -> None:
    raise AssertionError(message)


def load_json(path: Path) -> object:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def main() -> int:
    required = [
        ROOT / "README.md",
        ROOT / "LICENSE",
        ROOT / ".agents" / "plugins" / "marketplace.json",
        PLUGIN / ".codex-plugin" / "plugin.json",
        PLUGIN / "hooks" / "hooks.json",
        SKILL / "SKILL.md",
        SKILL / "agents" / "openai.yaml",
        PLUGIN / "scripts" / "install-user-config.sh",
        PLUGIN / "scripts" / "codex-agent",
    ]
    missing = [str(path.relative_to(ROOT)) for path in required if not path.is_file()]
    if missing:
        fail(f"missing required files: {missing}")

    plugin = load_json(PLUGIN / ".codex-plugin" / "plugin.json")
    if not isinstance(plugin, dict) or plugin.get("name") != "orchestrator-pattern":
        fail("plugin name must be orchestrator-pattern")
    if not re.fullmatch(r"\d+\.\d+\.\d+", str(plugin.get("version", ""))):
        fail("plugin version must be strict semver")

    marketplace = load_json(ROOT / ".agents" / "plugins" / "marketplace.json")
    if not isinstance(marketplace, dict) or marketplace.get("name") != "codex-orchestrator":
        fail("marketplace name must be codex-orchestrator")
    entries = marketplace.get("plugins")
    if not isinstance(entries, list) or len(entries) != 1:
        fail("marketplace must expose exactly one plugin")
    if entries[0].get("source", {}).get("path") != "./plugins/orchestrator-pattern":
        fail("marketplace source path is incorrect")

    skill_text = (SKILL / "SKILL.md").read_text(encoding="utf-8")
    frontmatter = re.match(r"^---\nname: ([^\n]+)\ndescription: ([^\n]+)\n---\n", skill_text)
    if not frontmatter or frontmatter.group(1) != "orchestrator-pattern":
        fail("skill frontmatter is invalid")

    text_files = [path for path in ROOT.rglob("*") if path.is_file() and ".git" not in path.parts]
    for path in text_files:
        if path.suffix.lower() in {".png", ".jpg", ".jpeg", ".gif"}:
            continue
        text = path.read_text(encoding="utf-8")
        if "[TODO" + ":" in text:
            fail(f"placeholder remains in {path.relative_to(ROOT)}")
        if "/Users" + "/" in text or "vishnu" + "rajrajagopal" in text:
            fail(f"machine-specific path remains in {path.relative_to(ROOT)}")

    for template in (PLUGIN / "assets" / "user-config").rglob("*.toml.tmpl"):
        with template.open("rb") as handle:
            tomllib.load(handle)

    shell_scripts = [ROOT / "install.sh", *(PLUGIN / "scripts").glob("*.sh"), PLUGIN / "scripts" / "codex-agent"]
    for script in shell_scripts:
        result = subprocess.run(["bash", "-n", str(script)], capture_output=True, text=True)
        if result.returncode:
            fail(f"shell syntax failed for {script.relative_to(ROOT)}: {result.stderr.strip()}")

    hook = PLUGIN / "scripts" / "delegation-guard.sh"
    benign = subprocess.run(["sh", str(hook)], input='{"tool_name":"Bash","tool_input":{"command":"pwd"}}', capture_output=True, text=True)
    if benign.returncode or benign.stdout:
        fail("benign hook probe should produce no output")
    heavy = subprocess.run(["sh", str(hook)], input='{"tool_name":"Bash","tool_input":{"command":"pnpm test"}}', capture_output=True, text=True)
    if heavy.returncode or "verifier" not in heavy.stdout:
        fail("verification hook probe did not emit the expected advisory")

    print("PASS: repository structure, manifests, skill, templates, scripts, and hook probes")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, json.JSONDecodeError, tomllib.TOMLDecodeError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
