#!/bin/bash

# Colored variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# PVS-Studio-Free Header
PVS_STUDIO_HEADER="// This is a personal academic project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++, C#, and Java: https://pvs-studio.com
"

# Files for recording errors
PVS_ERROR_LOG_FILE="pvs_studio_error_files.txt"

# Function to add header to Java files
add_header_to_files() {
    local directory=$1
    find "$directory" -name "*.java" | while read -r file; do
        if ! head -n 2 "$file" | grep -q "PVS-Studio Static Code Analyzer"; then
            { echo -e "$PVS_STUDIO_HEADER"; cat "$file"; } > "$file.tmp" && mv "$file.tmp" "$file"
        fi
    done
}

# Function to check the execution of the analysis
check_analysis_result() {
    local status=$1
    local output=$2
    local directory=$3
    local error_log_file=$4
    local analyzer_name=$5

    # Check if the output contains a NullPointerException
    if [[ "$output" =~ "java.lang.NullPointerException" ]]; then
        echo -e "${YELLOW}[$analyzer_name] Can not be started for $directory${NC}"

        # Check if the error log file exists
        if [ -f "$error_log_file" ]; then
            # Check if the directory is already in the error log
            if grep -Fxq "$directory" "$error_log_file"; then
                # Remove the directory from the error log
                sed -i "\|^$directory\$|d" "$error_log_file"
            fi
        fi

    # Check if the analysis was successful
    elif [[ $status -eq 0 && ! "$output" =~ "timeout" && ! "$output" =~ "error" ]]; then
        echo -e "${GREEN}[$analyzer_name] Completed successfully for $directory${NC}"

        # Check if the error log file exists
        if [ -f "$error_log_file" ]; then
            # Check if the directory is already in the error log
            if grep -Fxq "$directory" "$error_log_file"; then
                # Remove the directory from the error log
                sed -i "\|^$directory\$|d" "$error_log_file"
            fi
        fi

    else
        # Print a failure message
        echo -e "${RED}[$analyzer_name] Failed for $directory${NC}"
        echo -e "${YELLOW}$output${NC}"
        # Check if the directory is not in the error log
        if ! grep -Fxq "$directory" "$error_log_file"; then
            # Add the directory to the error log
            echo "$directory" >> "$error_log_file"
        fi
    fi
}

# Function for launching PVS-Studio
run_pvs_studio() {

    while [ $(jobs -rp | wc -l) -ge $MAX_CONCURRENT_JOBS ]; do
            sleep 1
        done

    local directory=$1
    if [ ! -f "$directory/PVS-Studio.json" ]; then
        add_header_to_files "$directory"
        
        output=$(java -jar "$PVS_STUDIO_JAR_PATH" \
            -s "$directory" \
            -j4 \
            -o "$directory/PVS-Studio.json" \
            --user-name "narezfivenew@mail.ru" \
            --license-key "0HH0-5QY5-2EAH-7785" 2>&1)
        
        check_analysis_result $? "$output" "$directory" "$PVS_ERROR_LOG_FILE" "PVS"
    fi
}

# Function for processing one directory
process_directory() {
    local hash_folder=$1
    local hash_path="$HASH_PAIRS_DIR/$hash_folder"
    
    if [ -d "$hash_path" ]; then
        local prev_path="$hash_path/prev"
        local curr_path="$hash_path/curr"
        
        if [ -d "$prev_path" ]; then
            echo -e "${BLUE}Running on $hash_folder - prev version${NC}"
            run_pvs_studio "$prev_path"
        fi
        if [ -d "$curr_path" ]; then
            echo -e "${BLUE}Running on $hash_folder - curr version${NC}"
            run_pvs_studio "$curr_path"
        fi
    fi
}

# Function to re-run analysis for files with errors
re_run_failed_analysis() {
    local error_log_file=$1
    local analysis_function=$2

    if [ -f "$error_log_file" ]; then
        error_directories=$(cat "$error_log_file")
        if [ -s "$error_log_file" ]; then
            echo -e "${YELLOW}Re-running analysis for directories in $error_log_file${NC}"
            for error_directory in $error_directories; do
                $analysis_function "$error_directory" &
                wait
            done
        fi
    fi
}

# Function to terminate all background processes when receiving SIGINT signal
cleanup() {
    echo -e "${YELLOW}Received SIGINT, terminating background processes...${NC}"
    pkill -P $$
    wait
    exit 1
}

# Основная функция
main() {
    local PVS_STUDIO_JAR_PATH=""
    local HASH_PAIRS_DIR=""
    local MAX_CONCURRENT_JOBS=4

    # Parsing command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --pvs)
                PVS_STUDIO_JAR_PATH="$2"
                shift 2
                ;;
            --dir)
                HASH_PAIRS_DIR="$2"
                shift 2
                ;;
            --max-jobs)
                MAX_CONCURRENT_JOBS="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                exit 1
                ;;
        esac
    done

    # Checking for all required parameters
    if [[ -z "$PVS_STUDIO_JAR_PATH" || -z "$HASH_PAIRS_DIR" ]]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo "Usage: $0 --pvs <PVS_STUDIO_JAR_PATH> --dir <HASH_PAIRS_DIR> [--max-jobs <MAX_CONCURRENT_JOBS>]"
        exit 1
    elif [ ! -f "$PVS_STUDIO_JAR_PATH" ]; then
        echo -e "${RED}Error: PVS-Studio JAR file not found at $PVS_STUDIO_JAR_PATH${NC}"
        exit 1
    elif [ ! -d "$HASH_PAIRS_DIR" ]; then
        echo -e "${RED}Error: Hash pairs directory not found at $HASH_PAIRS_DIR${NC}"
        exit 1
    fi

    # Installing a SIGINT signal handler
    trap cleanup SIGINT

    # Get a list of hashes
    hash_folders=$(ls "$HASH_PAIRS_DIR")

    for hash_folder in $hash_folders; do
        process_directory "$hash_folder" &
    done

    wait
    re_run_failed_analysis "$PVS_ERROR_LOG_FILE" run_pvs_studio
    wait

    echo -e "Job completed!"
}

main "$@"
