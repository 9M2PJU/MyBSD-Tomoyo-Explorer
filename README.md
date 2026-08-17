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

### Download & Run (Standalone AppImage)

Download the ready-to-run Linux **x86_64 AppImage** from [Releases](../../releases):

```bash
# Make executable and run
chmod +x MyBSD_Tomoyo_Explorer-x86_64.AppImage
./MyBSD_Tomoyo_Explorer-x86_64.AppImage ~/
```

*Bundles Ruby 1.8 runtime, GTK+ 1.2, GdkPixbuf, `ruby-gnome 0.34`, and `ruby-gtk-fix` C extension. Runs on any modern Linux distribution without installing dependencies.*

---

### Alternative: Docker Environment & Building AppImage

```bash
# 1. Build Docker runtime image
docker build -t mybsd-tomoyo-explorer:latest .

# 2. Run via Docker container
./run-tomoyo-explorer.sh

# 3. Build standalone AppImage locally
./build-appimage.sh
```

---

### Releases & CI/CD

Packaged standalone AppImage binaries, source distribution bundles (`.tar.gz`, `.tar.bz2`, `.zip`), and `SHA256SUMS` are built automatically with GitHub Actions and published under [Releases](../../releases).
