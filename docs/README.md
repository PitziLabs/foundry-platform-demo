# Firewalla Gold SE → Axiom: Domain & Flow Log Shipping

## What This Does

Ships your Firewalla's Zeek DNS and connection logs to Axiom's cloud, giving you
months of searchable "what domains did each device visit" history — the same data
you see in the Firewalla app, but with long-term retention and powerful search.

**Cost: $0/month** (Axiom free tier = 500 GB/month, 30-day retention)  
**RAM overhead: ~26-50 MB** on the Firewalla  
**Setup time: ~15 minutes**

---

## Step 1: Create Your Axiom Account & Dataset

1. Go to [app.axiom.co](https://app.axiom.co) and sign up (free, no credit card)
2. Click **Datasets** in the left sidebar → **New Dataset**
3. Name it `firewalla` (or whatever you prefer)
4. Go to **Settings → API Tokens → New API Token**
5. Name: `firewalla-ingest`, Permissions: **Ingest** only
6. Copy the token — it starts with `xaat-`

## Step 2: Copy Files to Your Firewalla

From your Mac/PC, SCP the config files to the Firewalla's persistent directory.
Replace `192.168.1.1` with your Firewalla's IP address. The default SSH password
is in the Firewalla app under Settings → Advanced → SSH.

```bash
# Connect and create the config directory if needed
ssh pi@192.168.1.1 "mkdir -p /home/pi/.firewalla/config/post_main.d"

# Copy the config files
scp fluent-bit.conf pi@192.168.1.1:/home/pi/.firewalla/config/
scp parsers.conf pi@192.168.1.1:/home/pi/.firewalla/config/
scp log_shipping.env pi@192.168.1.1:/home/pi/.firewalla/config/
scp start_log_shipping.sh pi@192.168.1.1:/home/pi/.firewalla/config/post_main.d/
```

## Step 3: Configure Your API Token

```bash
ssh pi@192.168.1.1

# Edit the env file with your actual Axiom token
nano /home/pi/.firewalla/config/log_shipping.env
# Change: AXIOM_API_TOKEN=xaat-PASTE-YOUR-TOKEN-HERE
# To:     AXIOM_API_TOKEN=xaat-abc123yourActualToken

# Make the startup script executable
chmod +x /home/pi/.firewalla/config/post_main.d/start_log_shipping.sh
```

## Step 4: Start It Up

```bash
# Run the script manually the first time (it will pull the Docker image)
sudo /home/pi/.firewalla/config/post_main.d/start_log_shipping.sh

# Verify it's running
docker ps
# You should see: fluent-bit-axiom

# Check for errors
docker logs fluent-bit-axiom

# After ~30 seconds, check Axiom — you should see data flowing in
```

## Step 5: Verify in Axiom

Go to [app.axiom.co](https://app.axiom.co), click your `firewalla` dataset,
and you should see log entries appearing. The `log_source` field will show
`zeek_dns`, `zeek_conn`, or `firewalla_acl`.

---

## Example Axiom Queries (APL)

Once data is flowing, here are some queries to try in Axiom's query editor.
APL (Axiom Processing Language) is inspired by Kusto/KQL — if you've ever
touched Azure Log Analytics, it'll feel familiar.

### All DNS queries from the last hour
```kusto
['firewalla']
| where log_source == "zeek_dns"
| where _time > ago(1h)
```

### Top 20 most-queried domains today
```kusto
['firewalla']
| where log_source == "zeek_dns"
| where _time > ago(24h)
| parse log with * "\t" * "\t" * "\t" source_ip "\t" * "\t" * "\t" * "\t" * "\t" query_domain "\t" *
| summarize query_count = count() by query_domain
| order by query_count desc
| take 20
```

### Domains visited by a specific device (by IP)
Replace 192.168.1.50 with the device's IP from your Firewalla app.
```kusto
['firewalla']
| where log_source == "zeek_dns"
| where _time > ago(7d)
| where log contains "192.168.1.50"
| parse log with * "\t" * "\t" * "\t" source_ip "\t" * "\t" * "\t" * "\t" * "\t" query_domain "\t" *
| distinct query_domain
| order by query_domain asc
```

### Connection volume by destination (top bandwidth consumers)
```kusto
['firewalla']
| where log_source == "zeek_conn"
| where _time > ago(24h)
| parse log with * "\t" source_ip "\t" * "\t" dest_ip "\t" dest_port "\t" * "\t" * "\t" * "\t" * "\t" * "\t" * "\t" * "\t" orig_bytes "\t" resp_bytes "\t" *
| extend total_bytes = tolong(orig_bytes) + tolong(resp_bytes)
| summarize total_traffic = sum(total_bytes) by dest_ip
| order by total_traffic desc
| take 20
```

### Blocked connections (from Firewalla ACL logs)
```kusto
['firewalla']
| where log_source == "firewalla_acl"
| where _time > ago(24h)
```

---

## Maintenance & Troubleshooting

### After a Firewalla firmware update
The persistence script runs automatically — no action needed. If something
breaks, SSH in and check:
```bash
docker ps                          # Is the container running?
docker logs fluent-bit-axiom       # Any errors?
sudo /home/pi/.firewalla/config/post_main.d/start_log_shipping.sh  # Restart
```

### Check RAM usage
```bash
docker stats fluent-bit-axiom --no-stream
# Should be well under 128 MB
```

### Stop shipping logs
```bash
docker rm -f fluent-bit-axiom
# To prevent restart on boot, remove or rename the post_main.d script
```

### Verify Zeek log paths exist
```bash
ls -la /bspool/manager/dns.log
ls -la /bspool/manager/conn.log
# These should exist and be actively written to
```

---

## How It Survives Firmware Updates

The Firewalla Gold SE uses an overlay filesystem — almost everything outside
of `/home/pi/.firewalla/` gets wiped on reboot or firmware update. That's why
all four files live under that path:

```
/home/pi/.firewalla/config/
├── fluent-bit.conf          ← Fluent Bit main config
├── parsers.conf             ← Zeek TSV parser definition
├── log_shipping.env         ← Your Axiom credentials (keep secret!)
├── fluent-bit-data/         ← Auto-created: file position tracking
└── post_main.d/
    └── start_log_shipping.sh  ← Runs on every boot + firmware update
```

Docker images are cached and `--restart always` handles normal reboots.
The post_main.d script handles the edge case where a firmware update
clears the Docker state entirely.
