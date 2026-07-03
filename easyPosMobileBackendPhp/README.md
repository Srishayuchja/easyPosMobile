# EasyPOS Mobile Backend (PHP)

PHP REST API for the EasyPOS Flutter app. It is a port of the original ASP.NET
backend — **same structure, same database (UltimatePOS), only the language changed**
— so it deploys to PHP hosting (Hostinger) without a VPS.

## Structure (maps to the old .NET project)

| PHP file                         | .NET equivalent            |
| -------------------------------- | -------------------------- |
| `public/index.php`               | `Program.cs` (entry/router)|
| `config/config.php`              | `appsettings.json`         |
| `src/Database.php`               | `Data/AppDbContext.cs`     |
| `src/Controllers/*.php`          | `Controllers/*.cs`         |

```
easyPosMobileBackendPhp/
├── public/
│   ├── index.php        # front controller + routes
│   └── .htaccess        # pretty-URL rewrite
├── config/config.php    # DB credentials + POS defaults
├── src/
│   ├── Database.php     # PDO connection
│   ├── Response.php     # JSON helper
│   ├── Auth.php         # login token (HMAC, no dependencies)
│   └── Controllers/     # Health, Auth, Product, Sale
└── requests.http        # ready-made test calls
```

## Endpoints

| Method | Path               | Purpose                          |
| ------ | ------------------ | -------------------------------- |
| GET    | `/api/health`      | Service health check             |
| POST   | `/api/auth/login`  | Login (UltimatePOS users/roles)  |
| POST   | `/api/auth/logout` | Logout (stateless)               |
| GET    | `/api/products`    | Product list (price + stock)     |
| GET    | `/api/sales`       | Recent sales                     |
| POST   | `/api/sales`       | Create a sale                    |

Responses match the Flutter models in `lib/models/` exactly.

## Database

Uses the **existing UltimatePOS database** (`u383264767_EasyPOS`) — no schema changes.
The API reads/writes the real tables:

- products → `products` + `variations` (price) + `variation_location_details` (stock) + `units`
- login    → `users` + `model_has_roles` + `roles`
- sales    → `transactions` + `transaction_sell_lines` + `transaction_payments`

Defaults (`business_id`, `location_id`, walk-in `contact_id`) are set in
`config/config.php` and currently point to the values found in your dump (all `1`).

## Run locally

```bash
cd easyPosMobileBackendPhp
php -S localhost:8000 -t public
# → http://localhost:8000/api/health
```

Set DB credentials via env vars or by editing `config/config.php`:

```bash
DB_HOST=localhost DB_DATABASE=u383264767_EasyPOS DB_USERNAME=root DB_PASSWORD=secret \
  php -S localhost:8000 -t public
```

## Deploy to Hostinger

1. Upload the contents of this folder to your domain's folder (e.g. `public_html`).
2. In hPanel, ideally set the website's **document root to the `public/` folder**.
   (If you can't, the root `.htaccess` already forwards requests into `public/`.)
3. Edit `config/config.php` with the Hostinger DB name/user/password
   (hPanel → Databases → MySQL Databases), or set them as environment variables.
4. Set `'token_secret'` to a long random string and, when ready, `AUTH_REQUIRED=true`.
5. Test: `https://yourdomain/api/health` → `{"status":"ok",...}`.

## Point the Flutter app at it

In `lib/data/services/api_service.dart`, set the base URL to
`https://yourdomain/api` and replace the stub method bodies with `http` calls
to the endpoints above.

> ⚠️ The sale-creation endpoint writes to your live POS database
> (`transactions`, stock, payments). Test it against a **copy** of the database
> first to confirm the records match what the UltimatePOS web app expects.
