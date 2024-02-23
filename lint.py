import os
import subprocess

IGNORE = (
    "addons",
)

for file in os.listdir(os.getcwd()):
    if os.path.isfile(file) and len(file.split(".")) == 1:
        continue

    if len(file.split(".")) != 1 and not file.endswith(".gd"):
        continue

    if file in IGNORE:
        continue

    try:
        subprocess.run(f"gdlint {file}", shell=True, check=True)
    except subprocess.CalledProcessError as e:
        exit(1)
