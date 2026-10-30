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

## Lock tracking

Lock tracking uses the browser's Idle Detection API, which **Chrome and Edge** support on Windows,
macOS and Linux. Click **Enable lock tracking** once, then click **Allow** in the browser's prompt
under the address bar. If you clicked Block, open the site icon left of the address bar →
**Site settings** → **Your device use** → Allow, and reload. It records locks
only while the page is open; a background tab is fine. Other browsers can use the time clock, but
without lock tracking.

## Where your data lives

Everything is saved in your browser's local storage for this site. Nothing is sent anywhere.

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

## Optional: Windows service mode

`time-clock.cmd` runs a small PowerShell host on `http://localhost:47653/` that records lock and
unlock even while the page is closed, and stores data in `%LOCALAPPDATA%\TimeClock`. It needs no
admin rights. To use it, download `index.html`, `time-clock.ps1` and `time-clock.cmd` into one
folder and double-click `time-clock.cmd`.
