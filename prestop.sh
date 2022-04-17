#!/bin/bash
set -x
kill -9 `pgrep ssserver`
kill -9 `pgrep server_linux_amd64`
kill -9 `pgrep speederv2_amd64`
kill -9 `pgrep udp2raw_amd64`
