# 🖥️ XAMPP Virtual Host Creator

A Windows batch script that automates the setup of Apache virtual hosts on your local XAMPP development environment — no manual config file editing required.

---

## 📌 What This Script Does

Every time you start a new PHP/Laravel project locally, you need to manually edit two files:

- `httpd-vhosts.conf` — to register the virtual host in Apache
- `hosts` (Windows) — to map your custom domain to `127.0.0.1`

This script does **both** in one go, with validation, duplicate detection, and a confirmation prompt before touching anything.

---

## ✅ Requirements

| Requirement | Detail |
|---|---|
| OS | Windows 10 / 11 |
| XAMPP | Installed at `C:\xampp` (default path) |
| Apache | Included with XAMPP |
| Privileges | Administrator (script auto-requests via UAC) |

> ⚠️ If your XAMPP is installed in a custom path (e.g., `D:\xampp`), open the script in Notepad and update the `XAMPP_PATH` variable at the top.

---

## ⚙️ One-Time Setup (Do This First)

Before using this script, you need to enable virtual host support in Apache:

1. Open: `C:\xampp\apache\conf\httpd.conf`
2. Find this line:
   ```
   # Include conf/extra/httpd-vhosts.conf
   ```
3. Remove the `#` to uncomment it:
   ```
   Include conf/extra/httpd-vhosts.conf
   ```
4. Save the file and restart Apache from the XAMPP Control Panel.

> The script will warn you if this step is skipped, but your virtual host **will not work** without it.

---

## 🚀 How to Use

1. **Right-click** `add-vhost.bat` → **Run as Administrator**
   *(Or just double-click — it will auto-request admin via UAC)*

2. When prompted, enter the **full path** to your project's public folder:
   ```
   Enter full path to your project public folder:
   > C:\xampp\htdocs\my-laravel-app\public
   ```

3. Enter your desired **local domain name**:
   ```
   Enter local domain name (e.g., myproject.local):
   > my-laravel-app.local
   ```

4. Review the summary and confirm with `Y`.

5. **Restart Apache** from the XAMPP Control Panel.

6. Open your browser and visit: `http://my-laravel-app.local`

---

## 🗂️ What Gets Added

### `httpd-vhosts.conf`
```apache
<VirtualHost *:80>
    DocumentRoot "C:\xampp\htdocs\my-laravel-app\public"
    ServerName my-laravel-app.local
    ServerAlias www.my-laravel-app.local
    <Directory "C:\xampp\htdocs\my-laravel-app\public">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog "logs/my-laravel-app.local-error.log"
    CustomLog "logs/my-laravel-app.local-access.log" combined
</VirtualHost>
```

### `hosts` file
```
127.0.0.1   my-laravel-app.local
127.0.0.1   www.my-laravel-app.local
```

---

## 🛡️ Safety Checks

The script performs these validations before writing anything:

- ✅ Confirms it is running as Administrator
- ✅ Verifies XAMPP is installed at the configured path
- ✅ Checks all required config files exist
- ✅ Warns if `httpd-vhosts.conf` is not included in `httpd.conf`
- ✅ Validates the project directory actually exists
- ✅ Validates domain name format (must contain a dot)
- ✅ Checks for duplicate domain in both config files
- ✅ Shows a summary and asks for confirmation before writing
- ✅ Verifies entries were written successfully after each file operation

---

## 💡 Use Cases

| Scenario | Example Domain |
|---|---|
| Laravel / PHP project | `myapp.local` |
| Multiple projects isolated | `erp.local`, `blog.local`, `api.local` |
| Testing different PHP versions | `app-php8.local` |
| Simulating a production-like URL | `inventory.test` |

---

## ❓ Troubleshooting

**Browser shows "This site can't be reached"**
→ Make sure Apache is running in XAMPP Control Panel.
→ Make sure you restarted Apache after running the script.

**Script says "already exists in vhosts config"**
→ That domain was already added. Open `httpd-vhosts.conf` to review or edit it manually.

**UAC prompt doesn't appear / access denied**
→ Right-click the file and choose **Run as Administrator** manually.

**Custom XAMPP path**
→ Edit the `XAMPP_PATH` variable near the top of the `.bat` file.
