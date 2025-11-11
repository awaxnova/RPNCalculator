import os, subprocess, datetime
from pathlib import Path

def git(cmd):
    try: return subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL).decode().strip()
    except Exception: return "nogit"

root = Path(os.getcwd()); (root/"include").mkdir(exist_ok=True)
ver = git("git describe --tags --always")
branch = git("git rev-parse --abbrev-ref HEAD")
dt = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
(root/"include"/"version_auto.h").write_text(
    f"#pragma once\n#define FW_VERSION \"{ver}\"\n#define FW_BRANCH \"{branch}\"\n#define FW_BUILD_UTC \"{dt}\"\n",
    encoding="utf-8"
)
