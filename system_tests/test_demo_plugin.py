#!/usr/bin/env python
# -*- coding: utf-8 -*-

import subprocess
import pytest
import os
import time

# mock nvim in a new address in cas you're already running in your machine
nvim_test_addr = "/tmp/nvim_test_addr"
os.environ.setdefault("NVIM_LISTEN_ADDRESS", nvim_test_addr)


class PluginLog(object):

    """Abstract plugin log functionalities"""

    def __init__(self, log_file: str) -> None:
        """Constructor of  PluginLog."""
        self.log_file = log_file

    def match_line(self, line: str) -> bool:
        """Match a str line in the log file."""
        if not line:
            return False

        with open(self.log_file) as f:
            for read_line in f.readlines():
                if line in read_line:
                    return True
        return False


@pytest.fixture(scope="session")
def spawn_demoplugin() -> int:
    """Force the bootstrap of the plugin for testing purposes."""

    spawn_nvim()
    assert os.environ.get("NVIM_LISTEN_ADDRESS")

    popen = subprocess.Popen(
        ["demo-plugin"],
        shell=True,
        universal_newlines=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    time.sleep(0.3)
    return popen.pid


def spawn_nvim():
    """Spawn nvim in background."""
    popen = subprocess.Popen(
        ["nvim", "--headless", "--listen", nvim_test_addr, "&"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
        shell=True,
    )
    time.sleep(0.5)
    assert popen.pid


class TestDemoPluginBootstrap(object):

    """TestDemoPlugin. """

    def test_is_running(self, spawn_demoplugin):
        pid = spawn_demoplugin

        f_log = os.environ.get("NVIMHOST_LOG_FILE")
        assert os.path.exists(f_log)
        assert pid

    def test_started(self, spawn_demoplugin):
        """Check if the plugin properly started."""
        f_log = os.environ.get("NVIMHOST_LOG_FILE")
        pl = PluginLog(f_log)
        lines = [
            "Main thread connected to nvim",
            "cbThread ready",
            "Setting g:demoplugin_channel",
            "Plugin demoplugin is ready",
        ]
        for line in lines:
            assert pl.match_line(line)

    def test_kill(self, spawn_demoplugin):
        pid = spawn_demoplugin
        assert pid
        out = subprocess.check_output(
            ["kill " + str(pid)],
            shell=True,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
        )
        f_log = os.environ.get("NVIMHOST_LOG_FILE")
        os.remove(f_log)
        assert not os.path.exists(f_log)
        assert not out
