#!/bin/bash
set -e

# Compute this run's p95 (parent transactions only, matching what we did in PowerShell earlier)
this_p95=$(tail -n +2 result1.jtl | awk -F',' '{print $2}' | sort -n | awk '
  { a[NR]=$1 }
  END {
    idx = int(NR * 0.95)
    if (idx < 1) idx = 1
    print a[idx]
  }')

echo "This run p95: ${this_p95}ms"

if [ -f baseline.json ]; then
  baseline_p95=$(jq '.p95_ms' baseline.json)
  echo "Baseline p95: ${baseline_p95}ms"

  # Regression = more than 20% worse than baseline
  limit=$(( baseline_p95 * 120 / 100 ))
  if [ "$this_p95" -gt "$limit" ]; then
    echo "::error::Regression detected — p95 ${this_p95}ms is more than 20% worse than baseline ${baseline_p95}ms"
    exit 1
  fi
  echo "No regression — within 20% of baseline"
else
  echo "No baseline found yet — this run will become the baseline"
fi

# Save this run's numbers as the new baseline for next time
echo "{\"p95_ms\": $this_p95, \"run_number\": \"${GITHUB_RUN_NUMBER}\", \"date\": \"$(date -u +%Y-%m-%d)\"}" > baseline.json
