#!/usr/bin/env bash

set -Eeuo pipefail

# Get the full path to this bash script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename "${BASH_SOURCE[0]}") <concatenated_log_file>"
    exit 1
fi

RAW_DATA_FILE="$1"
PROJECT="$(basename "$1" | cut -f 1 -d '-')"
INTERMEDIATE_OUTPUT_DIR="intermediate_output_${PROJECT}"
DATA_FILE="${INTERMEDIATE_OUTPUT_DIR}/all.log"
IP_FILE="${INTERMEDIATE_OUTPUT_DIR}/ips.txt"
GEO_FILE="${INTERMEDIATE_OUTPUT_DIR}/geolocations.csv"
DATABASE="${SCRIPT_DIR}/../database/IP2LOCATION-LITE-DB5.BIN"
PYTHON_SCRIPT="${SCRIPT_DIR}/get_ip_adresses.py"

# Check if input files exist
if [[ ! -f "${RAW_DATA_FILE}" ]]; then
    echo "Error: Input file ${RAW_DATA_FILE} does not exist."
    exit 1
fi

if [[ "${PROJECT}" != "seqan" && "${PROJECT}" != "openms" ]]; then
    echo "Error: Input file name should start with \"openms-\" or \"seqan-\""
    exit 1
fi

if [[ ! -f "${DATABASE}" ]]; then
    echo "Error: Database file ${DATABASE} does not exist."
    exit 1
fi

if [[ ! -f "${PYTHON_SCRIPT}" ]]; then
    echo "Error: Python script ${PYTHON_SCRIPT} does not exist."
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "${INTERMEDIATE_OUTPUT_DIR}"

# Check if input file has content
LINES=$(wc -l < "${RAW_DATA_FILE}")
if [[ "${LINES}" -eq "0" ]]; then
    echo "Error: ${RAW_DATA_FILE} is empty."
    exit 1
fi

echo "--- Lines to process: ${LINES}."

echo "--- Start formatting of the log files into a table format"
echo -e "calls\tdate\tip\tapp\tversion\tcpu\tos\twho\tclustered" > "${DATA_FILE}"

# List of terms to exclude
EXCLUDED_TERMS="test_version_check program_full_options empty_options default myApp test_parser"
EXCLUDE_PATTERN=${EXCLUDED_TERMS// /|}

# Process log file - breaking down the pipeline into more readable parts
gawk '!/'"${EXCLUDE_PATTERN}"'/' "${RAW_DATA_FILE}" | \
    sed -rn 's;(^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\s.*\[([0-9]+)/([a-zA-Z]+)/([0-9]+)\:[0-9]+\:[0-9]+\:[0-9]+.*\] \"GET /check/([^_]+|[^_]+_[a-zA-Z]+)_([a-zA-Z]+)_([0-9]+)_([a-zA-Z0-9_]+)_([0-9]+\.[0-9]+\.[0-9]+).*;\4-\3-\2\t\1\t\8\t\9\t\7\t\6\t\5;p' | \
    sort -n | \
    uniq | \
    sed 's/\(.*\)/1\t\1/' | \
    gawk ' BEGIN {OFS="\t"} {
        split($3,IP,".",seps);
        if ($2==PREV_DATE && $4==PREV_APP && $5==PREV_VERSION && IP[1]==PREV_IP[1] && IP[2]==PREV_IP[2])
            print $0,1;
        else
            print $0,0;
        PREV_DATE=$2;
        PREV_APP=$4;
        PREV_VERSION=$5;
        split($3,PREV_IP,".",seps);
    }' >> "${DATA_FILE}"

if [[ "${PROJECT}" == "seqan" ]]; then
    sed -i 's@linux@Linux@' "${DATA_FILE}"
    sed -i 's@macos@MacOS@' "${DATA_FILE}"
    sed -i 's@windows@Windows@' "${DATA_FILE}"
fi

# Extract unique IP addresses
echo "--- Writing unique IP addresses into ${IP_FILE}"
tail -n +2 "${DATA_FILE}" | cut -f 3 | sort -n | uniq > "${IP_FILE}"

# Get geolocation data
echo "--- Getting geolocation from local database for $(wc -l < "${IP_FILE}") unique IP addresses."
if ! "${PYTHON_SCRIPT}" "${IP_FILE}" "${GEO_FILE}" "${DATABASE}"; then
    echo "Error: Failed to get geolocation data."
    exit 1
fi

echo "--- Tracked $(wc -l < "${GEO_FILE}") geolocations."
echo "--- Done. Intermediate output files are in ${INTERMEDIATE_OUTPUT_DIR}."
