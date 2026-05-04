#!/usr/bin/env python3
"""Deterministic repository structure verifier for claude-toymarket."""

import argparse
import json
import re
import stat
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATH = REPO_ROOT / "catalog" / "toymarket.json"
KEBAB_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
SEMVER_RE = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+(?:[-+][0-9A-Za-z.-]+)?$")


class Reporter:
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.ok = []

    def add_ok(self, code, message):
        self.ok.append(("OK", code, message))

    def error(self, code, message):
        self.errors.append(("ERR", code, message))

    def warn(self, code, message):
        self.warnings.append(("WARN", code, message))

    def print(self, quiet=False):
        rows = []
        if not quiet:
            rows.extend(self.ok)
            rows.extend(self.warnings)
        else:
            rows.extend(self.warnings)
        rows.extend(self.errors)
        for level, code, message in sorted(rows, key=lambda item: (item[0], item[1], item[2])):
            print(f"{level} {code} {message}")
        print(f"SUMMARY errors={len(self.errors)} warnings={len(self.warnings)} ok={len(self.ok)}")


def rel(path):
    return str(path.relative_to(REPO_ROOT))


def load_json(path, reporter, code):
    if not path.exists():
        reporter.error(code, f"missing file: {rel(path)}")
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        reporter.error(code, f"invalid json: {rel(path)}:{exc.lineno}:{exc.colno}: {exc.msg}")
        return None


def canonical_json(data):
    return json.dumps(data, ensure_ascii=False, indent=2) + "\n"


def read_text(path):
    return path.read_text(encoding="utf-8")


