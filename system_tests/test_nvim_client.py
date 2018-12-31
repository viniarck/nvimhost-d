#!/usr/bin/env python
# -*- coding: utf-8 -*-

import subprocess
import glob
import os


def test_nvimd_client():
    cwd = os.getcwd()
    print(cwd)
    exe = glob.glob(cwd + "/nvimd-client", recursive=True)
    (out, err) = subprocess.Popen(
        exe[0],
        shell=True,
        universal_newlines=True,
        stderr=subprocess.PIPE,
        stdout=subprocess.PIPE,
    ).communicate()

    assert("buffer #1" in out)
