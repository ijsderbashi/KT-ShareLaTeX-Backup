# KT-ShareLaTeX-Backup

A script to backup the files in kt-sharelatex. I personally used it to push my thesis onto my github.

## What is this repo?

This repository contains a single Bash script that:

1) logs in to your KT-ShareLaTeX account,
2) downloads your project as a ZIP,
3) extracts it to a local folder, and
4) commits & pushes any changes to your own Git remote.

It is intended to be run periodically via `cron`.

## Requirements

- Linux with `bash`, `curl`, `unzip`, and `git` installed (macOS should work. I am not sure about Windows)
- A KT-ShareLaTeX account (check onboarding docs to get it)
- A remote Git repository you can write to
- Basic Git set up (ideally SSH keys so `git push` works non-interactively)

## Configuration

Open the script in a text editor and set the **CONFIG** variables at the top:

```bash
BASE_URL="https://kt-sharelatex2.ijs.si"       # Probably should not change this
EMAIL="your.email@ijs.si"                      # Your ShareLaTeX login email
PASSWORD="YourLatexPassword"                   # Your ShareLaTeX password
PROJECT="ProjectIDCopiedFromURL"               # Project ID (see below)
BASE_PATH="/path/to/where/you/are/backing/up"  # Local backup root
```

### How to find the `PROJECT` ID
Open your project in KT-ShareLaTeX and copy the ID from the URL bar.
It typically looks like:

```
https://kt-sharelatex2.ijs.si/project/<PROJECT_ID>
```

Use the value after `/project/` as `PROJECT`.

### What gets created locally

- `"$BASE_PATH/proj.zip"` — the downloaded ZIP
- `"$BASE_PATH/Thesis"` — the extracted working tree (this is where Git commits happen)
- `"$BASE_PATH/cron.log"` — the script’s log file

## (Reccommended) Prep

Although the script should create everything automatically, you are advised to prepare the base path and the git repo manually.

### a) If you have a repo that you want to use
```bash
mkdir -p "/path/to/where/you/are/backing/up"
cd "/path/to/where/you/are/backing/up"
git clone <your_repo_remote_url> Thesis
```

### b) If you have an empty repo that you want to push into

```bash
mkdir -p "/path/to/where/you/are/backing/up/Thesis"
cd "/path/to/where/you/are/backing/up/Thesis"
git remote add origin <YOUR_EMPTY_REMOTE_URL>
git branch -M main
git push -u origin main
```
### Try the script for the first time manually.

Many things can go wrong so give your script a try to make sure everything is set up correctly

```bash
chmod +x BackMeUp.sh # Make sure it is executable, only needed once
./BackMeUp.sh
```


## Set up a cron job

1) Open your user crontab:

```bash
crontab -e
```

2) Add an entry. Examples:

**Every day at 06:15:**
  ```cron
  15 6 * * * /full/path/to/BackMeUp.sh
  ```

The job is quiet by design; check `cron.log` for status:
- `COMMITTED <hash>: Update from KT-ShareLaTeX: …` — changes were pulled, committed, and pushed
- `NO_CHANGES` — nothing new since last run

Now it should be working as you set it up.

## Uninstall / disable

- Remove the line from `crontab -e`
- Optionally delete `"$BASE_PATH/Thesis"`, `proj.zip`, and `cron.log` if you no longer need them


