# Conky Desktop Dashboard

This directory contains a modular Conky-based desktop dashboard designed for
**ambient awareness**, not constant interaction.

Each widget is its own Conky instance. Together, they form a persistent
background layer that surfaces important context while staying visually quiet.

No Chromium, no Electron, no database.
Just shell scripts, text files, and Conky.

---

## Overview

The dashboard is composed of **six widgets**, positioned around a 1366×768 screen:

1. Projects
2. Todo
3. Stats
4. Recent Notes
5. Quotes
6. Year Progress

Each widget:
- Runs independently
- Uses transparent windows
- Sits below normal application windows
- Can be enabled/disabled without affecting the others

---

## Screenshot

![Conky dashboard overview](screenshots/overview.png)

---

## Widgets

### 1. Projects (`conky_projects.conf`)

Displays a short list of ongoing projects.

- Source: `projects.txt`
- One project per line
- Updated periodically via `cat`

Purpose:
A static reminder of what I'm currently working on, to hopefully not start yet another new project

---

### 2. Todo (`conky_todo.conf`)

Displays the current todo list.

- Source: `todo.txt`
- Plain text, human-editable
- Rendered as a simple list

Purpose:
Immediate tasks without task-manager overhead.
Links great with rofi which does the editing

---

### 3. Stats (`conky_stats.conf`)

Shows lightweight activity metrics.

- GitHub:
  - Commits today (`github_today.sh`)
  - Commits this week (`github_week.sh`)
- Anki:
  - Reviews today (`anki_today.sh`)
  - Reviews this week (`anki_week.sh`)

Purpose:
How's the progress going?

---

### 4. Recent Notes (`conky_notes.conf`)

Lists recently modified Obsidian notes.

- Source: `obsidian_last_notes.sh`
- Derived from the filesystem, not Obsidian internals

Purpose:
Surface recent thinking without opening the obsidian vault. Acts as a gentle nudge to get back into writing.

---

### 5. Quotes (`conky_quotes.conf`)

Displays a single quote that changes periodically.

- Source: `quotes.txt`
- One quote per line
- Randomly selected
- Fixed max width with automatic text wrapping

Purpose:
Just a quote every hour, like a cookie treat for the soul. Heh maybe I should add in jokes here?

---

### 6. Year Progress (`conky_year.conf`)

Visualizes the passage of the year as dots, grouped by month.

- Script: `scripts/year_dots.sh`
- 12 rows → one per month
- Each dot represents a day:
  - ● past
  - ◉ today
  - ○ future
- No numbers, no percentages

Purpose:
Time awareness without abstraction. So fucking cool. Thanks Sagar.

---

## Directory Structure

./
├── screenshots/
├── scripts/
│   ├── anki_today.sh*
│   ├── anki_week.sh*
│   ├── github_today.sh*
│   ├── github_week.sh*
│   ├── obsidian_last_notes.sh*
│   └── year_dots.sh*
├── conky.conf
├── conky_notes.conf
├── conky_projects.conf
├── conky_quotes.conf
├── conky_stats.conf
├── conky_todo.conf
├── conky_year.conf
├── projects.txt
├── quotes.txt
├── README.md
├── secrets.env
└── todo.txt

2 directories, 18 files

---

## Notes

- Widgets are started individually from the i3 config
- Reloading i3 does not reload Conky
- Each widget can be restarted independently
- Scripts are intentionally simple and inspectable

---