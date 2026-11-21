
#
# generate_stress_test.py
# NMSBaseBuilder
#
# Created by Zach Baron on 11/21/26.
#

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODELS = Path("/Users/instinct/nms-base-builder/ConvertedModels")
CATALOG = ROOT / "NMSParts.json"
OUTPUT = ROOT / "StressTests"

COUNTS = [250, 1000, 3000]
SPACING = 5.0
COLUMNS = 50

OUTPUT.mkdir(exist_ok=True)

with CATALOG.open(encoding="utf-8") as file:
    catalog = json.load(file)

# Find catalog entries with converted USDZ models.
available_parts = []

for part in catalog:
    mesh_path = part.get("meshPath")

    if not mesh_path:
        continue

    usdz_path = (MODELS / mesh_path).with_suffix(".usdz")

    if usdz_path.is_file():
        available_parts.append(part)

print("Catalog:", CATALOG)
print("Models:", MODELS)
print("Converted models found:", len(available_parts))

if not available_parts:
    raise RuntimeError(
        "No converted USDZ models found. "
        "Check meshPath values and ConvertedModels."
    )

# Choose a small model for repeated-mesh testing.
preferred_id = "^C_WALL_Q_H"

repeated_part = next(
    (
        part
        for part in available_parts
        if part.get("objectID") == preferred_id
    ),
    available_parts[0]
)

print("Repeated model:", repeated_part.get("objectID"))


def make_project(count, varied):
    objects = []
    rows = math.ceil(count / COLUMNS)

    for index in range(count):
        part = (
            available_parts[index % len(available_parts)]
            if varied
            else repeated_part
        )

        column = index % COLUMNS
        row = index // COLUMNS

        x = (column - (COLUMNS - 1) / 2) * SPACING
        z = (row - (rows - 1) / 2) * SPACING

        objects.append({
            "ObjectID": part["objectID"],
            "Position": [float(x), 0.0, float(z)],
            "Up": [0.0, 1.0, 0.0],
            "At": [0.0, 0.0, 1.0],
            "Timestamp": 0,
            "UserData": 0
        })

    return {
        "BaseVersion": 8,
        "Objects": objects
    }


for count in COUNTS:
    for varied in (False, True):
        kind = "varied" if varied else "repeated"

        filename = f"stress_{count}_{kind}.json"
        path = OUTPUT / filename

        project = make_project(count, varied)

        with path.open("w", encoding="utf-8") as file:
            json.dump(project, file, indent=2)

        unique_ids = len({
            part["ObjectID"]
            for part in project["Objects"]
        })

        print(
            f"{filename}: "
            f"{count} parts, "
            f"{unique_ids} unique IDs"
        )

print("\nStress-test fixtures generated.")
