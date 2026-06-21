#!/usr/bin/env python3
"""Read Codex account rate limits through the local Codex app server."""

from __future__ import annotations

import json
import os
import selectors
import shutil
import subprocess
import sys
import time
from typing import Any


TIMEOUT_SECONDS = 15


def emit(payload: dict[str, Any]) -> None:
    print(json.dumps(payload, separators=(",", ":")), flush=True)


def fail(message: str) -> None:
    emit({"status": "error", "message": message})


def send(process: subprocess.Popen[bytes], payload: dict[str, Any]) -> None:
    assert process.stdin is not None
    process.stdin.write((json.dumps(payload, separators=(",", ":")) + "\n").encode())
    process.stdin.flush()


def read_message(
    process: subprocess.Popen[bytes],
    selector: selectors.BaseSelector,
    deadline: float,
    buffer: bytearray,
) -> dict[str, Any]:
    assert process.stdout is not None
    while time.monotonic() < deadline:
        newline = buffer.find(b"\n")
        if newline >= 0:
            line = bytes(buffer[:newline]).strip()
            del buffer[: newline + 1]
            if not line:
                continue
            try:
                message = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(message, dict):
                return message

        events = selector.select(max(0.0, deadline - time.monotonic()))
        if not events:
            break
        chunk = os.read(process.stdout.fileno(), 65536)
        if not chunk:
            details = ""
            if process.stderr is not None:
                details = process.stderr.read().decode(errors="replace").strip()
            suffix = f": {details.splitlines()[-1]}" if details else ""
            raise RuntimeError(f"Codex app server closed unexpectedly{suffix}")
        buffer.extend(chunk)
    raise TimeoutError("Timed out while waiting for Codex")


def window_payload(window: Any) -> dict[str, Any] | None:
    if not isinstance(window, dict):
        return None
    used = max(0, min(100, int(window.get("usedPercent", 0))))
    return {
        "usedPercent": used,
        "remainingPercent": 100 - used,
        "resetsAt": window.get("resetsAt"),
        "durationMinutes": window.get("windowDurationMins"),
    }


def normalize(result: dict[str, Any]) -> dict[str, Any]:
    snapshot = result.get("rateLimits")
    buckets = result.get("rateLimitsByLimitId")
    if isinstance(buckets, dict) and buckets:
        snapshot = buckets.get("codex") or next(iter(buckets.values()))
    if not isinstance(snapshot, dict):
        raise RuntimeError("Codex returned no rate-limit information")

    return {
        "status": "ok",
        "planType": snapshot.get("planType") or "unknown",
        "limitId": snapshot.get("limitId"),
        "limitName": snapshot.get("limitName"),
        "primary": window_payload(snapshot.get("primary")),
        "secondary": window_payload(snapshot.get("secondary")),
        "credits": snapshot.get("credits"),
        "rateLimitReachedType": snapshot.get("rateLimitReachedType"),
        "fetchedAt": int(time.time()),
    }


def main() -> int:
    codex = shutil.which(os.environ.get("CODEX_BINARY", "codex"))
    if not codex:
        fail("Codex CLI was not found in PATH")
        return 1

    process = subprocess.Popen(
        [codex, "app-server", "--stdio"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        bufsize=0,
    )
    selector = selectors.DefaultSelector()
    assert process.stdout is not None
    selector.register(process.stdout, selectors.EVENT_READ)
    deadline = time.monotonic() + TIMEOUT_SECONDS
    read_buffer = bytearray()

    try:
        send(
            process,
            {
                "id": 1,
                "method": "initialize",
                "params": {
                    "clientInfo": {
                        "name": "kde-codex-usage",
                        "title": "KDE Codex Usage",
                        "version": "0.1.0",
                    },
                    "capabilities": {"experimentalApi": True},
                },
            },
        )

        while True:
            message = read_message(process, selector, deadline, read_buffer)
            if message.get("id") == 1:
                if "error" in message:
                    raise RuntimeError(str(message["error"].get("message", message["error"])))
                break

        send(process, {"method": "initialized"})
        send(process, {"id": 2, "method": "account/rateLimits/read", "params": None})

        while True:
            message = read_message(process, selector, deadline, read_buffer)
            if message.get("id") != 2:
                continue
            if "error" in message:
                error = message["error"]
                raise RuntimeError(str(error.get("message", error)))
            result = message.get("result")
            if not isinstance(result, dict):
                raise RuntimeError("Codex returned an invalid response")
            emit(normalize(result))
            return 0
    except (OSError, RuntimeError, TimeoutError, ValueError) as error:
        fail(str(error))
        return 1
    finally:
        selector.close()
        process.terminate()
        try:
            process.wait(timeout=1)
        except subprocess.TimeoutExpired:
            process.kill()


if __name__ == "__main__":
    sys.exit(main())
