# exitsama

Native Session Termination and Power Management Dialog for the Samarinda Desktop Environment.

`exitsama` provides an interactive power and session control dialog rendered via Floria Toolkit (`libft.so`) and X11/XCB.

## Specifications

`exitsama` offers the following session and power actions:
- **Lock Screen**: Locks screen via `shellsama --lock` (accelerator `L`)
- **Switch User**: Displays display manager greeter via `dm-tool switch-to-greeter` (accelerator `U`)
- **Suspend**: Suspends system via `systemctl suspend` (accelerator `P`)
- **Log Out**: Requests graceful session exit via `sessionsama --logout` (accelerator `O`)
- **Restart**: Reboots system via `systemctl reboot` (accelerator `R`)
- **Shut Down**: Powers off system via `systemctl poweroff` (accelerator `S` or `Enter`)
- **Cancel**: Dismisses dialog with exit code 0 (`Escape` or `C`)

## Features

- **Automatic countdown**: Configurable timer (default: 60s) executing default action on expiry.
- **Auto-pause**: Pointer motion, button hover, tab focus, or key press automatically pauses the countdown.
- **Keyboard navigation**: Tab/arrow cycling, Enter selection, Esc dismissal, single-key accelerators.
- **CLI parameters**: Supports `--shutdown`, `--reboot`, `--logout`, `--suspend`, `--lock`, and `--timeout=<sec>`.

## Building and testing

Compile binary:
```bash
./build.sh
```

Run test suite:
```bash
./build.sh test
```

## License

`exitsama` is released under the [Mozilla Public License 2.0](LICENSE).  
Copyright (c) 2026 Dio Affriza.
