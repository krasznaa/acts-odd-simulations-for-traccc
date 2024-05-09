#!/bin/bash
#
# Script for launching a set of ODD simulation jobs for traccc
# performance measurements, with the help of another python script.
#

# Stop on errors.
set -e

# Figure out the directory that this script is in.
SCRIPT_DIR=$(dirname ${BASH_SOURCE[0]})
SCRIPT_DIR=$(\cd ${SCRIPT_DIR};\pwd)

# Default script arguments.
ACTS_SOURCE_DIR="./acts"
ACTS_BUILD_DIR="./build"
OUTPUT_DIR="./output"

# Helper function for printing usage information for the script.
usage() {
    echo "Script for launching ODD simulations for traccc using the"
    echo "ghcr.io/acts-project/ubuntu2204:v41 Docker image."
    echo ""
    echo "Usage: ${BASH_SOURCE[0]} [options]"
    echo "Options:"
    echo "  -h/--help:      Print this message."
    echo ""
    echo "  -a/--acts-dir:   Directory with the Acts sources"
    echo "                   [${ACTS_SOURCE_DIR}]"
    echo "  -b/--build-dir:  Build directory for Acts"
    echo "                   [${ACTS_BUILD_DIR}]"
	 echo "  -o/--output-dir: Output directory for the simulation results"
	 echo "                   [${OUTPUT_DIR}]"
    echo ""
}

# Parse the command line argument(s).
while [[ $# > 0 ]]
do
    case $1 in
	-a|--acts-dir)
	    ACTS_SOURCE_DIR=$2
	    shift
	    ;;
	-b|--build-dir)
	    ACTS_BUILD_DIR=$2
	    shift
	    ;;
	-o|--output-dir)
	    OUTPUT_DIR=$2
	    shift
	    ;;
	-h|--help)
	    usage
	    exit 0
	    ;;
	*)
	    echo "ERROR: Unknown argument: $1"
	    echo ""
	    usage
	    exit 1
	    ;;
    esac
    shift
done

# Check if the Acts directory exists.
if [ ! -d "${ACTS_SOURCE_DIR}" ]
then
    echo "ERROR: Acts directory (${ACTS_SOURCE_DIR}) not found"
    exit 1
fi

# Check if the build directory exists. If not, make it.
if [ ! -d "${ACTS_BUILD_DIR}" ]
then
    cmake -G Ninja \
	  -DCMAKE_BUILD_TYPE=Release \
	  -DCMAKE_CXX_STANDARD=17 \
	  -DACTS_ENABLE_LOG_FAILURE_THRESHOLD=ON \
	  -DACTS_BUILD_EVERYTHING=ON \
	  -DACTS_BUILD_ODD=ON \
	  -DACTS_BUILD_EXAMPLES_PYTHON_BINDINGS=ON \
	  -S "${ACTS_SOURCE_DIR}" \
	  -B "${ACTS_BUILD_DIR}"
    cmake --build "${ACTS_BUILD_DIR}"
fi

# Set up the environment from the build directory.
source "${ACTS_BUILD_DIR}/this_acts.sh"
source "${ACTS_BUILD_DIR}/python/setup.sh"

# Make sure that the Geant4 datasets are downloaded.
geant4-config --install-datasets

# Launch the python script that runs the ODD simulations.
"${SCRIPT_DIR}/run_odd_simulations.py" \
	--acts-dir "${ACTS_SOURCE_DIR}" \
	--output-dir "${OUTPUT_DIR}"
