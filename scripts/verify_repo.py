#!/usr/bin/env python3
"""Deterministic repository structure verifier for claude-toymarket."""

import argparse
import json
import re
import stat
import sys
from pathlib import Path

# optional: every other check still runs without pyyaml installed
try:
    import yaml
except ImportError:
    yaml = None


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATH = REPO_ROOT / "catalog" / "toymarket.json"
KEBAB_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
SEMVER_RE = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+(?:[-+][0-9A-Za-z.-]+)?$")
AGENT_PLUGINS_SCHEMA = "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"
AGENT_PLUGINS_MCP_SCHEMA = "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json"
# 카탈로그는 Agent Plugins 전송 이름(stdio, streamable-http, sse)을 쓴다.
# Claude 설정은 원격 전송을 http로 부르므로 생성할 때 바꿔 준다.
CLAUDE_MCP_TYPE = {"streamable-http": "http"}
MCP_REMOTE_TYPES = {"streamable-http", "sse"}


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


def expected_cursor_marketplace(source):
    return {
        "name": source["name"],
        "displayName": source["cursor"]["displayName"],
        "owner": source["owner"],
        "metadata": {
            "description": source["description"],
            "pluginRoot": "plugins",
        },
        "plugins": [
            {
                "name": plugin["name"],
                "source": plugin["name"],
                "description": plugin.get("claude", {}).get(
                    "marketplaceDescription", plugin["description"]
                ),
            }
            for plugin in source["plugins"]
        ],
    }


def expected_cursor_plugin(plugin):
    name = plugin["name"]
    manifest = {
        "name": name,
        "description": plugin["description"],
        "version": plugin["version"],
        "author": plugin["author"],
    }
    # 루트 mcp.json은 Agent Plugins 문서다. Cursor는 Agent Plugins 규격 플러그인을
    # 그 경로로 직접 읽으므로 Cursor 전용 매니페스트에서 다시 가리키지 않는다.
    if hook_config_path(name) is not None:
        # Claude hook schema is not Cursor-compatible; skip auto-discovery.
        manifest["hooks"] = {}
    return manifest


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
        if "mcp" in plugin:
            manifest["mcpServers"] = "./.mcp.json"
        app_path = plugin_dir(name) / ".app.json"
        if app_path.exists():
            manifest["apps"] = "./.app.json"
    manifest["interface"] = plugin["codex"]["interface"]
    return manifest


def has_codex_entrypoint(manifest):
    return any(key in manifest for key in ["skills", "hooks", "mcpServers", "apps"])


def expected_claude_mcp(plugin):
    servers = {}
    for server_name, server in plugin["mcp"].items():
        rendered = dict(server)
        rendered["type"] = CLAUDE_MCP_TYPE.get(server["type"], server["type"])
        servers[server_name] = rendered
    return {"mcpServers": servers}


def expected_kiro_plugin(plugin):
    # Agent Plugins 1.0.0의 manifest 스키마는 닫혀 있다. 표에 없는 최상위 키는
    # 스키마 위반이므로 skills/hooks 포인터를 넣지 않는다. 클라이언트는 skills/와
    # mcp.json을 고정 위치에서 스스로 발견한다.
    return {
        "$schema": AGENT_PLUGINS_SCHEMA,
        "name": plugin["name"],
        "version": plugin["version"],
        "description": plugin["description"],
        "author": plugin["author"],
        "keywords": plugin["keywords"],
    }


def expected_kiro_mcp(plugin):
    return {
        "$schema": AGENT_PLUGINS_MCP_SCHEMA,
        "mcpServers": plugin["mcp"],
    }


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
    required_top = ["name", "description", "owner", "codex", "cursor", "plugins"]
    for field in required_top:
        if field not in source:
            reporter.error("E100", f"source missing top-level field: {field}")
    cursor = source.get("cursor")
    if not isinstance(cursor, dict) or not cursor.get("displayName"):
        reporter.error("E102", "source cursor.displayName is required")
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
        for field in ["description", "version", "author", "keywords", "claude", "codex"]:
            if field not in plugin:
                reporter.error("E113", f"{name} missing field: {field}")
        version = plugin.get("version", "")
        if version and not SEMVER_RE.match(version):
            reporter.error("E114", f"{name} version must be semver: {version}")
        author = plugin.get("author", {})
        if not isinstance(author, dict) or not author.get("name"):
            reporter.error("E115", f"{name} author.name is required")
        # `keywords: null`은 키가 있으므로 E113에 걸리지 않는다. 존재 여부로 분기해
        # null과 잘못된 타입을 같은 자리에서 잡는다.
        if "keywords" in plugin:
            keywords = plugin["keywords"]
            if not isinstance(keywords, list) or not keywords:
                reporter.error("E121", f"{name} keywords must be a non-empty list")
            elif not all(isinstance(word, str) and word.strip() for word in keywords):
                reporter.error("E122", f"{name} keywords must all be non-empty strings")
        # mcp는 선택 블록이다. 있으면 Agent Plugins 전송 어휘로만 적는다.
        if "mcp" in plugin:
            servers = plugin["mcp"]
            if not isinstance(servers, dict) or not servers:
                reporter.error("E123", f"{name} mcp must be a non-empty object")
            else:
                for server_name, server in servers.items():
                    label = f"{name} mcp.{server_name}"
                    if not isinstance(server, dict):
                        reporter.error("E124", f"{label} must be an object")
                        continue
                    transport = server.get("type")
                    if transport not in {"stdio"} | MCP_REMOTE_TYPES:
                        reporter.error(
                            "E125",
                            f"{label} type must be stdio, streamable-http, or sse: {transport}",
                        )
                    elif transport == "stdio" and not server.get("command"):
                        reporter.error("E126", f"{label} stdio requires command")
                    elif transport in MCP_REMOTE_TYPES and not server.get("url"):
                        reporter.error("E126", f"{label} {transport} requires url")
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
    block = "\n".join(lines[1:end])
    if yaml is None:
        fields = {}
        for line in lines[1:end]:
            if ":" not in line:
                continue
            key, value = line.split(":", 1)
            fields[key.strip()] = value.strip().strip('"')
        return fields
    try:
        fields = yaml.safe_load(block)
    except yaml.YAMLError as exc:
        detail = " ".join(str(exc).split())
        reporter.error("E302", f"frontmatter is not valid yaml: {rel(path)}: {detail}")
        return {}
    if fields is None:
        fields = {}
    if not isinstance(fields, dict):
        reporter.error("E303", f"frontmatter is not a mapping: {rel(path)}")
        return {}
    return fields