def write_if_changed(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and read_text(path) == text:
        return False
    path.write_text(text, encoding="utf-8")
    return True


def plugin_dir(name):
    return REPO_ROOT / "plugins" / name


def has_skills(name):
    skills_dir = plugin_dir(name) / "skills"
    return skills_dir.exists() and any(skills_dir.glob("*/SKILL.md"))


def hook_config_path(name):
    candidate = plugin_dir(name) / "hooks" / "hooks.json"
    return candidate if candidate.exists() else None


def expected_claude_marketplace(source):
    plugins = []
    for plugin in source["plugins"]:
        claude = plugin.get("claude", {})
        plugins.append(
            {
                "name": plugin["name"],
                "description": claude.get("marketplaceDescription", plugin["description"]),
                "source": f"./plugins/{plugin['name']}",
                "category": claude["category"],
            }
        )
    return {
        "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
        "name": source["name"],
        "description": source["description"],
        "owner": source["owner"],
        "plugins": plugins,
    }


def expected_claude_plugin(plugin):
    return {
        "name": plugin["name"],
        "description": plugin["description"],
        "version": plugin["version"],
        "author": plugin["author"],
    }


def expected_codex_marketplace(source):
    return {
        "name": source["name"],
        "interface": {
            "displayName": source["codex"]["displayName"],
        },
        "plugins": [
            {
                "name": plugin["name"],
                "source": {
                    "source": "local",
                    "path": f"./plugins/{plugin['name']}",
                },
                "policy": {
                    "installation": "NOT_AVAILABLE"
                    if plugin["codex"].get("status") == "claude-only"
                    else "AVAILABLE",
                    "authentication": "ON_INSTALL",
                },
                "category": plugin["codex"]["category"],
            }
            for plugin in source["plugins"]
        ],
    }


def expected_codex_plugin(plugin):
    name = plugin["name"]
    manifest = {
        "name": name,
        "version": plugin["version"],
        "description": plugin["description"],
        "author": plugin["author"],
    }
    if plugin["codex"].get("status") != "claude-only":
        if has_skills(name):
            manifest["skills"] = "./skills/"
        hooks = hook_config_path(name)
        if hooks is not None:
            manifest["hooks"] = f"./{hooks.relative_to(plugin_dir(name))}"
        mcp_path = plugin_dir(name) / ".mcp.json"
        if mcp_path.exists():
            manifest["mcpServers"] = "./.mcp.json"
        app_path = plugin_dir(name) / ".app.json"
        if app_path.exists():
            manifest["apps"] = "./.app.json"
    manifest["interface"] = plugin["codex"]["interface"]
    return manifest


def has_codex_entrypoint(manifest):
    return any(key in manifest for key in ["skills", "hooks", "mcpServers", "apps"])


def compare_generated(path, expected, reporter, code, fix=False):
    expected_text = canonical_json(expected)
    if fix:
        try:
            changed = write_if_changed(path, expected_text)
        except OSError as exc:
            reporter.error("E002", f"cannot write generated file: {rel(path)}: {exc}")
            return
        reporter.add_ok(code, f"{'updated' if changed else 'current'}: {rel(path)}")
        return
    if not path.exists():
        reporter.error(code, f"missing generated file: {rel(path)}")
        return
    actual_text = read_text(path)
    if actual_text != expected_text:
        reporter.error(code, f"generated drift: {rel(path)}")
    else:
        reporter.add_ok(code, f"generated file current: {rel(path)}")


def validate_source_schema(source, reporter):
    required_top = ["name", "description", "owner", "codex", "plugins"]
    for field in required_top:
        if field not in source:
            reporter.error("E100", f"source missing top-level field: {field}")
    if not isinstance(source.get("plugins"), list):
        reporter.error("E101", "source plugins must be a list")
        return []

    seen = set()
    plugins = []
    for index, plugin in enumerate(source["plugins"]):
        name = plugin.get("name", "")
        label = name or f"plugins[{index}]"
        if not name:
            reporter.error("E110", f"plugin missing name: {label}")
            continue
        if name in seen:
            reporter.error("E111", f"duplicate plugin name: {name}")
        seen.add(name)
        plugins.append(plugin)
        if not KEBAB_RE.match(name):
            reporter.error("E112", f"plugin name must be kebab-case: {name}")
        for field in ["description", "version", "author", "claude", "codex"]:
            if field not in plugin:
                reporter.error("E113", f"{name} missing field: {field}")
        version = plugin.get("version", "")
        if version and not SEMVER_RE.match(version):
            reporter.error("E114", f"{name} version must be semver: {version}")
        author = plugin.get("author", {})
        if not isinstance(author, dict) or not author.get("name"):
            reporter.error("E115", f"{name} author.name is required")
        claude = plugin.get("claude", {})
        if not isinstance(claude, dict) or not claude.get("category"):
            reporter.error("E116", f"{name} claude.category is required")
        codex = plugin.get("codex", {})
        if not isinstance(codex, dict):
            reporter.error("E117", f"{name} codex must be an object")
            continue
        if codex.get("status") not in {"planned", "ready", "claude-only"}:
            reporter.error("E118", f"{name} codex.status must be planned, ready, or claude-only")
        if not codex.get("category"):
            reporter.error("E119", f"{name} codex.category is required")
        interface = codex.get("interface", {})
        for field in [
            "displayName",
            "shortDescription",
            "longDescription",
            "developerName",
            "category",
            "capabilities",
            "defaultPrompt",
        ]:
            if field not in interface:
                reporter.error("E120", f"{name} codex.interface missing field: {field}")
    reporter.add_ok("S100", "source schema checked")
    return plugins


def validate_plugin_dirs(source_plugins, reporter):
    expected = {plugin["name"] for plugin in source_plugins if "name" in plugin}
    actual = {
        path.name
        for path in (REPO_ROOT / "plugins").iterdir()
        if path.is_dir() and not path.name.startswith(".")
    }
    for name in sorted(expected - actual):
        reporter.error("E200", f"source plugin missing directory: plugins/{name}")
    for name in sorted(actual - expected):
        reporter.error("E201", f"plugin directory missing from source: plugins/{name}")
    if expected == actual:
        reporter.add_ok("S200", "plugin directories match source")


def parse_frontmatter(path, reporter):
    lines = read_text(path).splitlines()
    if not lines or lines[0] != "---":
        reporter.error("E300", f"missing frontmatter start: {rel(path)}")
        return {}
    try:
        end = lines.index("---", 1)
    except ValueError:
        reporter.error("E301", f"missing frontmatter end: {rel(path)}")
        return {}
    fields = {}
    for line in lines[1:end]:
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        fields[key.strip()] = value.strip().strip('"')
    return fields


def validate_skills(reporter):
    skill_paths = sorted((REPO_ROOT / "plugins").glob("*/skills/*/SKILL.md"))
    for path in skill_paths:
        fields = parse_frontmatter(path, reporter)
        name = fields.get("name", "")
        if not name:
            reporter.error("E310", f"skill missing name: {rel(path)}")
        elif not KEBAB_RE.match(name):
            reporter.error("E311", f"skill name must be kebab-case: {rel(path)}: {name}")
        elif path.parent.name != name:
            reporter.error("E312", f"skill folder/name mismatch: {rel(path)}: {name}")
        if not fields.get("description"):
            reporter.error("E313", f"skill missing description: {rel(path)}")
        if not fields.get("version"):
            reporter.warn("W310", f"skill missing version: {rel(path)}")
    reporter.add_ok("S300", f"skill files checked: {len(skill_paths)}")


def validate_commands(reporter):
    command_paths = sorted((REPO_ROOT / "plugins").glob("*/commands/*.md"))
    for path in command_paths:
        if not read_text(path).strip():
            reporter.error("E400", f"empty command adapter: {rel(path)}")
        fields = parse_frontmatter(path, reporter)
        if not fields.get("name"):
            reporter.error("E401", f"command missing name: {rel(path)}")
        if not fields.get("description"):
            reporter.error("E402", f"command missing description: {rel(path)}")
    reporter.add_ok("S400", f"command adapters checked: {len(command_paths)}")


def validate_scripts(reporter):
    scripts = sorted((REPO_ROOT / "plugins").glob("*/hooks/*.sh"))
    for path in scripts:
        mode = path.stat().st_mode
        if not mode & stat.S_IXUSR:
            reporter.error("E500", f"script is not executable: {rel(path)}")
    reporter.add_ok("S500", f"hook scripts checked: {len(scripts)}")


def validate_claude(source, reporter, fix=False):
    compare_generated(
        REPO_ROOT / ".claude-plugin" / "marketplace.json",
        expected_claude_marketplace(source),
        reporter,
        "S610",
        fix,
    )
    for plugin in source["plugins"]:
        compare_generated(
            plugin_dir(plugin["name"]) / ".claude-plugin" / "plugin.json",
            expected_claude_plugin(plugin),
            reporter,
            "S611",
            fix,
        )


def validate_dual(source, reporter, fix=False):
    compare_generated(
        REPO_ROOT / ".agents" / "plugins" / "marketplace.json",
        expected_codex_marketplace(source),
        reporter,
        "S710",
        fix,
    )
    for plugin in source["plugins"]:
        manifest = expected_codex_plugin(plugin)
        compare_generated(
            plugin_dir(plugin["name"]) / ".codex-plugin" / "plugin.json",
            manifest,
            reporter,
            "S711",
            fix,
        )
        status = plugin["codex"]["status"]
        if status == "planned":
            reporter.error("E720", f"codex.status is still planned: {plugin['name']}")
        if status == "ready" and not has_codex_entrypoint(manifest):
            reporter.error("E721", f"codex.status ready requires a functional entrypoint: {plugin['name']}")


def main():
    parser = argparse.ArgumentParser(description="Verify claude-toymarket structure deterministically.")
    parser.add_argument("--profile", choices=["claude", "dual"], default="claude")
    parser.add_argument("--fix", action="store_true", help="write generated manifest files for the selected profile")
    parser.add_argument("--full", action="store_true", help="include executable script checks")
    parser.add_argument("--quiet", action="store_true", help="print only warnings, errors, and summary")
    args = parser.parse_args()

    reporter = Reporter()
    source = load_json(SOURCE_PATH, reporter, "E001")
    if source is None:
        reporter.print(args.quiet)
        return 1

    plugins = validate_source_schema(source, reporter)
    validate_plugin_dirs(plugins, reporter)
    validate_skills(reporter)
    validate_commands(reporter)
    if args.full:
        validate_scripts(reporter)
    validate_claude(source, reporter, fix=args.fix)
    if args.profile == "dual":
        validate_dual(source, reporter, fix=args.fix)

    reporter.print(args.quiet)
    return 1 if reporter.errors else 0


if __name__ == "__main__":
    sys.exit(main())
