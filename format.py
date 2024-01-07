import os
import subprocess

IGNORE = (
    "addons",
)

for file in os.listdir(os.getcwd()):
    if len(file.split(".")) != 1 and not file.endswith(".gd"):
        continue

    if file in IGNORE:
        continue

    try:
        subprocess.run(f"gdformat --check {file}", shell=True, check=True)
    except subprocess.CalledProcessError as e:
        exit(1)
