#!/usr/bin/env python3
"""Verify workspace claims locally without printing credentials.

Run after interactive Business login on both hosts with the same expected
workspace account ID. This does not infer account type from an email address.
"""
import argparse
import base64
import json
from pathlib import Path
import re
import os
import shutil
import tempfile
import time
import tomllib

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('expected_account_id', nargs='?')
parser.add_argument('--check', action='store_true', help='check existing binding without changing it')
parser.add_argument('--show', action='store_true', help='show only workspace ID and plan, never credentials')
args = parser.parse_args()
root = Path.home()
marker = root / '.config/codex-usage-monitor/business/identity-verified'
if args.check:
    if not marker.exists():
        raise SystemExit(1)
    args.expected_account_id = marker.read_text().strip()
if not args.show and not re.fullmatch(r'[A-Za-z0-9._-]{1,64}', args.expected_account_id or ''):
    raise SystemExit('invalid workspace account ID')
data = json.loads((root / '.codex-business/auth.json').read_text())
token = data.get('tokens', {}).get('id_token', '')
try:
    claims = json.loads(base64.urlsafe_b64decode(token.split('.')[1] + '==='))
    auth = claims['https://api.openai.com/auth']
except (ValueError, KeyError, IndexError):
    raise SystemExit('no usable ChatGPT workspace identity; log in first')
if args.show:
    print(json.dumps({key: auth.get(key) for key in ('chatgpt_account_id', 'chatgpt_plan_type')}))
    raise SystemExit(0)
if auth.get('chatgpt_account_id') != args.expected_account_id or auth.get('chatgpt_plan_type') not in ('team', 'business'):
    raise SystemExit('Business workspace identity does not match; collection remains disabled')
if args.check:
    raise SystemExit(0)
config = root / '.codex-business/config.toml'
if config.is_symlink():
    raise SystemExit('refusing to bind a symlinked user configuration')
text = config.read_text()
existing = tomllib.loads(text).get('forced_chatgpt_workspace_id')
if existing is not None and existing != args.expected_account_id:
    raise SystemExit('existing workspace restriction conflicts; no changes made')
if existing is None:
    backup = config.with_name('config.toml.bak-' + str(time.time_ns()))
    shutil.copy2(config, backup)
    backup.chmod(0o600)
    fd, temporary = tempfile.mkstemp(dir=config.parent, prefix='.workspace-binding-')
    with os.fdopen(fd, 'w') as stream:
        stream.write('forced_chatgpt_workspace_id = ' + json.dumps(args.expected_account_id) + '\n' + text)
    os.replace(temporary, config)
with marker.open('x') as stream:
    stream.write(args.expected_account_id + '\n')
marker.chmod(0o600)
print('Business workspace claims match; collection can now be enabled')
