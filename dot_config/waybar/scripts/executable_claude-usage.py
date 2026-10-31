#!/usr/bin/python3
"""Waybar module: today's local Claude Code usage.

Ports the part of Omarchy 4's `omarchy.agents` panel (MIT) that needs no
credentials. Omarchy's version also pulls authoritative rate limits from
Anthropic's OAuth usage endpoint; that half is deliberately left out, so this
reads nothing but the transcripts already on disk and never makes a request.

Source is ~/.claude/projects/*/*.jsonl. Only files modified since local midnight
are opened, which keeps a 200MB history down to a ~15MB read.
"""

from __future__ import annotations

import datetime as dt
import glob
import json
import os
import sys
import time

CACHE = os.path.join(
    os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")),
    "waybar-claude-usage.json",
)
CACHE_TTL = 60  # seconds; the bar polls faster than the numbers meaningfully move
ROOT = os.path.expanduser("~/.claude/projects")


def escape(value: str) -> str:
    """Pango-escape a value. Only model names reach the tooltip unvetted."""
    return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def humanize(n: int) -> str:
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n / 1_000:.0f}k"
    return str(n)


def collect() -> dict:
    # Aware, because transcript stamps are aware once parsed; comparing the two
    # forms raises rather than silently misbucketing.
    midnight = dt.datetime.now().astimezone().replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    cutoff = midnight.timestamp()
    week_ago = (midnight - dt.timedelta(days=6)).timestamp()

    today = {"input": 0, "output": 0, "cache_read": 0, "cache_write": 0}
    per_model: dict[str, int] = {}
    sessions: set[str] = set()
    week_total = 0

    for path in glob.glob(os.path.join(ROOT, "*", "*.jsonl")):
        try:
            mtime = os.path.getmtime(path)
        except OSError:
            continue
        if mtime < week_ago:
            continue
        recent = mtime >= cutoff

        try:
            fh = open(path, encoding="utf-8", errors="replace")
        except OSError:
            continue
        with fh:
            for line in fh:
                line = line.strip()
                if not line or '"usage"' not in line:
                    continue
                try:
                    rec = json.loads(line)
                except ValueError:
                    continue
                usage = (rec.get("message") or {}).get("usage")
                if not usage:
                    continue
                stamp = rec.get("timestamp")
                if not stamp:
                    continue
                try:
                    # Transcripts stamp UTC with a trailing Z; compare in local time.
                    when = dt.datetime.fromisoformat(stamp.replace("Z", "+00:00")).astimezone()
                except ValueError:
                    continue

                # Cache reads are excluded everywhere except their own tooltip
                # line, so every rolled-up figure means the same thing.
                total = (
                    (usage.get("input_tokens") or 0)
                    + (usage.get("output_tokens") or 0)
                    + (usage.get("cache_creation_input_tokens") or 0)
                )
                if when >= midnight - dt.timedelta(days=6):
                    week_total += total
                if not recent or when < midnight:
                    continue

                today["input"] += usage.get("input_tokens") or 0
                today["output"] += usage.get("output_tokens") or 0
                today["cache_read"] += usage.get("cache_read_input_tokens") or 0
                today["cache_write"] += usage.get("cache_creation_input_tokens") or 0
                model = (rec.get("message") or {}).get("model") or "unknown"
                per_model[model] = per_model.get(model, 0) + total
                if rec.get("sessionId"):
                    sessions.add(rec["sessionId"])

    return {
        "today": today,
        "per_model": per_model,
        "sessions": len(sessions),
        "week_total": week_total,
    }


def render(data: dict) -> dict:
    today = data["today"]
    # Cache reads dominate any session by an order of magnitude and say nothing
    # about how hard the day was, so the headline counts the tokens that were
    # actually produced or freshly sent. The full split stays in the tooltip.
    headline = today["input"] + today["output"] + today["cache_write"]
    if headline + today["cache_read"] == 0:
        return {"text": "", "tooltip": ""}

    lines = [
        "<b>Claude Code today</b>",
        f"Sessions      {data['sessions']}",
        "",
        f"Input         {humanize(today['input'])}",
        f"Output        {humanize(today['output'])}",
        f"Cache write   {humanize(today['cache_write'])}",
        f"Billed-ish    {humanize(headline)}   ← shown in the bar",
        "",
        f"Cache read    {humanize(today['cache_read'])}   (excluded)",
    ]
    if data["per_model"]:
        lines.append("")
        for model, count in sorted(data["per_model"].items(), key=lambda kv: -kv[1]):
            lines.append(f"{escape(model):<22} {humanize(count)}")
    lines += ["", f"Last 7 days   {humanize(data['week_total'])}   (same basis)"]
    lines.append("\nLocal transcripts only — no rate-limit data.")

    return {
        "text": humanize(headline),
        "class": "claude",
        "alt": "claude",
        "tooltip": "\n".join(lines),
    }


def main() -> None:
    now = time.time()
    if "--force" not in sys.argv:
        try:
            if now - os.path.getmtime(CACHE) < CACHE_TTL:
                with open(CACHE, encoding="utf-8") as fh:
                    print(fh.read().strip())
                    return
        except (OSError, ValueError):
            pass

    payload = json.dumps(render(collect()), ensure_ascii=False)
    try:
        os.makedirs(os.path.dirname(CACHE), exist_ok=True)
        with open(CACHE, "w", encoding="utf-8") as fh:
            fh.write(payload)
    except OSError:
        pass
    print(payload)


if __name__ == "__main__":
    main()
