# Time Clock

A simple time clock for keeping track of **your own** time. It runs in your browser, with nothing to
install, no admin rights and no account. It's a personal log, not an employee-monitoring tool: your
data never leaves your browser, and you can add, edit or delete any line, including lock/unlock entries.

**[▶ Open Time Clock](https://chris-wolfgang.github.io/time-clock/)**

## Features

- Clock In / Clock Out, Meal Start / Meal End, Break Start / Break End
- Log grouped by day (today expanded), with each start/end pair on one line and hours worked per day
- Add, edit or delete any line; optional description on every line, including screen locks
- Weekly total and hours remaining against a target (default 40)
- Lock tracking: screen lock/unlock is logged, and locked time while clocked in is taken out of
  your hours worked (day and week totals)
- Export to CSV; Backup / Restore as JSON
- Diagnostics: download a log of what the browser reported about screen lock, for troubleshooting
  lock tracking (see [Where your data lives](#where-your-data-lives))

## Lock tracking

Lock tracking uses the browser's Idle Detection API, which **Chrome and Edge** support on Windows,
macOS and Linux. Click **Enable lock tracking** once, then click **Allow** in the browser's prompt
under the address bar. If you clicked Block, open the site icon left of the address bar →
**Site settings** → **Your device use** → Allow, and reload. It records locks
only while the page is open; a background tab is fine. Other browsers can use the time clock, but
without lock tracking.

## Where your data lives

Everything is saved in your browser's local storage for this site. Nothing is sent anywhere.
The page keeps up to three items there:

| Local storage key | What it holds |
| --- | --- |
| `timeClock.v2` | Your entries, lock events and settings. This is what Backup saves and Restore replaces. |
| `timeClock.diag` | The diagnostic log (below). |
| `timeClock.v2.unreadable` | Only if saved data could not be read (below). |

> [!WARNING]
> **Your entries are tied to the exact web address and the exact browser you used.**
>
> - **Same address only.** Entries made at https://chris-wolfgang.github.io/time-clock/ are not
>   visible from any other address, such as a downloaded copy of `index.html`, a `localhost`
>   address, or the Windows service mode. Each address starts empty.
> - **Same browser and profile only.** Chrome and Edge don't share data, and neither do two
>   profiles in the same browser. Private (Incognito / InPrivate) windows keep nothing after they
>   close, and another computer always starts empty, even if you're signed in to the browser.
> - **Clearing site data** (cookies and site data, or a cleanup tool) deletes your entries.
>
> To move your entries, click **Backup** where they are, then **Restore** in the other browser or
> at the other address. Restore replaces everything already there. Pick one browser and keep
> using it, and back up regularly.

### Diagnostic log

To help troubleshoot lock tracking, the page keeps a log of what the browser reports, under
`timeClock.diag`. It records each time the page is opened (with your browser's user-agent string),
shown or hidden, frozen or resumed, focused or unfocused, goes online or offline, or is saved from
another tab; timer gaps over 90 seconds; and lock-tracking permission, start, screen lock/unlock
changes and errors. Each record has the date and time, a random id for the browser tab, whether the
page was visible and whether it had focus. It holds no entry descriptions or totals. Only the latest
3,000 records are kept.

The log stays in your browser. It is not included in Backup or Export CSV; the **Diagnostics**
button downloads it as a JSON file, which you can read before sharing. **Clear all data** does not
delete it. To delete it, clear this site's data in the browser (which also deletes your entries),
or open the browser's developer tools (F12), go to the Console and run
`localStorage.removeItem('timeClock.diag')`. If browser storage is full, the page drops the log to
make room for your entries.

### Saved data that could not be read

If the saved data is damaged (for example, edited by hand), the page leaves out the entries it
can't use and shows a note in the Data card. Before doing so, it copies the original saved text
to `timeClock.v2.unreadable` (if there is room), so nothing is lost; the next time this happens,
that copy is replaced. The copy is not in Backup and **Clear all data** does not delete it. To get it out, open the
browser's developer tools (F12), go to the Console and run
`copy(localStorage.getItem('timeClock.v2.unreadable'))`, then paste it into a text editor. You can
also see it under **Application** → **Local storage** in Chrome and Edge. Once you no longer need
it, run `localStorage.removeItem('timeClock.v2.unreadable')`.

## Optional: Windows service mode

`time-clock.cmd` runs a small PowerShell host on `http://localhost:47653/` that records lock and
unlock even while the page is closed, and stores data in `%LOCALAPPDATA%\TimeClock`. It needs no
admin rights. To use it, download `index.html`, `time-clock.ps1` and `time-clock.cmd` into one
folder and double-click `time-clock.cmd`.

The page opens at an address ending in `?k=` and a key that belongs to your Windows account (kept
in `%LOCALAPPDATA%\TimeClock\token`). Without the key the page and its data are refused, so other
users and programs on the PC can't read your entries through the port. Bookmark the address it
opens, or just run `time-clock.cmd` again.

The service keeps these files in `%LOCALAPPDATA%\TimeClock`:

| File | What it holds |
| --- | --- |
| `data.json` | Your entries, lock events and settings, as the page last saved them. |
| `data.json.bak` | The previous version of `data.json`, replaced on each save. |
| `lock-events.csv` | Every lock and unlock seen while the service runs: time, `Lock` or `Unlock`, and the Windows reason (such as `SessionLock`). It is never trimmed. |
| `token` | The key described above. Anyone who can read it can open your Time Clock. |
| `error.log` | Only if something went wrong, such as the service failing to start or to write `lock-events.csv`. |

The page at the service's address also keeps its own copy in that browser's local storage, along
with the diagnostic log described above. **Clear all data** empties `data.json` (the version before
it is left in `data.json.bak` until the next save), but does not delete `lock-events.csv`; it only
stops the page importing those past events again. To remove everything, stop the service and delete
the `%LOCALAPPDATA%\TimeClock` folder.
