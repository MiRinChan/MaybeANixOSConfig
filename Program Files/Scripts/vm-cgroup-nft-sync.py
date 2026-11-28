#!/usr/bin/env python3
"""Sync coding-vm and audit-vm systemd user cgroups into an nftables cgroupsv2 set."""

import argparse
import ctypes
import json
import os
import pwd
import re
import select
import signal
import subprocess
import sys

IN_MOVED_FROM = 0x00000040
IN_MOVED_TO = 0x00000080
IN_CREATE = 0x00000100
IN_DELETE = 0x00000200
IN_DELETE_SELF = 0x00000400
IN_MOVE_SELF = 0x00000800
IN_IGNORED = 0x00008000
IN_ONLYDIR = 0x01000000
IN_CLOEXEC = 0o2000000
IN_NONBLOCK = 0o4000

SLICE_MASK = (
    IN_CREATE
    | IN_DELETE
    | IN_MOVED_FROM
    | IN_MOVED_TO
    | IN_DELETE_SELF
    | IN_MOVE_SELF
    | IN_ONLYDIR
)
ANCESTOR_MASK = IN_CREATE | IN_MOVED_TO | IN_DELETE_SELF | IN_MOVE_SELF | IN_ONLYDIR


class Inotify:
    def __init__(self):
        self._libc = ctypes.CDLL("libc.so.6", use_errno=True)
        self._libc.inotify_init1.argtypes = [ctypes.c_int]
        self._libc.inotify_init1.restype = ctypes.c_int
        self._libc.inotify_add_watch.argtypes = [
            ctypes.c_int,
            ctypes.c_char_p,
            ctypes.c_uint32,
        ]
        self._libc.inotify_add_watch.restype = ctypes.c_int
        self._libc.inotify_rm_watch.argtypes = [ctypes.c_int, ctypes.c_int]
        self._libc.inotify_rm_watch.restype = ctypes.c_int

        self.fd = self._libc.inotify_init1(IN_CLOEXEC | IN_NONBLOCK)
        if self.fd < 0:
            err = ctypes.get_errno()
            raise OSError(err, os.strerror(err))
        self.wd = -1

    def set_watch(self, path, mask):
        if self.wd >= 0:
            self._libc.inotify_rm_watch(self.fd, self.wd)
            self.wd = -1
        wd = self._libc.inotify_add_watch(self.fd, os.fsencode(path), mask)
        if wd < 0:
            err = ctypes.get_errno()
            raise OSError(err, os.strerror(err))
        self.wd = wd

    def drain(self):
        while True:
            try:
                data = os.read(self.fd, 65536)
                if not data:
                    break
            except BlockingIOError:
                break

    def close(self):
        if self.fd >= 0:
            os.close(self.fd)
            self.fd = -1


def default_slice_rel(username):
    uid = pwd.getpwnam(username).pw_uid
    return f"user.slice/user-{uid}.slice/user@{uid}.service/app.slice"


def deepest_existing_path(cgroup_root, slice_rel):
    target = os.path.join(cgroup_root, slice_rel)
    current = target
    while True:
        if os.path.isdir(current):
            return current, current == target
        parent = os.path.dirname(current)
        if parent == current:
            return cgroup_root, False
        current = parent


def find_vm_cgroups(cgroup_root, slice_rel, pattern):
    slice_dir = os.path.join(cgroup_root, slice_rel)
    if not os.path.isdir(slice_dir):
        return []
    found = []
    try:
        with os.scandir(slice_dir) as entries:
            for entry in entries:
                if pattern.match(entry.name) and entry.is_dir(follow_symlinks=False):
                    found.append(f"{slice_rel}/{entry.name}")
    except FileNotFoundError:
        return []
    found.sort()
    return found


def read_nft_set(nft_bin, family, table, set_name):
    result = subprocess.run(
        [nft_bin, "-j", "list", "set", family, table, set_name],
        capture_output=True,
        text=True,
        check=True,
    )
    payload = json.loads(result.stdout)
    for item in payload.get("nftables", []):
        set_obj = item.get("set")
        if set_obj and set_obj.get("name") == set_name:
            elems = set_obj.get("elem") or []
            return sorted(str(elem).lstrip("/") for elem in elems)
    return []


def build_nft_script(family, table, set_name, elements):
    lines = [f"flush set {family} {table} {set_name}"]
    if elements:
        quoted = ", ".join('"' + elem.replace('"', '\\"') + '"' for elem in elements)
        lines.append(f"add element {family} {table} {set_name} {{ {quoted} }}")
    return "\n".join(lines) + "\n"


