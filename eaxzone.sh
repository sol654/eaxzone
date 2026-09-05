#!/bin/bash

# ============================================================
# Domain Security Scanner - Professional AXFR Testing Tool
# Version: 2.0
# Author: Security Research Team
# Description: Automated NS lookup and AXFR zone transfer testing
# ============================================================

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
TIMEOUT=10
MAX_RETRIES=2
OUTPUT_DIR="scan_results_$(date +%Y%m%d_%H%M%S)"
THREADS=5  # Parallel processing

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Logging setup
LOG_FILE="$OUTPUT_DIR/scan.log"
MASTER_RESULT="$OUTPUT_DIR/master_report.txt"
NS_RESULT="$OUTPUT_DIR/ns_records.txt"
AXFR_RESULT="$OUTPUT_DIR/axfr_results.txt"
JSON_OUTPUT="$OUTPUT_DIR/results.json"
CSV_OUTPUT="$OUTPUT_DIR/results.csv"

# ============================================================
# Function: Display Banner
# ============================================================
banner() {
    echo -e "${BLUE}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║     DOMAIN SECURITY SCANNER - AXFR TESTING TOOL     ║"
    echo "║          Professional Zone Transfer Scanner         ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ============================================================
# Function: Display help
# ============================================================
show_help() {
    echo -e "${CYAN}${BOLD}USAGE:${NC}"
    echo "  $0 [OPTIONS] -f <domain_list_file>"
    echo ""
    echo -e "${CYAN}${BOLD}OPTIONS:${NC}"
    echo "  -f, --file FILE       Input file with domains/subdomains (one per line)"
    echo "  -o, --output DIR      Output directory (default: scan_results_<timestamp>)"
    echo "  -t, --timeout SEC     DNS timeout in seconds (default: 10)"
    echo "  -r, --retries NUM     Number of retries (default: 2)"
    echo "  -j, --json            Generate JSON output"
    echo "  -c, --csv             Generate CSV output"
    echo "  -q, --quiet           Quiet mode (minimal output)"
    echo "  -v, --verbose         Verbose mode"
    echo "  -h, --help            Show this help message"
    echo ""
    echo -e "${CYAN}${BOLD}EXAMPLES:${NC}"
    echo "  $0 -f domains.txt"
    echo "  $0 -f subdomains.txt -o my_scan -j -c"
    echo "  $0 -f domains.txt -t 15 -r 3 --json"
    echo ""
}

# ============================================================
# Function: Log messages
# ============================================================
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO") echo -e "${GREEN}[+]${NC} $message" ;;
        "WARN") echo -e "${YELLOW}[!]${NC} $message" ;;
        "ERROR") echo -e "${RED}[-]${NC} $message" ;;
        "DEBUG") [[ "$VERBOSE" == "true" ]] && echo -e "${CYAN}[*]${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}[✓]${NC} $message" ;;
        "FAIL") echo -e "${RED}[✗]${NC} $message" ;;
        *) echo "$message" ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# ============================================================
