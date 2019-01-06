#!/usr/bin/env python
# -*- coding: utf-8 -*-

import subprocess
import pytest
import os
import time
import pynvim

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

    """TestDemoPlugin.
    This test suite forces the bootstrap of the plugin
    by directly calling the plugin binary.
    """

    def test_is_running(self, spawn_demoplugin):
        pid = spawn_demoplugin

        f_log = os.environ.get("NVIMHOST_LOG_FILE")
        assert os.path.exists(f_log)
        assert pid

    def test_manifest_exists(self, spawn_demoplugin):
        """Make sure the plugin is generating the manifest vim file."""
        manifest_file = "~/.config/nvim/settings/demo-plugin.vim"
        assert os.path.exists(os.path.expanduser(manifest_file))

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


@pytest.fixture(scope="session")
def get_nvim():

    nvim_addr = os.environ.get("NVIM_LISTEN_ADDRESS")
    assert nvim_addr
    nvim = pynvim.attach("socket", path=nvim_addr)
    assert nvim
    return nvim


class TestDemoPluginFunctions(object):

    """
    TestDemoPluginFunctions.
    This test suite tests all demo-plugin funtions by leveraging pynvim
    official client (since it's super stable).
    """

    def test_greet(self, get_nvim):
        """Test demo-plugin Greet function."""
        nvim = get_nvim
        res = nvim.command_output("echo Greet('D')")
        assert res == "Hello D"

    def test_greet_wrong_args(self, get_nvim):
        """Test demo-plugin Greet function."""
        nvim = get_nvim
        with pytest.raises(pynvim.api.nvim.NvimError) as exc:
            nvim.command_output("echo Greet(1)")
            assert "Wrong function argument types" in str(exc.value)

    def test_sum_begin_to_end(self, get_nvim):
        """Test demo-plugin SumBeginToEnd function."""
        nvim = get_nvim
        res = nvim.command_output("echo SumBeginToEnd(0, 10)")
        assert res == str(sum(range(0, 10)))

    def test_set_var_value_sync(self, get_nvim):
        """Test demo-plugin SetVarValueSync function."""
        nvim = get_nvim
        nvim.command("call SetVarValueSync(555)")
        res = nvim.command_output("echo g:test_var_value")
        assert res == "555"

    def test_set_var_value_async(self, get_nvim):
        """Test demo-plugin SetVarValueAsync function."""
        nvim = get_nvim
        nvim.command("call SetVarValueAsync(56)")
        res = nvim.command_output("echo g:testasync_var_value")
        assert res == "56"
