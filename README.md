# 🌐 eaxzone - Professional Domain Security Scanner

> 🚀 **Advanced AXFR Zone Transfer Detection Tool for Security Researchers & Bug Bounty Hunters**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash Version](https://img.shields.io/badge/bash-4.0+-blue.svg)](https://www.gnu.org/software/bash/)
[![Version](https://img.shields.io/badge/version-2.0-green.svg)](https://github.com/sol654/eaxzone)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![Maintenance](https://img.shields.io/badge/Maintained-yes-green.svg)](https://github.com/sol654/eaxzone/commits/main)

---

## 📖 Table of Contents
- [Overview](#-overview)
- [Key Features](#-key-features)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Usage Guide](#-usage-guide)
- [Output Examples](#-output-examples)
- [Report Formats](#-report-formats)
- [Use Cases](#-use-cases)
- [Security Best Practices](#-security-best-practices)
- [FAQ](#-faq)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 Overview

**eaxzone** is a professional-grade domain security scanner designed for penetration testers, bug bounty hunters, and security researchers. It automates the critical process of identifying misconfigured DNS servers vulnerable to zone transfer attacks.

### What is a Zone Transfer (AXFR)?
A zone transfer is a DNS mechanism used to replicate DNS data across nameservers. When misconfigured, it allows unauthorized users to download the entire DNS zone, potentially exposing:
- Internal IP addresses and network infrastructure
- Subdomain enumeration
- Email server information
- Other sensitive internal services

### How It Works
This tool combines the functionality of `dig NS` and `dig AXFR` into a single, powerful interface:

1. **NS Record Enumeration** - Discovers all authoritative nameservers
2. **AXFR Zone Transfer Testing** - Systematically tests each nameserver
3. **Vulnerability Detection** - Identifies misconfigured servers
4. **Comprehensive Reporting** - Generates multiple report formats

---

## 🚀 Key Features

### 🔒 **Security & Reliability**
- ✅ Input validation to prevent injection attacks
- ✅ Configurable timeouts (prevent hanging)
- ✅ Automatic retry mechanism with exponential backoff
- ✅ Error handling and recovery
- ✅ Temporary file cleanup
- ✅ Non-destructive scanning
- ✅ Rate limiting protection

### 📊 **Multiple Output Formats**
- **Master Report** - Complete scan details with color coding
- **JSON** - Machine-readable format for API integration
- **CSV** - Excel-compatible for data analysis
- **NS Records** - Discovered nameservers list
- **AXFR Results** - Vulnerability findings summary
- **Detailed Logs** - Complete audit trail

### 🎯 **Professional Features**
- 🎨 Color-coded terminal output
- 📈 Real-time progress tracking
- 📝 Detailed logging system
- ⏰ Timestamped results
- 🔄 Parallel processing support
- 🔇 Verbose and quiet modes
- 📊 Professional summary statistics
- 🚦 Progress indicators

### ⚡ **Performance**
- Configurable parallel threads
- Efficient batch processing
- Minimal resource usage
- Handles large domain lists (1000+)
- Intelligent caching

---

## 📦 Installation

### **Option 1: Direct Download**
```bash
# Download the script
wget https://raw.githubusercontent.com/sol654/eaxzone/main/eaxzone.sh

# Make it executable
chmod +x eaxzone.sh

# Optional: Move to PATH for system-wide use
sudo mv eaxzone.sh /usr/local/bin/eaxzone
```

### **Option 2: Clone Repository**
```bash
# Clone the repository
git clone https://github.com/sol654/eaxzone.git

# Navigate to directory
cd eaxzone

# Make it executable
chmod +x eaxzone.sh
```

### **Option 3: One-Liner Installation**
```bash
curl -sSL https://raw.githubusercontent.com/sol654/eaxzone/main/eaxzone.sh -o eaxzone.sh && chmod +x eaxzone.sh
```

### **Prerequisites**

| Package | Installation Command |
|---------|---------------------|
| **Bash 4.0+** | Pre-installed on most Linux/macOS |
| **dnsutils (dig)** | `sudo apt-get install dnsutils` (Ubuntu/Debian) |
| **bind-utils** | `sudo yum install bind-utils` (RHEL/CentOS) |
| **bind-tools** | `sudo pacman -S bind-tools` (Arch Linux) |
| **bind** | `brew install bind` (macOS) |

### **Verify Installation**
```bash
./eaxzone.sh -h
```

---

## 🎯 Quick Start

### **1. Basic Usage**
```bash
# Create a domain list file
echo "example.com" > domains.txt
echo "test.com" >> domains.txt
echo "intigriti.com" >> domains.txt

# Run the scanner
./eaxzone.sh -f domains.txt
```

### **2. Advanced Usage**
```bash
# With custom output directory and multiple report formats
./eaxzone.sh -f domains.txt -o scan_results -j -c

# With custom timeout and retries
./eaxzone.sh -f subdomains.txt -t 15 -r 3

# Quiet mode for automation
./eaxzone.sh -f domains.txt -q -j

# Verbose mode for debugging
./eaxzone.sh -f domains.txt -v
```

### **3. Complete Bug Bounty Workflow**
```bash
# Step 1: Extract subdomains
subfinder -d example.com -silent -o subdomains.txt

# Step 2: Clean and sort
sort -u subdomains.txt -o subdomains.txt

# Step 3: Scan for AXFR vulnerabilities
./eaxzone.sh -f subdomains.txt -o axfr_scan -j -c

# Step 4: Extract vulnerable domains
cat axfr_scan/axfr_results.txt | grep -A5 "VULNERABLE" > vulnerable.txt

# Step 5: Report findings
echo "Found $(grep -c "VULNERABLE" vulnerable.txt) vulnerable domains"
```

---

## 📖 Usage Guide

### **Command Syntax**
```bash
./eaxzone.sh [OPTIONS] -f <domain_list_file>
```

### **Options Reference**

| Option | Long Option | Description | Required | Default |
|--------|-------------|-------------|----------|---------|
| `-f` | `--file` | Input file with domains/subdomains (one per line) | ✅ | - |
| `-o` | `--output` | Output directory for results | ❌ | `scan_results_<timestamp>` |
| `-t` | `--timeout` | DNS query timeout in seconds | ❌ | 10 |
| `-r` | `--retries` | Number of retry attempts | ❌ | 2 |
| `-j` | `--json` | Generate JSON report | ❌ | false |
| `-c` | `--csv` | Generate CSV report | ❌ | false |
| `-q` | `--quiet` | Quiet mode (minimal output) | ❌ | false |
| `-v` | `--verbose` | Verbose mode (detailed output) | ❌ | false |
| `-h` | `--help` | Display help message | ❌ | false |

### **Input File Format**
Create a text file with one domain/subdomain per line:

```txt
example.com
www.example.com
mail.example.com
subdomain.example.com
test.domain.com
api.example.com
intigriti.com
hackerone.com
bugcrowd.com
```

### **Output Directory Structure**
```
scan_results_20240101_120000/
├── master_report.txt      # Complete scan report with color
├── ns_records.txt         # All discovered NS records
├── axfr_results.txt       # Vulnerability findings
├── results.json           # JSON format (if -j enabled)
├── results.csv            # CSV format (if -c enabled)
├── scan.log               # Detailed log file
└── temp/                  # Temporary files (auto-cleaned)
```

---

## 📊 Output Examples

### **Terminal Output Preview**
```bash
╔══════════════════════════════════════════════════════╗
║     DOMAIN SECURITY SCANNER - AXFR TESTING TOOL     ║
║          Professional Zone Transfer Scanner         ║
╚══════════════════════════════════════════════════════╝

Configuration:
  Input file: domains.txt
  Output dir: scan_results_20240101_120000
  Timeout: 10s
  Retries: 2
  Parallel threads: 5

Processing: example.com
[*] Testing example.com on NS: ns1.example.com
    - AXFR refused by ns1.example.com
[*] Testing example.com on NS: ns2.example.com
    *** SUCCESS! Zone transfer successful on ns2.example.com ***
    Records found:
    example.com.        3600    IN      A       192.0.2.1
    www.example.com.    3600    IN      A       192.0.2.2
    mail.example.com.   3600    IN      A       192.0.2.3
    ns1.example.com.    3600    IN      A       192.0.2.4
    ns2.example.com.    3600    IN      A       192.0.2.5

[!] VULNERABLE: example.com - Zone transfer possible!

Progress: 1/10 completed
```

### **AXFR Results File**
```
========================================
VULNERABLE DOMAIN: example.com
Nameserver: ns2.example.com
Time: 2024-01-01 12:00:00
----------------------------------------
Zone Transfer Successful - ALL RECORDS:

example.com.        3600    IN      SOA     ns1.example.com. admin.example.com. 2024010101 3600 1800 1209600 3600
example.com.        3600    IN      NS      ns1.example.com.
example.com.        3600    IN      NS      ns2.example.com.
example.com.        3600    IN      A       192.0.2.1
www.example.com.    3600    IN      A       192.0.2.2
mail.example.com.   3600    IN      A       192.0.2.3
ftp.example.com.    3600    IN      A       192.0.2.4
internal.example.com. 3600 IN      A       10.0.0.1
========================================
```

### **JSON Output Example**
```json
{
  "scan_info": {
    "timestamp": "2024-01-01T12:00:00+00:00",
    "tool": "Domain Security Scanner",
    "version": "2.0",
    "total_domains": 10,
    "vulnerable_domains": 2
  },
  "results": [
    {
      "domain": "example.com",
      "vulnerable": true,
      "nameserver": "ns2.example.com",
      "zone_transfer": "SUCCESS",
      "records_count": 8
    },
    {
      "domain": "intigriti.com",
      "vulnerable": false,
      "nameserver": "N/A",
      "zone_transfer": "SECURE"
    }
  ]
}
```

### **CSV Output Example**
```csv
Domain,Nameserver,Vulnerable,ZoneTransfer,RecordsFound
example.com,ns2.example.com,Yes,Successful,8
intigriti.com,N/A,No,Secure,0
hackerone.com,N/A,No,Secure,0
bugcrowd.com,ns1.bugcrowd.com,No,Refused,0
```

---

## 🛠️ Use Cases

### **1. Bug Bounty Hunting**
```bash
# Quick check of all subdomains from recon
./eaxzone.sh -f all_subs.txt -o bb_scan -j -c

# Focus on high-value targets
./eaxzone.sh -f high_value.txt -t 20 -r 5 -v
```

### **2. Penetration Testing**
```bash
# Comprehensive domain assessment
./eaxzone.sh -f targets.txt -t 15 -r 3 -j -c -v

# Integration with other tools
subfinder -d target.com -silent | ./eaxzone.sh -f -
```

### **3. Security Audits**
```bash
# Audit multiple client domains
./eaxzone.sh -f clients.txt -o audit_report -j

# Generate executive summary
./eaxzone.sh -f domains.txt -j -c -q
```

### **4. Continuous Monitoring**
```bash
# Add to crontab for daily scanning
0 6 * * * /opt/eaxzone/eaxzone.sh -f /opt/domains.txt -o /reports/daily -q -j

# Weekly comprehensive scan
0 2 * * 0 /opt/eaxzone/eaxzone.sh -f /opt/all_domains.txt -o /reports/weekly -t 20 -j -c
```

### **5. Reconnaissance Automation**
```bash
#!/bin/bash
# Complete recon pipeline

echo "[+] Running subdomain enumeration..."
subfinder -d target.com -silent -o subs.txt
amass enum -d target.com -o amass_subs.txt
cat subs.txt amass_subs.txt | sort -u > all_subs.txt

echo "[+] Scanning for AXFR vulnerabilities..."
./eaxzone.sh -f all_subs.txt -o recon -j -c

echo "[+] Extracting vulnerable domains..."
jq '.results[] | select(.vulnerable==true) | .domain' recon/results.json > vulnerable.txt

echo "[+] Found $(wc -l < vulnerable.txt) vulnerable domains"
```

---

## 🔒 Security Best Practices

### **Ethical Usage Guidelines**
1. ✅ **Always get permission** before scanning domains you don't own
2. ✅ **Use on authorized targets only** (bug bounty programs, own infrastructure)
3. ✅ **Respect rate limits** - Don't overwhelm DNS servers
4. ✅ **Document your testing** - Keep records of authorized scans
5. ✅ **Report responsibly** - Inform owners of vulnerabilities found
6. ✅ **Follow bug bounty rules** - Stay within scope

### **Operational Security**
```bash
# Use with proper authorization
# Example: Only scan domains in your bug bounty scope
./eaxzone.sh -f in_scope_domains.txt -o authorized_scan

# Use VPN/proxy when appropriate
# Set custom DNS servers for specific scans
./eaxzone.sh -f domains.txt --dns-server 8.8.8.8

# Ensure logs don't contain sensitive data
./eaxzone.sh -f domains.txt -q -j
```

### **Performance Optimization**
```bash
# For large domain lists (1000+)
./eaxzone.sh -f large_list.txt -t 5 -r 2 -q -j

# For critical scans (lower timeout, more retries)
./eaxzone.sh -f critical.txt -t 20 -r 5 -v

# Network-friendly scanning
./eaxzone.sh -f domains.txt -t 8 -r 1
```

---

## ❓ FAQ

### **Q1: What is an AXFR Zone Transfer?**
**A:** AXFR is a DNS protocol mechanism for replicating DNS data across nameservers. When misconfigured, it allows unauthorized users to download the entire DNS zone, potentially exposing internal infrastructure. This is a critical security misconfiguration (CWE-200: Information Exposure).

### **Q2: Why should I use eaxzone?**
**A:** 
- **Automation**: Automates the complete workflow of NS lookup and AXFR testing
- **Efficiency**: Tests all nameservers for each domain automatically
- **Professional Reports**: Multiple formats for different audiences
- **Security**: Built with security best practices in mind
- **Integration**: Works with other recon tools seamlessly

### **Q3: Is this legal to use?**
**A:** Yes, when used responsibly on domains you own or have explicit permission to test. Always follow the laws and regulations of your jurisdiction. Bug bounty programs explicitly allow this type of testing within scope.

### **Q4: How fast is the scan?**
**A:** Typically 1-2 seconds per domain, but depends on:
- Network conditions
- DNS server response times
- Timeout settings
- Number of nameservers per domain
- With parallel processing, can handle hundreds of domains efficiently.

### **Q5: Can I use it with other tools?**
**A:** Absolutely! Integration examples:
```bash
# Pipe from Subfinder
subfinder -d target.com -silent | ./eaxzone.sh -f -

# Use with Amass
amass enum -d target.com -o domains.txt && ./eaxzone.sh -f domains.txt

# Combine with httpx for complete enumeration
./eaxzone.sh -f subs.txt -o scan
cat scan/axfr_results.txt | grep "VULNERABLE" | awk '{print $3}' | httpx -silent
```

### **Q6: What if I get false positives?**
**A:** The tool uses multiple validation checks to minimize false positives. However, always verify critical findings manually:
```bash
# Manual verification
dig axfr example.com @ns2.example.com
```
If you consistently get false positives, check your network configuration or DNS resolvers.

### **Q7: Can I scan IP addresses?**
**A:** The tool is designed for domain names. For IP-based DNS testing, use other tools like `dnsrecon` or `fierce`. However, you can use reverse DNS first:
```bash
# Convert IPs to domains first
for ip in $(cat ips.txt); do dig -x $ip +short; done > domains.txt
./eaxzone.sh -f domains.txt
```

### **Q8: How do I interpret the results?**
**A:** 
| Status | Meaning | Action Required |
|--------|---------|-----------------|
| **VULNERABLE** | Zone transfer successful | ⚠️ **Immediate security risk** - Contact admin |
| **SECURE** | No zone transfer possible | ✅ Safe configuration |
| **REFUSED** | Server refused transfer | ✅ Properly secured |
| **NO_NS** | No nameservers found | ⚠️ Check domain validity |
| **TIMEOUT** | No response | ⚠️ Network/firewall issue |

### **Q9: Can I customize the output format?**
**A:** Yes! The tool supports:
- Terminal with color coding
- Plain text reports
- JSON for API consumption
- CSV for spreadsheet analysis
- Custom formats can be built from the reports

### **Q10: How do I update the tool?**
**A:** 
```bash
# If cloned
git pull origin main

# If downloaded
rm eaxzone.sh
wget https://raw.githubusercontent.com/sol654/eaxzone/main/eaxzone.sh
chmod +x eaxzone.sh
```

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### **Ways to Contribute**
- 🐛 **Report bugs** - Create an issue with detailed information
- 💡 **Suggest features** - Share your ideas for improvements
- 📝 **Improve documentation** - Help make the docs better
- 🔧 **Submit PRs** - Fix issues or add features
- ⭐ **Star the repo** - Show your support

### **Development Setup**
```bash
# Clone the repository
git clone https://github.com/sol654/eaxzone.git
cd eaxzone

# Create a development branch
git checkout -b feature/your-feature-name

# Make your changes and test
./eaxzone.sh -f test_domains.txt -v

# Run tests (if available)
./test.sh

# Submit a pull request
```

### **Pull Request Guidelines**
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 sol654

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 📞 Contact & Support

- **GitHub Issues**: [https://github.com/sol654/eaxzone/issues](https://github.com/sol654/eaxzone/issues)
- **Security Reports**: Please open a private issue for security concerns
- **Twitter**: [@sol654](https://twitter.com/sol654)

---

## 🙏 Acknowledgments

- **ISC** - For the amazing `dig` tool
- **Bug Bounty Community** - For inspiring better security tools
- **Open Source Contributors** - Making security accessible to everyone
- **DNS Community** - For maintaining the DNS infrastructure

---

## ⭐ Show Your Support

If you find this tool useful, please consider:
- ⭐ Starring the repository
- 🐦 Sharing on social media
- 📖 Writing about your experience
- 💰 Donating to open source projects

---

## 📊 Project Statistics

![GitHub stars](https://img.shields.io/github/stars/sol654/eaxzone?style=social)
![GitHub forks](https://img.shields.io/github/forks/sol654/eaxzone?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/sol654/eaxzone?style=social)
![GitHub contributors](https://img.shields.io/github/contributors/sol654/eaxzone)
![GitHub last commit](https://img.shields.io/github/last-commit/sol654/eaxzone)
![GitHub issues](https://img.shields.io/github/issues/sol654/eaxzone)

---

**Made with ❤️ by Eaxayaz**

*Remember: With great power comes great responsibility. Scan responsibly!*

🔒 **Stay Secure, Stay Ethical**

---
