#!/usr/bin/env bash
# Ubuntu 24.04 compositor package feasibility gate. Does NOT prove a graphical session.
set -Eeuo pipefail
source /etc/os-release
if [[ "$ID" != ubuntu || "$VERSION_ID" != "24.04" ]]; then
  echo "Requires Ubuntu 24.04, got ${PRETTY_NAME:-unknown}" >&2
  exit 2
fi
mkdir -p out
echo "Ubuntu package dependency feasibility (NOT a GUI test)" | tee out/package-probe.log
apt-get update -qq
for compositor in labwc wayfire sway; do
  printf '\n--- %s ---\n' "$compositor" | tee -a out/package-probe.log
  apt-cache policy "$compositor" | tee -a out/package-probe.log
  if apt-get -s install --no-install-recommends "$compositor" > "out/${compositor}-apt-simulate.log" 2>&1; then
    echo "$compositor: installable (APT simulation)" | tee -a out/package-probe.log
  else
    echo "$compositor: APT dependency solver failed; inspect out/${compositor}-apt-simulate.log" | tee -a out/package-probe.log
  fi
done
# Fail if our known baseline itself cannot be installed. An alternate candidate may be unavailable.
apt-get -s install --no-install-recommends labwc >/dev/null
