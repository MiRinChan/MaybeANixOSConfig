#!/usr/bin/env python3
"""Tests for vm-cgroup-nft-sync.py."""

import importlib.util
from pathlib import Path
import re
import subprocess
import tempfile
import unittest
from unittest import mock

SPEC = importlib.util.spec_from_file_location(
    "vm_cgroup_nft_sync",
    Path(__file__).with_name("vm-cgroup-nft-sync.py"),
)
SYNC = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SYNC)


class VmCgroupNftSyncTests(unittest.TestCase):
    def test_find_vm_cgroups_filters_and_sorts(self):
        with tempfile.TemporaryDirectory() as tmp:
            slice_rel = "user.slice/user-1000.slice/user@1000.service/app.slice"
            slice_dir = Path(tmp) / slice_rel
            slice_dir.mkdir(parents=True)
            for name in [
                "coding-vm-qemu-200.service",
                "audit-vm-qemu-100.service",
                "firefox.service",
                "coding-vm-helper.service",
            ]:
                (slice_dir / name).mkdir()
            (slice_dir / "coding-vm-qemu-999.service").write_text("not a dir\n")

            pattern = re.compile(r"^(coding-vm|audit-vm)-qemu-.*\.service$")
            found = SYNC.find_vm_cgroups(tmp, slice_rel, pattern)
            self.assertEqual(
                found,
                [
                    f"{slice_rel}/audit-vm-qemu-100.service",
                    f"{slice_rel}/coding-vm-qemu-200.service",
                ],
            )

    def test_deepest_existing_path_falls_back_to_existing_ancestor(self):
        with tempfile.TemporaryDirectory() as tmp:
            slice_rel = "user.slice/user-1000.slice/user@1000.service/app.slice"
            existing = Path(tmp) / "user.slice"
            existing.mkdir()
            path, is_slice = SYNC.deepest_existing_path(tmp, slice_rel)
            self.assertEqual(path, str(existing))
            self.assertFalse(is_slice)

            (Path(tmp) / slice_rel).mkdir(parents=True)
            path, is_slice = SYNC.deepest_existing_path(tmp, slice_rel)
            self.assertEqual(path, str(Path(tmp) / slice_rel))
            self.assertTrue(is_slice)

    def test_build_nft_script(self):
        self.assertEqual(
            SYNC.build_nft_script("inet", "ts-priority", "vm_cgroups", []),
            "flush set inet ts-priority vm_cgroups\n",
        )
        self.assertEqual(
            SYNC.build_nft_script(
                "inet",
                "ts-priority",
                "vm_cgroups",
                ["user.slice/coding-vm-qemu-1.service"],
            ),
            (
                "flush set inet ts-priority vm_cgroups\n"
                'add element inet ts-priority vm_cgroups { "user.slice/coding-vm-qemu-1.service" }\n'
            ),
        )

    def test_sync_once_skips_when_already_matching(self):
        with tempfile.TemporaryDirectory() as tmp:
            slice_rel = "user.slice/app.slice"
            cg_name = "coding-vm-qemu-42.service"
            (Path(tmp) / slice_rel / cg_name).mkdir(parents=True)
            pattern = re.compile(r"^(coding-vm|audit-vm)-qemu-.*\.service$")
            with (
                mock.patch.object(
                    SYNC, "read_nft_set", return_value=[f"{slice_rel}/{cg_name}"]
                ),
                mock.patch.object(subprocess, "run") as run_mock,
            ):
                result = SYNC.sync_once(
                    tmp, slice_rel, pattern, "nft", "inet", "ts-priority", "vm_cgroups"
                )
            self.assertEqual(result, [f"{slice_rel}/{cg_name}"])
            run_mock.assert_not_called()

    def test_sync_once_retries_on_disappearing_cgroup(self):
        with tempfile.TemporaryDirectory() as tmp:
            slice_rel = "user.slice/app.slice"
            slice_dir = Path(tmp) / slice_rel
            slice_dir.mkdir(parents=True)
            vanished = slice_dir / "coding-vm-qemu-1.service"
            kept = slice_dir / "audit-vm-qemu-2.service"
            vanished.mkdir()
            kept.mkdir()
            pattern = re.compile(r"^(coding-vm|audit-vm)-qemu-.*\.service$")

            calls = []

            def fake_run(args, input=None, **_kwargs):
                calls.append(input)
                if len(calls) == 1:
                    vanished.rmdir()
                    return subprocess.CompletedProcess(
                        args, 1, stdout="", stderr="Error: No such file or directory\n"
                    )
                return subprocess.CompletedProcess(args, 0, stdout="", stderr="")

            with (
                mock.patch.object(SYNC, "read_nft_set", return_value=[]),
                mock.patch.object(subprocess, "run", side_effect=fake_run),
            ):
                result = SYNC.sync_once(
                    tmp, slice_rel, pattern, "nft", "inet", "ts-priority", "vm_cgroups"
                )
            self.assertEqual(result, [f"{slice_rel}/audit-vm-qemu-2.service"])
            self.assertEqual(len(calls), 2)


if __name__ == "__main__":
    unittest.main()
