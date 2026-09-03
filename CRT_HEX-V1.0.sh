#!/bin/bash

# ============================================================
# CRT_HEX-V-2.0.sh - MR. ROBOT (TryHackMe) ULTIMATE EDITION
# ============================================================
# GitHub: hex-3030
# TryHackMe: HEXD
# ============================================================

# ============================================================
# COLOR DEFINITIONS
# ============================================================
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

GREEN='\033[38;5;46m'
AMBER='\033[38;5;214m'
WHITE='\033[38;5;255m'
RED='\033[38;5;196m'
GRAY='\033[38;5;245m'

# ============================================================
# HELP
# ============================================================
show_help() {
    echo -e "${GREEN}┌─────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${GREEN}│${RESET}  ${BOLD}${WHITE}🔐 CRT_HEX v2.0 - Mr. Robot Ultimate Edition${RESET}${GREEN}│${RESET}"
    echo -e "${GREEN}├─────────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${GREEN}│${RESET}  ${AMBER}GitHub:${RESET} ${WHITE}https://github.com/hex-3030${RESET}            ${GREEN}│${RESET}"
    echo -e "${GREEN}│${RESET}  ${AMBER}TryHackMe:${RESET} ${WHITE}https://tryhackme.com/p/HEXD${RESET}         ${GREEN}│${RESET}"
    echo -e "${GREEN}│${RESET}  ${AMBER}USAGE:${RESET} ./CRT_HEX-V-13.0.sh -d <domain> [options]     ${GREEN}│${RESET}"
    echo -e "${GREEN}│${RESET}  ${AMBER}OPTIONS:${RESET} --html <file> | -o <file> | --limit <num>   ${GREEN}│${RESET}"
    echo -e "${GREEN}└─────────────────────────────────────────────────────────────────┘${RESET}"
    exit 0
}

# ============================================================
# ARGUMENTS
# ============================================================
DOMAIN=""
HTML_OUTPUT=""
TEXT_OUTPUT=""
LIMIT=100

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain) DOMAIN="$2"; shift 2 ;;
        --html) HTML_OUTPUT="$2"; shift 2 ;;
        -o|--output) TEXT_OUTPUT="$2"; shift 2 ;;
        --limit) LIMIT="$2"; shift 2 ;;
        -h|--help) show_help ;;
        *) echo -e "${RED}❌ Unknown option: $1${RESET}"; exit 1 ;;
    esac
done

if [[ -z "$DOMAIN" ]]; then
    echo -e "${RED}💀 ERROR: Target domain required! Use -d <domain>${RESET}"
    exit 1
fi

# ============================================================
# FETCH DATA
# ============================================================
clear
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${RESET}"
echo -e "${AMBER}   🔐 CRT_HEX v13.0 - Target: ${BOLD}${WHITE}$DOMAIN${RESET}${AMBER} [GitHub: hex-3030]${RESET}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${RESET}\n"

API_URL="https://crt.sh/?q=%25.${DOMAIN}&output=json"
TEMP_FILE=$(mktemp)

curl -s "$API_URL" -o "$TEMP_FILE" --max-time 30

if [[ ! -s "$TEMP_FILE" ]]; then
    echo -e "${RED}💀 ERROR: Failed to fetch data${RESET}"
    rm -f "$TEMP_FILE"
    exit 1
fi

