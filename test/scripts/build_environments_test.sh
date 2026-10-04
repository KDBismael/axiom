#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

python3 - "$repo_root" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])

expected = {
    "development": {
        "API_BASE_URL": "https://dev-server.ndeli.tech",
        "AXIOM_PAYINS_ENABLED": "false",
        "AXIOM_PAYMENT_ENV": "disabled",
        "AXIOM_GENIUSPAY_SANDBOX_VERIFIED": "false",
    },
    "production": {
        "API_BASE_URL": "https://server.ndeli.tech",
        "AXIOM_PAYINS_ENABLED": "false",
        "AXIOM_PAYMENT_ENV": "disabled",
        "AXIOM_GENIUSPAY_SANDBOX_VERIFIED": "false",
    },
}

configs = {}
for environment, required_values in expected.items():
    path = root / "config" / f"{environment}.json"
    configs[environment] = json.loads(path.read_text())
    for key, value in required_values.items():
        actual = configs[environment].get(key)
        assert actual == value, f"{path}: {key}={actual!r}, attendu {value!r}"

assert configs["development"]["API_BASE_URL"] != configs["production"]["API_BASE_URL"]

for script_name, environment in {
    "run_dev.sh": "development",
    "build_dev_apk.sh": "development",
    "build_dev_ipa.sh": "development",
    "build_prod_aab.sh": "production",
    "build_prod_ipa.sh": "production",
}.items():
    script = (root / "scripts" / script_name).read_text()
    expected_argument = f"--dart-define-from-file=config/{environment}.json"
    assert expected_argument in script, f"{script_name} doit utiliser {expected_argument}"

print("Configurations development/production valides")
PY
