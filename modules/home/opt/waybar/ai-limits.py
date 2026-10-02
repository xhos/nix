"""Waybar image module: outer five-hour / inner weekly allowance rings.

Only reads existing CLI credentials. Never refreshes or copies login tokens.
Claude's OAuth usage endpoint is internal and may change independently of the CLI.
"""

import argparse
import datetime as dt
import fcntl
import html
import json
import math
import os
from pathlib import Path
import selectors
import subprocess
import time
import urllib.error
import urllib.request


class UsageError(Exception):
    pass


def read_json(path):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return {}


def atomic_write(path, content):
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(content)
    temporary.replace(path)


def timestamp(value):
    if isinstance(value, str):
        return dt.datetime.fromisoformat(value.replace('Z', '+00:00')).timestamp()
    return float(value) if value is not None else None


def window(used, reset):
    if used is None:
        return None
    return {'remaining': max(0, min(100, 100 - float(used))), 'reset': timestamp(reset)}


def claude_usage():
    config = Path(os.environ.get('CLAUDE_CONFIG_DIR', Path.home() / '.config/claude'))
    if not config.exists():
        config = Path.home() / '.claude'
    auth = read_json(config / '.credentials.json').get('claudeAiOauth', {})
    token = auth.get('accessToken')
    if not token:
        raise UsageError('Sign in to Claude Code to show usage.')
    request = urllib.request.Request(
        'https://api.anthropic.com/api/oauth/usage',
        headers={'Authorization': 'Bearer ' + token,
                 'anthropic-beta': 'oauth-2025-04-20',
                 'User-Agent': 'waybar-ai-limits/1.0'},
    )
    try:
        with urllib.request.urlopen(request, timeout=12) as response:
            data = json.load(response)
    except urllib.error.HTTPError as error:
        if error.code in (401, 403):
            raise UsageError('Claude login expired or usage unavailable; open Claude Code to sign in.') from None
        raise UsageError(f'Claude usage request failed (HTTP {error.code}).') from None
    return {name: window((data.get(key) or {}).get('utilization'),
                         (data.get(key) or {}).get('resets_at'))
            for name, key in [('five_hour', 'five_hour'), ('weekly', 'seven_day')]}


def codex_usage():
    # No thread or turn is started: this only queries the account's allowance.
    with subprocess.Popen(['codex', 'app-server'], stdin=subprocess.PIPE,
                          stdout=subprocess.PIPE, stderr=subprocess.DEVNULL) as process:
        selector = selectors.DefaultSelector()
        selector.register(process.stdout, selectors.EVENT_READ)
        buffer = b''
        deadline = time.monotonic() + 18

        def send(message):
            process.stdin.write((json.dumps(message) + '\n').encode())
            process.stdin.flush()

        def receive(request_id):
            nonlocal buffer
            while time.monotonic() < deadline:
                while b'\n' in buffer:
                    line, buffer = buffer.split(b'\n', 1)
                    message = json.loads(line)
                    if message.get('id') == request_id:
                        if 'error' in message:
                            raise UsageError('Codex usage unavailable; check your Codex login.')
                        return message['result']
                if selector.select(max(0, deadline - time.monotonic())):
                    chunk = os.read(process.stdout.fileno(), 65536)
                    if not chunk:
                        break
                    buffer += chunk
            raise UsageError('Codex usage request timed out.')

        try:
            send({'id': 1, 'method': 'initialize', 'params': {
                'clientInfo': {'name': 'waybar_ai_limits', 'version': '1.0.0'}}})
            receive(1)
            send({'method': 'initialized', 'params': {}})
            send({'id': 2, 'method': 'account/rateLimits/read'})
            result = receive(2)
        finally:
            selector.close()
            process.terminate()
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
    limits = (result.get('rateLimitsByLimitId') or {}).get('codex') or result.get('rateLimits') or {}
    data = {'five_hour': None, 'weekly': None}
    for key in ('primary', 'secondary'):
        bucket = limits.get(key) or {}
        name = {300: 'five_hour', 10080: 'weekly'}.get(bucket.get('windowDurationMins'))
        if name:
            data[name] = window(bucket.get('usedPercent'), bucket.get('resetsAt'))
    return data