# Function: Validate domain format
# ============================================================
validate_domain() {
    local domain=$1
    # Basic domain validation
    if [[ ! "$domain" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        return 1
    fi
    # Check for empty or too short
    if [[ ${#domain} -lt 3 ]]; then
        return 1
    fi
    return 0
}

# ============================================================
# Function: Get NS records
# ============================================================
get_ns_records() {
    local domain=$1
    local ns_list=""
    local retry=0
    
    while [[ $retry -lt $MAX_RETRIES ]]; do
        ns_list=$(dig ns "$domain" +short +timeout=$TIMEOUT 2>/dev/null | \
                  grep -v '^$' | \
                  head -10 | \
                  tr '\n' ',' | \
                  sed 's/,$//')
        
        if [[ -n "$ns_list" ]]; then
            echo "$ns_list"
            return 0
        fi
        ((retry++))
        sleep 1
    done
    
    echo "NO_NS_RECORDS"
    return 1
}

# ============================================================
# Function: Test AXFR on a nameserver
# ============================================================
test_axfr() {
    local domain=$1
    local ns=$2
    local result=""
    
    # Clean the nameserver (remove trailing dot if present)
    ns=$(echo "$ns" | sed 's/\.$//')
    
    log "DEBUG" "Testing AXFR for $domain on NS: $ns"
    
    # Perform AXFR request with timeout
    result=$(dig axfr "$domain" @"$ns" +noall +answer +timeout=$TIMEOUT 2>/dev/null)
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo "ERROR: Timeout or connection failed"
        return 1
    fi
    
    if [[ -z "$result" ]]; then
        echo "NO_RECORDS"
        return 2
    fi
    
    # Check for common error messages
    if echo "$result" | grep -qi "Transfer failed\|connection timed out\|no servers\|refused\|not authoritative"; then
        echo "REFUSED"
        return 3
    fi
    
    # Check if we got actual records
    if echo "$result" | grep -q "; <<>> DiG"; then
        # It's a successful response
        echo "$result"
        return 0
    else
        echo "NO_RECORDS"
        return 2
    fi
}

# ============================================================
# Function: Process single domain (called by parallel)
# ============================================================
process_domain() {
    local domain=$1
    local domain_file=$2
    local temp_dir=$3
    
    # Create temp file for this domain's results
    local temp_file="$temp_dir/${domain//[^a-zA-Z0-9]/_}.tmp"
    
    echo "Processing: $domain" | tee -a "$temp_file"
    
    # Step 1: Get NS records
    ns_records=$(get_ns_records "$domain")
    
    if [[ "$ns_records" == "NO_NS_RECORDS" || -z "$ns_records" ]]; then
        echo "FAIL|$domain|NO_NS|No nameservers found" >> "$temp_file"
        echo "$domain: No NS records found" >> "$NS_RESULT"
        return 1
    fi
    
    # Save NS records
    echo "$domain: $ns_records" >> "$NS_RESULT"
    
    # Step 2: Test AXFR on each nameserver
    local axfr_success=false
    IFS=',' read -ra ns_array <<< "$ns_records"
    
    for ns in "${ns_array[@]}"; do
        ns=$(echo "$ns" | xargs)  # Trim whitespace
        [[ -z "$ns" ]] && continue
        
        echo "[*] Testing $domain on NS: $ns" | tee -a "$temp_file"
        
        axfr_result=$(test_axfr "$domain" "$ns")
        local result_code=$?
        
        case $result_code in
            0)
                # Successful AXFR
                echo "SUCCESS|$domain|$ns" >> "$temp_file"
                echo "    *** SUCCESS! Zone transfer successful on $ns ***" >> "$temp_file"
                echo "$axfr_result" | tee -a "$temp_file"
                axfr_success=true
                
                # Log to master result
                {
                    echo ""
                    echo "========================================"
                    echo "VULNERABLE: $domain"
                    echo "Nameserver: $ns"
                    echo "----------------------------------------"
                    echo "$axfr_result"
                    echo "========================================"
                } >> "$AXFR_RESULT"
                ;;
            1)
                echo "FAIL|$domain|$ns|Timeout" >> "$temp_file"
                echo "    - Connection timeout for $ns" >> "$temp_file"
                ;;
            2)
                echo "FAIL|$domain|$ns|NoRecords" >> "$temp_file"
                echo "    - No records returned (likely refused)" >> "$temp_file"
                ;;
            3)
                echo "FAIL|$domain|$ns|Refused" >> "$temp_file"
                echo "    - AXFR refused by $ns" >> "$temp_file"
                ;;
        esac
        echo "" >> "$temp_file"
    done
    
    # Summary for this domain
    if [[ "$axfr_success" == true ]]; then
        echo "STATUS|$domain|VULNERABLE" >> "$temp_file"
        echo -e "${RED}${BOLD}[!] VULNERABLE: $domain - Zone transfer possible!${NC}" | tee -a "$temp_file"
    else
        echo "STATUS|$domain|SECURE" >> "$temp_file"
        echo -e "${GREEN}[✓] SECURE: $domain - No zone transfer vulnerabilities found${NC}" | tee -a "$temp_file"
    fi
    
    echo "----------------------------------------" >> "$temp_file"
}

# ============================================================
# Function: Generate JSON report
# ============================================================
generate_json() {
    log "INFO" "Generating JSON report..."
    
    echo '{' > "$JSON_OUTPUT"
    echo '  "scan_info": {' >> "$JSON_OUTPUT"
    echo '    "timestamp": "'$(date -Iseconds)'",' >> "$JSON_OUTPUT"
    echo '    "tool": "Domain Security Scanner",' >> "$JSON_OUTPUT"
    echo '    "version": "2.0"' >> "$JSON_OUTPUT"
    echo '  },' >> "$JSON_OUTPUT"
    echo '  "results": [' >> "$JSON_OUTPUT"
    
    local first=true
    while IFS='|' read -r status domain ns records; do
        if [[ "$status" == "SUCCESS" ]]; then
            if [[ "$first" == true ]]; then
                first=false
            else
                echo ',' >> "$JSON_OUTPUT"
            fi
            echo '    {' >> "$JSON_OUTPUT"
            echo '      "domain": "'$domain'",' >> "$JSON_OUTPUT"
            echo '      "vulnerable": true,' >> "$JSON_OUTPUT"
            echo '      "nameserver": "'$ns'",' >> "$JSON_OUTPUT"
            echo '      "zone_transfer": "SUCCESS"' >> "$JSON_OUTPUT"
            echo -n '    }' >> "$JSON_OUTPUT"
        fi
    done < <(grep "^SUCCESS|" "$temp_dir"/*.tmp 2>/dev/null)
    
    echo '' >> "$JSON_OUTPUT"
    echo '  ]' >> "$JSON_OUTPUT"
    echo '}' >> "$JSON_OUTPUT"
    
    log "SUCCESS" "JSON report generated: $JSON_OUTPUT"
}

# ============================================================
# Function: Generate CSV report
# ============================================================
generate_csv() {
    log "INFO" "Generating CSV report..."
    
    echo "Domain,Nameserver,Vulnerable,ZoneTransfer" > "$CSV_OUTPUT"
    
    while IFS='|' read -r status domain ns records; do
        if [[ "$status" == "SUCCESS" ]]; then
            echo "$domain,$ns,Yes,Successful" >> "$CSV_OUTPUT"
        fi
    done < <(grep "^SUCCESS|" "$temp_dir"/*.tmp 2>/dev/null)
    
    # Add secure domains
    while IFS='|' read -r status domain; do
        if [[ "$status" == "STATUS" && "$domain" != "VULNERABLE" ]]; then
            echo "$domain,N/A,No,Not Tested" >> "$CSV_OUTPUT"
        fi
    done < <(grep "^STATUS|" "$temp_dir"/*.tmp 2>/dev/null | grep -v "VULNERABLE")
    
    log "SUCCESS" "CSV report generated: $CSV_OUTPUT"
}

# ============================================================
# Main function
# ============================================================
main() {
    # Initialize variables
    INPUT_FILE=""
    QUIET=false
    VERBOSE=false
    GENERATE_JSON=false
    GENERATE_CSV=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                INPUT_FILE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -r|--retries)
                MAX_RETRIES="$2"
                shift 2
                ;;
            -j|--json)
                GENERATE_JSON=true
                shift
                ;;
            -c|--csv)
                GENERATE_CSV=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                banner
                show_help
                exit 0
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Validate input
    if [[ -z "$INPUT_FILE" ]]; then
        log "ERROR" "No input file specified"
        show_help
        exit 1
    fi
    
    if [[ ! -f "$INPUT_FILE" ]]; then
        log "ERROR" "Input file not found: $INPUT_FILE"
        exit 1
    fi
    
    # Recreate output directory
    mkdir -p "$OUTPUT_DIR"
    temp_dir="$OUTPUT_DIR/temp"
    mkdir -p "$temp_dir"
    
    # Initialize result files
    echo "# Domain Security Scanner Results" > "$MASTER_RESULT"
    echo "# Scan started: $(date)" >> "$MASTER_RESULT"
    echo "=========================================" >> "$MASTER_RESULT"
    echo "" >> "$MASTER_RESULT"
    
    echo "# NS Records Found" > "$NS_RESULT"
    echo "# AXFR Test Results" > "$AXFR_RESULT"
    
    # Display banner if not quiet
    if [[ "$QUIET" == false ]]; then
        banner
        echo -e "${CYAN}${BOLD}Configuration:${NC}"
        echo "  Input file: $INPUT_FILE"
        echo "  Output dir: $OUTPUT_DIR"
        echo "  Timeout: ${TIMEOUT}s"
        echo "  Retries: $MAX_RETRIES"
        echo "  Parallel threads: $THREADS"
        echo ""
    fi
    
    # Count total domains
    total_domains=$(grep -v '^$' "$INPUT_FILE" | wc -l)
    log "INFO" "Processing $total_domains domains..."
    
    # Process domains
    processed=0
    vulnerabilities=0
    
    # Use temporary files for processing
    while IFS= read -r domain; do
        # Skip empty lines
        [[ -z "$domain" ]] && continue
        
        # Clean domain
        domain=$(echo "$domain" | xargs)
        
        # Validate domain
        if ! validate_domain "$domain"; then
            log "WARN" "Invalid domain format: $domain - Skipping"
            continue
        fi
        
        ((processed++))
        echo -ne "\r${CYAN}Progress: $processed/$total_domains${NC}" >&2
        
        # Process domain
        process_domain "$domain" "$INPUT_FILE" "$temp_dir" >> "$MASTER_RESULT"
        
        # Check if vulnerable
        if grep -q "^SUCCESS|" "$temp_dir/${domain//[^a-zA-Z0-9]/_}.tmp" 2>/dev/null; then
            ((vulnerabilities++))
        fi
        
    done < <(grep -v '^$' "$INPUT_FILE")
    
    echo -e "\n" >&2
    
    # Generate reports
    if [[ "$GENERATE_JSON" == true ]]; then
        generate_json
    fi
    
    if [[ "$GENERATE_CSV" == true ]]; then
        generate_csv
    fi
    
    # Final summary
    log "SUCCESS" "Scan completed!"
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}SCAN COMPLETE - SUMMARY${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────────${NC}"
    echo "  Total domains tested: $total_domains"
    echo "  Vulnerable domains: ${RED}$vulnerabilities${NC}"
    echo "  Secure domains: $((total_domains - vulnerabilities))"
    echo ""
    echo -e "${BOLD}Results saved in: ${CYAN}$OUTPUT_DIR/${NC}"
    echo "  - Master report: $MASTER_RESULT"
    echo "  - NS records: $NS_RESULT"
    echo "  - AXFR results: $AXFR_RESULT"
    if [[ "$GENERATE_JSON" == true ]]; then
        echo "  - JSON report: $JSON_OUTPUT"
    fi
    if [[ "$GENERATE_CSV" == true ]]; then
        echo "  - CSV report: $CSV_OUTPUT"
    fi
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    
    # Cleanup temp files
    rm -rf "$temp_dir"
}

# ============================================================
# Trap interrupts
# ============================================================
trap 'echo -e "\n${RED}Scan interrupted. Cleaning up...${NC}"; rm -rf "$temp_dir" 2>/dev/null; exit 1' INT TERM

# ============================================================
# Run main function
# ============================================================
main "$@"