def validate_skills(reporter):
    skill_paths = sorted((REPO_ROOT / "plugins").glob("*/skills/*/SKILL.md"))
    for path in skill_paths:
        fields = parse_frontmatter(path, reporter)
        name = str(fields.get("name") or "")
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


def validate_agents(reporter):
    agent_paths = sorted((REPO_ROOT / "plugins").glob("*/agents/*.md"))
    for path in agent_paths:
        fields = parse_frontmatter(path, reporter)
        name = str(fields.get("name") or "")
        if not name:
            reporter.error("E320", f"agent missing name: {rel(path)}")
        elif not KEBAB_RE.match(name):
            reporter.error("E321", f"agent name must be kebab-case: {rel(path)}: {name}")
        elif path.stem != name:
            reporter.error("E322", f"agent file/name mismatch: {rel(path)}: {name}")
        if not fields.get("description"):
            reporter.error("E323", f"agent missing description: {rel(path)}")
    reporter.add_ok("S310", f"agent files checked: {len(agent_paths)}")


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
        if "mcp" in plugin:
            compare_generated(
                plugin_dir(plugin["name"]) / ".mcp.json",
                expected_claude_mcp(plugin),
                reporter,
                "S612",
                fix,
            )


def validate_cursor(source, reporter, fix=False):
    compare_generated(
        REPO_ROOT / ".cursor-plugin" / "marketplace.json",
        expected_cursor_marketplace(source),
        reporter,
        "S810",
        fix,
    )
    for plugin in source["plugins"]:
        compare_generated(
            plugin_dir(plugin["name"]) / ".cursor-plugin" / "plugin.json",
            expected_cursor_plugin(plugin),
            reporter,
            "S811",
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


def validate_kiro(source, reporter, fix=False):
    # Kiro는 power 패키지 루트의 plugin.json만 읽는다. 별도 marketplace 파일은 없고
    # 저장소 하나에 여러 power가 디렉터리별로 들어 있는 구조를 그대로 받는다.
    for plugin in source["plugins"]:
        compare_generated(
            plugin_dir(plugin["name"]) / "plugin.json",
            expected_kiro_plugin(plugin),
            reporter,
            "S911",
            fix,
        )
        if "mcp" in plugin:
            compare_generated(
                plugin_dir(plugin["name"]) / "mcp.json",
                expected_kiro_mcp(plugin),
                reporter,
                "S912",
                fix,
            )


def main():
    parser = argparse.ArgumentParser(description="Verify claude-toymarket structure deterministically.")
    parser.add_argument("--profile", choices=["claude", "dual", "kiro", "all"], default="claude")
    parser.add_argument("--fix", action="store_true", help="write generated manifest files for the selected profile")
    parser.add_argument("--full", action="store_true", help="include executable script checks")
    parser.add_argument("--quiet", action="store_true", help="print only warnings, errors, and summary")
    args = parser.parse_args()

    reporter = Reporter()
    source = load_json(SOURCE_PATH, reporter, "E001")
    if source is None:
        reporter.print(args.quiet)
        return 1

    if yaml is None:
        reporter.warn("W302", "pyyaml missing: frontmatter yaml validity not checked")

    plugins = validate_source_schema(source, reporter)
    # 생성기는 카탈로그 필드를 직접 인덱싱한다. 스키마가 깨진 채로 들어가면
    # KeyError로 죽어 정작 원인인 E1xx를 못 보여주므로, 여기서 멈춘다.
    source_schema_ok = not reporter.errors
    validate_plugin_dirs(plugins, reporter)
    validate_skills(reporter)
    validate_agents(reporter)
    validate_commands(reporter)
    if args.full:
        validate_scripts(reporter)
    if source_schema_ok:
        validate_claude(source, reporter, fix=args.fix)
        if args.profile in {"dual", "all"}:
            validate_cursor(source, reporter, fix=args.fix)
            validate_dual(source, reporter, fix=args.fix)
        if args.profile in {"kiro", "all"}:
            validate_kiro(source, reporter, fix=args.fix)
    else:
        reporter.warn("W600", "source schema is invalid: generated manifest checks skipped")

    reporter.print(args.quiet)
    return 1 if reporter.errors else 0


if __name__ == "__main__":
    sys.exit(main())
