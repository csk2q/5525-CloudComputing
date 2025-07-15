import os
import shlex
import subprocess

StrOrBytesPath = str | bytes | os.PathLike[str] | os.PathLike[bytes]
def run(command: str, workDir: StrOrBytesPath | None = None) -> subprocess.CompletedProcess[str]:
    args = shlex.split(command)
    return subprocess.run(args=args, capture_output=True, text=True, cwd=workDir)

if __name__ == '__main__':
    print(run("echo TEST").stdout)

