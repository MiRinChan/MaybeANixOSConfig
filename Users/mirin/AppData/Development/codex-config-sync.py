#!/usr/bin/env python3
"""Sync only portable scalar preferences. No credentials, tables or runtime data."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import sys
import tempfile
import time
import tomllib

KEYS = ('model', 'model_reasoning_effort', 'model_reasoning_summary',
        'model_verbosity', 'personality', 'suppress_unstable_features_warning')


def read(path):
    path = Path(path).expanduser()
    if path.is_symlink() or str(path.resolve()).startswith(('/etc/codex/', '/nix/store/')):
        raise ValueError('system config and symlinks are not sync endpoints')
    text = path.read_text() if path.exists() else ''
    return path, text, tomllib.loads(text)


def portable(data):
    result = {}
    for key in KEYS:
        if key in data:
            value = data[key]
            if not isinstance(value, (str, bool)) or (isinstance(value, str) and ('/' in value or '\n' in value)):
                raise ValueError('nonportable value: ' + key)
            result[key] = value
    return result


def merge(text, values):
    original = tomllib.loads(text)
    lines = text.splitlines(keepends=True)
    end = next((i for i, line in enumerate(lines) if line.lstrip().startswith('[')), len(lines))
    prefix = lines[:end]
    for key, value in values.items():
        matches = [i for i, line in enumerate(prefix) if re.match(r'^\s*' + re.escape(key) + r'\s*=', line)]
        if key in original and len(matches) != 1:
            raise ValueError('unsupported TOML spelling: ' + key)
        rendered = f'{key} = {json.dumps(value, ensure_ascii=False)}\n'
        if matches:
            # Refuse multiline values; never remove adjacent configuration.
            tomllib.loads(prefix[matches[0]])
            prefix[matches[0]] = rendered
        else:
            prefix.insert(0, rendered)
    result = ''.join(prefix + lines[end:])
    if tomllib.loads(result) != dict(original, **values):
        raise ValueError('merge changed unrelated configuration')
    return result


def write(path, text):
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    if path.exists():
        backup = path.with_name(path.name + '.bak-' + str(time.time_ns()))
        shutil.copy2(path, backup)
        backup.chmod(0o600)
    fd, name = tempfile.mkstemp(prefix='.config-sync-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(text)
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source')
    parser.add_argument('target', nargs='?')
    parser.add_argument('--export', action='store_true')
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--replace-conflicts', action='store_true')
    args = parser.parse_args()
    if args.source == '-':
        source = tomllib.loads(sys.stdin.read())
    else:
        _, _, source = read(args.source)
    values = portable(source)
    if args.export:
        print(merge('', values), end='')
        return
    if not args.target:
        parser.error('target required')
    path, text, target = read(args.target)
    conflicts = [key for key, value in values.items() if key in target and target[key] != value]
    for key, value in values.items():
        if target.get(key) != value:
            print(f'{key}: {target.get(key)!r} -> {value!r}')
    if args.apply:
        if conflicts and not args.replace_conflicts:
            raise SystemExit('conflicting preferences; review and explicitly use --replace-conflicts')
        write(path, merge(text, values))


if __name__ == '__main__':
    main()
