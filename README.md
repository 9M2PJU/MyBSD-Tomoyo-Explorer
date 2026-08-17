# MyBSD Tomoyo Explorer (BSD Explorer)

Contains historical projects from **MyBSD**, featuring **BSD Explorer / Tomoyo Explorer** written in Ruby.

![MyBSD Tomoyo Explorer](screenshots/mybsd-tomoyo-explorer.png)

---

### Credits & Attribution
- **Original Author:** Ariff Abdullah a.k.a. *skywizard* (`skywizard@MyBSD.org.my`) and the MyBSD team.
- **Original Release:** `1.00-ALPHA` ("Yamato Nadeshiko", 2002-02-26)

---

### Projects Included

1. **`ruby-BSD-Explorer`**: Tomoyo Explorer (BSD Explorer) `v1.00-ALPHA` ("Yamato Nadeshiko"), a Ruby + GTK 1.2 graphical file manager.
2. **`gelojoh-current`**: Gelojoh HTTP/SSL server in Ruby.
3. **`IPv6`**: IPv6 test chat server/clients and RFC drafts.

---

### Quick Start (Running Locally via Docker)

A complete containerized runtime environment with Ruby 1.8, GTK+ 1.2, GdkPixbuf, and the compiled `ruby-gtk-fix` C extension is provided.

```bash
# Build the runtime image
docker build -t mybsd-tomoyo-explorer:latest .

# Launch Tomoyo Explorer
./run-tomoyo-explorer.sh
```

Or run via the installed system shortcut:
```bash
tomoyo-explorer ~/
```

---

### Releases & CI/CD

Packaged source distribution bundles (`.tar.gz`, `.tar.bz2`, `.zip`, and `SHA256SUMS`) are built automatically with GitHub Actions and published under [Releases](../../releases).