def sync_once(cgroup_root, slice_rel, pattern, nft_bin, family, table, set_name, force=False):
    for attempt in range(2):
        desired = find_vm_cgroups(cgroup_root, slice_rel, pattern)
        if not force:
            try:
                current = read_nft_set(nft_bin, family, table, set_name)
                if current == desired:
                    return desired
            except (subprocess.CalledProcessError, json.JSONDecodeError):
                pass
        existing = [
            elem for elem in desired if os.path.isdir(os.path.join(cgroup_root, elem))
        ]
        script = build_nft_script(family, table, set_name, existing)
        proc = subprocess.run(
            [nft_bin, "-f", "-"],
            input=script,
            capture_output=True,
            text=True,
        )
        if proc.returncode == 0:
            return existing
        if attempt == 0 and "No such file or directory" in proc.stderr:
            continue
        raise subprocess.CalledProcessError(
            proc.returncode, proc.args, output=proc.stdout, stderr=proc.stderr
        )
    return []


def parse_extra_set(spec):
    if "=" not in spec:
        raise argparse.ArgumentTypeError(
            f"Expected SET_NAME=REGEX in --extra-set, got {spec!r}"
        )
    set_name, raw_pattern = spec.split("=", 1)
    if not set_name or not raw_pattern:
        raise argparse.ArgumentTypeError(
            f"Expected non-empty SET_NAME=REGEX in --extra-set, got {spec!r}"
        )
    return set_name, re.compile(raw_pattern)


def sync_targets(cgroup_root, slice_rel, targets, nft_bin, family, table, force=False):
    results = {}
    for set_name, pattern in targets:
        results[set_name] = sync_once(
            cgroup_root,
            slice_rel,
            pattern,
            nft_bin,
            family,
            table,
            set_name,
            force=force,
        )
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cgroup-root", default="/sys/fs/cgroup")
    parser.add_argument("--user", default="mirin")
    parser.add_argument("--slice-rel", default="")
    parser.add_argument(
        "--pattern", default=r"^(coding-vm|audit-vm)-qemu-.*\.service$"
    )
    parser.add_argument("--family", default="inet")
    parser.add_argument("--table", default="ts-priority")
    parser.add_argument("--set", dest="set_name", default="vm_cgroups")
    parser.add_argument(
        "--extra-set",
        dest="extra_sets",
        action="append",
        default=[],
        type=parse_extra_set,
        help="Additional SET_NAME=REGEX target to sync within the same slice",
    )
    parser.add_argument("--nft", default="nft")
    parser.add_argument("--interval", type=float, default=5.0)
    parser.add_argument("--once", action="store_true")
    args = parser.parse_args()

    slice_rel = args.slice_rel or default_slice_rel(args.user)
    targets = [(args.set_name, re.compile(args.pattern)), *args.extra_sets]

    if args.once:
        sync_targets(
            args.cgroup_root,
            slice_rel,
            targets,
            args.nft,
            args.family,
            args.table,
            force=True,
        )
        return

    running = True

    def stop(_signum, _frame):
        nonlocal running
        running = False

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    inotify = Inotify()
    poller = select.poll()
    poller.register(inotify.fd, select.POLLIN)
    watched_path = None
    watched_is_slice = False

    try:
        sync_targets(
            args.cgroup_root,
            slice_rel,
            targets,
            args.nft,
            args.family,
            args.table,
            force=True,
        )
        while running:
            watch_target, is_slice = deepest_existing_path(args.cgroup_root, slice_rel)
            if watch_target != watched_path or is_slice != watched_is_slice:
                try:
                    inotify.set_watch(
                        watch_target, SLICE_MASK if is_slice else ANCESTOR_MASK
                    )
                    watched_path = watch_target
                    watched_is_slice = is_slice
                except OSError as exc:
                    print(
                        f"Failed to watch {watch_target}: {exc}",
                        file=sys.stderr,
                        flush=True,
                    )
                    watched_path = None

            events = poller.poll(int(args.interval * 1000))
            if not running:
                break
            if events:
                inotify.drain()
                if watched_path and not os.path.isdir(watched_path):
                    watched_path = None
            try:
                sync_targets(
                    args.cgroup_root,
                    slice_rel,
                    targets,
                    args.nft,
                    args.family,
                    args.table,
                    force=False,
                )
            except subprocess.CalledProcessError as exc:
                print(
                    f"nft sync failed: {exc.stderr.strip() or exc}",
                    file=sys.stderr,
                    flush=True,
                )
    finally:
        inotify.close()


if __name__ == "__main__":
    main()