# ============================================================
# PROCESSING
# ============================================================
if command -v jq &> /dev/null; then
    
    # --- 1. Extract Unique Subdomains ---
    ALL_SUBS=$(jq -r '.[] | .name_value' "$TEMP_FILE" 2>/dev/null | \
        tr ',' '\n' | \
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
        grep -E "(^|\.)${DOMAIN}$" | \
        sort)

    UNIQUE_SUBDOMAINS=$(echo "$ALL_SUBS" | uniq | grep -v '^$')
    DUPLICATE_SUBS=$(echo "$ALL_SUBS" | uniq -d | grep -v '^$')
    
    SUBDOMAIN_COUNT=$(echo "$UNIQUE_SUBDOMAINS" | grep -c '.' || echo "0")
    DUPLICATE_COUNT=$(echo "$DUPLICATE_SUBS" | grep -c '.' || echo "0")

    # --- 2. Build HTML for Subdomains ---
    SUBDOMAIN_HTML_ITEMS=""
    while IFS= read -r sub; do
        if [[ -n "$sub" ]]; then
            SUBDOMAIN_HTML_ITEMS+="<tr><td>${sub}</td></tr>"
        fi
    done <<< "$UNIQUE_SUBDOMAINS"

    # --- 2.5. Build HTML for Duplicates ---
    DUPLICATE_HTML_ITEMS=""
    while IFS= read -r sub; do
        if [[ -n "$sub" ]]; then
            DUPLICATE_HTML_ITEMS+="<tr><td>${sub}</td></tr>"
        fi
    done <<< "$DUPLICATE_SUBS"

    # --- 3. Build Table Rows for Certificates ---
    TABLE_ROWS=""
    while IFS=$'\t' read -r name issuer not_before not_after id; do
        STATUS_CLASS="status-valid"
        STATUS_TEXT="ACTIVE"
        if [[ "$not_after" < "$(date -u +'%Y-%m-%dT%H:%M:%S')" ]]; then
            STATUS_CLASS="status-expired"
            STATUS_TEXT="EXPIRED"
        fi
        TABLE_ROWS+="<tr><td>$name</td><td>$issuer</td><td>$not_before</td><td>$not_after</td><td class='$STATUS_CLASS'>$STATUS_TEXT</td></tr>"
    done < <(jq -r --arg limit "$LIMIT" '.[0:$limit|tonumber] | .[] | 
        "\(.name_value)\t\(.issuer_name)\t\(.not_before)\t\(.not_after)\t\(.id)"' "$TEMP_FILE" 2>/dev/null)

    TOTAL_CERTS=$(jq '. | length' "$TEMP_FILE" 2>/dev/null)
    ACTIVE_CERTS=$(jq --arg now "$(date -u +'%Y-%m-%dT%H:%M:%S')" '[.[] | select(.not_after >= $now)] | length' "$TEMP_FILE" 2>/dev/null)
    EXPIRED_CERTS=$((TOTAL_CERTS - ACTIVE_CERTS))

    # ============================================================
    # TERMINAL OUTPUT (Beautiful Terminal Display)
    # ============================================================
    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${AMBER}${BOLD}[ 1 ] 🌐 UNIQUE SUBDOMAINS FOUND (${SUBDOMAIN_COUNT})${RESET}"
    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    if [[ -z "$UNIQUE_SUBDOMAINS" ]]; then
        echo -e "${GRAY}   No subdomains found.${RESET}"
    else
        echo "$UNIQUE_SUBDOMAINS" | while IFS= read -r sub; do
            echo -e "   ${GREEN}▶${RESET} ${WHITE}$sub${RESET}"
        done
    fi
    echo ""

    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${RED}${BOLD}[ 2 ] 🚨 DUPLICATE SUBDOMAINS (${DUPLICATE_COUNT})${RESET}"
    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    if [[ -z "$DUPLICATE_SUBS" ]]; then
        echo -e "${GREEN}   No duplicates found.${RESET}"
    else
        echo "$DUPLICATE_SUBS" | while IFS= read -r sub; do
            echo -e "   ${RED}⚠️${RESET} ${WHITE}$sub${RESET}"
        done
    fi
    echo ""

    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${GREEN}${BOLD}[ 3 ] 📋 CERTIFICATE DETAILS (All Records)${RESET}"
    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    while IFS=$'\t' read -r name issuer not_before not_after id; do
        STATUS=""
        if [[ "$not_after" < "$(date -u +'%Y-%m-%dT%H:%M:%S')" ]]; then
            STATUS="${RED}❌ EXPIRED${RESET}"
        else
            STATUS="${GREEN}✅ ACTIVE${RESET}"
        fi
        
        echo -e "${AMBER}┌────────────────────────────────────────────────────────────┐${RESET}"
        echo -e "${AMBER}│${RESET} ${BOLD}${WHITE}Common Name:${RESET} ${GREEN}$name${RESET}"
        echo -e "${AMBER}│${RESET} ${DIM}Issuer:${RESET} ${GRAY}$issuer${RESET}"
        echo -e "${AMBER}│${RESET} ${DIM}Valid To:${RESET} ${WHITE}$not_after${RESET}"
        echo -e "${AMBER}│${RESET} ${DIM}Status:${RESET} $STATUS"
        echo -e "${AMBER}└────────────────────────────────────────────────────────────┘${RESET}"
        echo ""
    done < <(jq -r --arg limit "$LIMIT" '.[0:$limit|tonumber] | .[] | 
        "\(.name_value)\t\(.issuer_name)\t\(.not_before)\t\(.not_after)\t\(.id)"' "$TEMP_FILE" 2>/dev/null)

    # ============================================================
    # HTML REPORT - FULL SCREEN MR. ROBOT (بدون sed و بدون باگ)
    # ============================================================
    if [[ -n "$HTML_OUTPUT" ]]; then
        
        cat > "$HTML_OUTPUT" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CRT_HEX - Mr. Robot</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: 'Courier New', Courier, monospace;
            background-color: #000000;
            color: #ffffff;
            padding: 0;
            min-height: 100vh;
        }

        .full-container {
            width: 100%;
            padding: 20px;
        }

        .terminal-window {
            background-color: #111111;
            border: 1px solid #ffffff;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 0 20px rgba(255, 255, 255, 0.1);
        }

        .terminal-heading {
            text-align: center;
            border-bottom: 1px solid #ffffff;
            padding-bottom: 20px;
            margin-bottom: 20px;
        }

        .terminal-heading h1 {
            font-size: 4em;
            font-weight: bold;
            letter-spacing: 10px;
            color: #ffffff;
            text-transform: uppercase;
            margin-bottom: 10px;
            text-shadow: 0 0 10px rgba(255, 255, 255, 0.5);
        }

        .terminal-heading h3 {
            color: #aaaaaa;
            font-size: 1.2em;
            margin-bottom: 10px;
        }

        .terminal-heading .links {
            margin-top: 15px;
            padding: 10px;
            background-color: #222222;
            border: 1px dashed #ffffff;
            display: inline-block;
            border-radius: 4px;
        }

        .terminal-heading .links a {
            color: #ffffff;
            text-decoration: none;
            font-weight: bold;
            margin: 0 15px;
            transition: color 0.3s;
        }

        .terminal-heading .links a:hover {
            color: #aaaaaa;
            text-decoration: underline;
        }

        .terminal-screen {
            background-color: #0d0d0d;
            border: 1px solid #333333;
            padding: 20px;
            min-height: 150px;
            font-size: 1em;
            line-height: 1.5;
            color: #aaaaaa;
        }

        .cursor {
            display: inline-block;
            width: 10px;
            height: 18px;
            background-color: #ffffff;
            animation: blink 1s step-end infinite;
            vertical-align: middle;
        }

        @keyframes blink {
            50% { opacity: 0; }
        }

        .live-cmd {
            color: #ffffff;
            font-weight: bold;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1px;
            background-color: #ffffff;
            border: 1px solid #ffffff;
            margin-bottom: 20px;
        }

        .stat-box {
            background-color: #000000;
            padding: 30px;
            text-align: center;
        }

        .stat-box .number {
            font-size: 5em;
            font-weight: bold;
            color: #ffffff;
        }

        .stat-box .label {
            font-size: 1em;
            color: #aaaaaa;
            text-transform: uppercase;
            letter-spacing: 2px;
            margin-top: 10px;
        }

        .section-container {
            margin-bottom: 30px;
            border: 1px solid #ffffff;
        }

        .section-header {
            background-color: #ffffff;
            color: #000000;
            padding: 15px;
            font-size: 1.5em;
            font-weight: bold;
            text-transform: uppercase;
        }

        .section-content {
            padding: 0;
            background-color: #000000;
        }

        table.full-table {
            width: 100%;
            border-collapse: collapse;
        }

        table.full-table th {
            background-color: #111111;
            color: #ffffff;
            padding: 15px;
            text-align: left;
            border-bottom: 1px solid #ffffff;
        }

        table.full-table td {
            padding: 15px;
            border-bottom: 1px solid #333333;
            color: #ffffff;
        }

        table.full-table tr:hover td {
            background-color: #222222;
        }

        .status-valid { color: #ffffff; font-weight: bold; }
        .status-expired { color: #aaaaaa; font-weight: bold; }

        .footer {
            text-align: center;
            padding: 20px;
            color: #aaaaaa;
            border-top: 1px solid #333333;
            margin-top: 20px;
        }

        @media (max-width: 768px) {
            .terminal-heading h1 {
                font-size: 2.5em;
            }
            .stat-box .number {
                font-size: 3em;
            }
        }
    </style>
</head>
<body>

    <div class="full-container">

        <div class="terminal-window">
            <div class="terminal-heading">
                <h1>fsociety</h1>
                <h3>// MR. ROBOT SECURITY PROTOCOL //</h3>
                <h3 style="color: #ffffff;">Target: $DOMAIN</h3>
                
                <div class="links">
                    <a href="https://github.com/hex-3030" target="_blank">[ GitHub: hex-3030 ]</a>
                    <span style="margin: 0 10px;">|</span>
                    <a href="https://tryhackme.com/p/HEXD" target="_blank">[ TryHackMe: HEXD ]</a>
                </div>
            </div>
            
            <div class="terminal-screen" id="terminal-box">
                <div>root@mrrobot:~# <span class="live-cmd">./CRT_HEX --initiating</span></div>
                <div>[OK] Initializing connection...</div>
                <div>[OK] Fetching certificate data...</div>
                <div id="typing-area"></div>
                <span class="cursor" id="cursor"></span>
            </div>
        </div>

        <div class="stats-grid">
            <div class="stat-box">
                <div class="number">$TOTAL_CERTS</div>
                <div class="label">Total Certificates</div>
            </div>
            <div class="stat-box">
                <div class="number">$ACTIVE_CERTS</div>
                <div class="label">Active</div>
            </div>
            <div class="stat-box">
                <div class="number">$EXPIRED_CERTS</div>
                <div class="label">Expired</div>
            </div>
            <div class="stat-box">
                <div class="number">$SUBDOMAIN_COUNT</div>
                <div class="label">Unique Subdomains</div>
            </div>
        </div>

        <div class="section-container">
            <div class="section-header">🌐 Subdomains Discovered</div>
            <div class="section-content">
                <table class="full-table">
                    <thead>
                        <tr>
                            <th>Common Name</th>
                        </tr>
                    </thead>
                    <tbody>
                        $SUBDOMAIN_HTML_ITEMS
                    </tbody>
                </table>
            </div>
        </div>

        <div class="section-container">
            <div class="section-header" style="background-color: #333333; color: #ffffff;">🚨 Duplicate Subdomains</div>
            <div class="section-content">
                <table class="full-table">
                    <thead>
                        <tr>
                            <th>Common Name</th>
                        </tr>
                    </thead>
                    <tbody>
                        $DUPLICATE_HTML_ITEMS
                    </tbody>
                </table>
            </div>
        </div>

        <div class="section-container">
            <div class="section-header">📋 Certificate Details</div>
            <div class="section-content">
                <table class="full-table">
                    <thead>
                        <tr>
                            <th>Common Name</th>
                            <th>Issuer</th>
                            <th>Valid From</th>
                            <th>Valid To</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        $TABLE_ROWS
                    </tbody>
                </table>
            </div>
        </div>

        <div class="footer">
            CRT_HEX v13.0 • MR. ROBOT (TryHackMe) FULL SCREEN EDITION • GitHub: hex-3030<br>
            For authorized security testing only
        </div>

    </div>

    <script>
        const commands = [
            "nmap -sC -sV <TARGET>",
            "gobuster dir -u http://<TARGET> -w wordlist.txt",
            "hydra -l elliot -P fsocity.dic <TARGET> http-post-form",
            "cat key-1-of-3.txt"
        ];
        
        const target = "$DOMAIN";
        const terminalBox = document.getElementById("typing-area");
        
        let cmdIndex = 0;
        let charIndex = 0;

        function typeCommand() {
            if (cmdIndex >= commands.length) return;

            const currentCmd = commands[cmdIndex].replace("<TARGET>", target);
            
            if (charIndex < currentCmd.length) {
                terminalBox.innerHTML += currentCmd[charIndex];
                charIndex++;
                setTimeout(typeCommand, 50);
            } else {
                terminalBox.innerHTML += " <span style='color:#888;'>[Completed]</span><br>root@mrrobot:~# ";
                charIndex = 0;
                cmdIndex++;
                setTimeout(typeCommand, 1000);
            }
        }

        setTimeout(() => {
            terminalBox.innerHTML = "";
            terminalBox.innerHTML = "root@mrrobot:~# nmap -sC -sV " + target + "<br>";
            terminalBox.innerHTML += "[OK] Starting scan...<br>";
            terminalBox.innerHTML += "root@mrrobot:~# ";
            typeCommand();
        }, 1000);
    </script>

</body>
</html>
HTMLEOF
        
        echo -e "${GREEN}✅ HTML report saved to: $HTML_OUTPUT${RESET}"
    fi

    # ============================================================
    # TEXT OUTPUT
    # ============================================================
    if [[ -n "$TEXT_OUTPUT" ]]; then
        {
            echo "=========================================="
            echo "CRT_HEX Certificate Report - $DOMAIN"
            echo "Generated: $(date)"
            echo "GitHub: https://github.com/hex-3030"
            echo "TryHackMe: https://tryhackme.com/p/HEXD"
            echo "=========================================="
            echo ""
            echo "--- UNIQUE SUBDOMAINS ---"
            echo "$UNIQUE_SUBDOMAINS"
            echo ""
            echo "--- DUPLICATE SUBDOMAINS ---"
            echo "$DUPLICATE_SUBS"
            echo ""
            echo "--- CERTIFICATE DETAILS ---"
            jq -r --arg limit "$LIMIT" '.[0:$limit|tonumber] | .[] | 
                "Name: \(.name_value)\nIssuer: \(.issuer_name)\nValid From: \(.not_before)\nValid To: \(.not_after)\nID: \(.id)\n---"' "$TEMP_FILE" 2>/dev/null
        } > "$TEXT_OUTPUT"
        echo -e "${GREEN}✅ Output saved to: $TEXT_OUTPUT${RESET}"
    fi

else
    echo -e "${RED}❌ jq is not installed. Please install it: sudo apt install jq${RESET}"
fi

rm -f "$TEMP_FILE"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${RESET}"
echo -e "${WHITE}   ✅ HUNT COMPLETE${RESET}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${RESET}"