def render(provider, data, colors, stale=False, now=None):
    now = time.time() if now is None else now
    text, muted, normal, warning, critical = colors
    parts = ['<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 28 28">']
    details = []
    for key, radius, label in [('five_hour', 12, '5-hour (outer)'), ('weekly', 8.5, 'Weekly (inner)')]:
        bucket = data.get(key)
        expired = bucket and bucket.get('reset') is not None and bucket['reset'] <= now
        valid = bucket is not None and not expired
        parts.append(f'<circle cx="14" cy="14" r="{radius}" fill="none" stroke="{muted}" stroke-opacity="0.28" stroke-width="2"/>')
        if valid:
            remaining = bucket['remaining']
            color = muted if stale else critical if remaining <= 10 else warning if remaining <= 25 else normal
            circumference = 2 * math.pi * radius
            if remaining > 0:
                parts.append(f'<circle cx="14" cy="14" r="{radius}" fill="none" stroke="{color}" stroke-width="2" stroke-dasharray="{circumference * remaining / 100:.3f} {circumference:.3f}" transform="rotate(-90 14 14)"/>')
            reset = bucket.get('reset')
            when = dt.datetime.fromtimestamp(reset).astimezone().strftime('%a %H:%M') if reset else 'unknown'
            details.append(f'{label}: {remaining:.0f}% remaining · resets {when}')
        else:
            details.append(f'{label}: awaiting fresh usage' if expired else f'{label}: unavailable')
    # Tiny vector letters remain legible at bar size without depending on fonts.
    mark = ('M16 11 H12 V17 H16' if provider == 'claude' else 'M16 11 H12 V17 H16 V14 H14')
    parts.append(f'<path d="{mark}" fill="none" stroke="{muted if stale else text}" stroke-width="1.3" stroke-linejoin="round"/>')
    parts.append('</svg>')
    return ''.join(parts), details


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('provider', choices=['claude', 'codex'])
    parser.add_argument('--colors', nargs=5, default=['#cdd6f4', '#6c7086', '#a6e3a1', '#f9e2af', '#f38ba8'])
    args = parser.parse_args()
    cache_dir = Path(os.environ.get('XDG_CACHE_HOME', Path.home() / '.cache')) / 'waybar-ai-limits'
    cache_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    cache_path = cache_dir / f'{args.provider}.json'
    # Avoid duplicate fetches if multiple bars ask for the same provider.
    with (cache_dir / f'{args.provider}.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        cache = read_json(cache_path)
        now = time.time()
        if now - cache.get('attempted_at', 0) >= 300:
            cache['attempted_at'] = now
            try:
                cache['data'] = (claude_usage if args.provider == 'claude' else codex_usage)()
                cache['updated_at'] = now
                cache.pop('error', None)
            except UsageError as error:
                cache['error'] = str(error)
            except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError):
                cache['error'] = 'Could not read usage; check network and CLI login.'
            atomic_write(cache_path, json.dumps(cache))
        stale = bool(cache.get('error')) or now - cache.get('updated_at', 0) > 600
        svg, details = render(args.provider, cache.get('data', {}), args.colors, stale, now)
        image_path = cache_dir / f'{args.provider}.svg'
        atomic_write(image_path, svg)
    title = 'Claude' if args.provider == 'claude' else 'Codex / GPT'
    tooltip = [f'<b>{title}</b>', *map(html.escape, details)]
    if cache.get('updated_at'):
        age = max(0, int((now - cache['updated_at']) / 60))
        tooltip.append(f'Updated {age}m ago' + (' · stale' if stale else ''))
    if cache.get('error'):
        tooltip.append(html.escape(cache['error']))
    print(image_path)
    # Image module reads exactly one tooltip line; Pango encodes line breaks.
    print('&#10;'.join(tooltip))


if __name__ == '__main__':
    main()
