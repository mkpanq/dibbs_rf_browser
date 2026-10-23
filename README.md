# DIBBS RFQ Browser

One fast page where a government-contracting vendor scans the day's Requests for Quotation (RFQs) from the
Defense Logistics Agency and finds the ones worth quoting.

DLA publishes every new RFQ on [DIBBS](https://www.dibbs.bsm.dla.mil) as a daily fixed-width text file,
behind a DoD consent page. This app downloads those files, parses them, and stores them in SQLite. You can then
search, filter and sort about 48,000 RFQs with every request served in under 30 ms.

## Quick start

```bash
bin/setup        # installs gems, creates the databases, imports the data (first run only, ~1 min), starts the server
```

Open <http://localhost:3000>.

Requirements: Ruby 4.0.6 (pinned in `.tool-versions`). No other services are needed; SQLite and the job queue run inside the app.

### Data import

```bash
bin/rails dibbs:import                          # new days + the newest day again
FULL=1 bin/rails dibbs:import                   # re-fetch every listed day
FILE=path/to/in261022.txt bin/rails dibbs:import  # import one local file
```

The same sync also runs automatically **every 24 hours** (Solid Queue, inside Puma).

## What you can do

| | |
|---|---|
| **Search** | One box. Every word must match a solicitation prefix, any part of an NSN (dashes optional, a bare NIIN works) or the item name. |
| **Open only** | Closed RFQs are hidden by default; tick *Include closed* to see them. |
| **Closing within** | 3 / 7 / 14 / 30 days, to focus on quotes due soon. |
| **FSC** | Type 4-digit supply classes or click one of the most common ones. |
| **Set-aside** | Small Business, HUBZone, SDVOSB, WOSB, 8(a), EDWOSB. |
| **Min qty** | Hide small buys. |
| **Sort** | Click any column header; click again to reverse. |
| **Live** | Results update as you type or click. The URL always reflects the view, so you can bookmark or share it. |

Every row links to the official RFQ page on DIBBS (opens in a new tab).

## How it works

```
DIBBS "Recent RFQs" page ──► Dibbs::Client ──► Dibbs::RfqFile ──► Dibbs::Importer ──► SQLite ──► RfqsController
  (consent wall, 2 hosts)     Net::HTTP,          fixed-width       upsert on            rfqs      one page,
                              cookies, consent    parser            solicitation + PR              Turbo + Stimulus
```

- **Access:** both DIBBS hosts show a DoD consent page. The client keeps a cookie jar per host, follows redirects
  by hand, and accepts consent by posting the form back. Consent is detected from the page content, because one
  host returns it with HTTP 200 at the file's own URL.
- **Parsing:** the layout comes from DIBBS's file definitions page and was checked against every line of a real
  file.
- **Storage:** one row per solicitation + purchase request. Re-importing is safe: the newest data wins, and the
  posted date keeps the first day an RFQ appeared.
- **Sync log:** every run is recorded (ok / failed + message) and shown on the page ("last checked 5 min ago", or
  a red warning).

## Stack

Rails 8.1 · SQLite · Solid Queue · Turbo + Stimulus · plain CSS. No extra gems, no JS or CSS frameworks.

## Project layout

| Path | What it is |
|---|---|
| `app/models/dibbs/client.rb` | Gets past the consent pages, lists and downloads files |
| `app/models/dibbs/rfq_file.rb` | Fixed-width layout and line parser |
| `app/models/dibbs/importer.rb` | Sync logic and upsert rules |
| `app/models/rfq.rb` | Search |
| `app/controllers/rfqs_controller.rb` | Filters, sorting, paging |
| `app/javascript/controllers/` | Live filtering and chip inputs (Stimulus) |
| `lib/tasks/dibbs.rake` | `dibbs:import`, `dibbs:fetch_latest` |

## Known limitations

- **Item names are cut at 21 characters** by the DIBBS file format; cut names are marked with "…". The full name
  is on the linked RFQ page.
- DIBBS lists roughly the last month of files, so that is the history available.
- Text search uses `LIKE`. That's fast at this size; full-text search (SQLite FTS5) would be the next step at
  millions of rows.
