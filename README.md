# 🛍️ SoftGeek Online Store

![License](https://img.shields.io/github/license/SoftGeekRO/sg.webShop)
![PHP](https://img.shields.io/badge/PHP-%3E%3D8.3-blue)
![CakePHP](https://img.shields.io/badge/CakePHP-5.0-red)
![Code Style](https://img.shields.io/badge/code%20style-PSR--12-blue)
![Size](https://img.shields.io/github/repo-size/SoftGeekRO/sg.webShop)
![Build](https://img.shields.io/github/actions/workflow/status/SoftGeekRO/sg.webShop/ci.yml?branch=main)
![Issues](https://img.shields.io/github/issues/SoftGeekRO/sg.webShop)
![softgeek.ro](https://img.shields.io/website?url=https://softgeek.ro)
![progeek.ro](https://img.shields.io/website?url=https://progeek.ro)


An advanced e-commerce web application for **SoftGeek**, built with modern technologies including [CakePHP](https://cakephp.org/), [MariaDB](https://mariadb.org/), [Webpack](https://webpack.js.org/), JavaScript.

---

## 🧱 Stack Overview

| Technology | Purpose                                    |
|------------|--------------------------------------------|
| CakePHP    | PHP framework for structured backend logic |
| MariaDB    | Reliable and performant SQL database       |
| Webpack    | Asset bundler for JavaScript/CSS           |
| SCSS       | Professional grade CSS extension language  |
| JavaScript | Interactive frontend                       |

---

## 🚀 Features

- Product catalog with categories, filters, and search
- Cart and checkout system
- Customer authentication and registration
- Order management dashboard (Admin)
- Multi-language and multi-currency support
- Dynamic frontend assets via Webpack
- Page-level caching with Memcached
- Backend admin for processing the orders and manage multistore features
- API support for mobile or third-party clients

---

## 📂 Project Structure

```
/bin
/config
/logs
/plugins
/resources
/src
  /Controller
  /Model
  /Template
  /View
/templates
/test
/tmp
  /cache
/vendor
/weboot -> hard move or soft link to /var/www/webshop/weboot/
  /js
  /css
  /images
```

---

## ⚙️ Requirements

- PHP >= 8.3
- Composer >= 2.8.0
- CakePHP >= 5.2
- Node.js >= 22.15.x + NPM >= 10.9.x
- MariaDB >= 11.7.2 || Mysql >= 8.0
- Nginx >= 1.24
- webpack >= 5.99
- SASS >= 1.89.0

---

## 🔧 Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/SoftGeekRO/sg.webShop.git
cd sg.webShop
```

### 2. Install PHP Dependencies

```bash
composer install
```

### 3. Setup Environment

Copy `.env.example` to `.env` and update your database, cache, and app settings.

```bash
cp .env.example .env
```

### 4. Configure Database

Create your MariaDB database and run migrations:

```bash
bin/cake migrations migrate
```

---

## 🛠️ Development Path

### 📌 Phase 1: Core Setup

- [ ] Set up CakePHP and basic routing
- [ ] Configure database and create schema (products, categories, users, orders)
- [ ] Integrate Webpack + asset manifest loading
- [ ] Basic frontend templating using CakePHP templates
- [ ] Basic backend templating using CakePHP templates

### 📌 Phase 2: Features & Logic

- [ ] Implement offline/online mode based on backend setting
- [ ] Implement user registration/login (with CakePHP Auth)
- [ ] Implement import products from different sources csv, xls, xml, feeds
- [ ] Create product listing + filters
- [ ] Develop cart and checkout flow
- [ ] Admin dashboard for order and inventory management
- [ ] Implement the multistore features
- [ ] Integrate email notifications (orders, signups)

### 📌 Phase 3: Optimization

- [ ] Configure caching views and queries
- [ ] Enable Webpack production mode + asset versioning
- [ ] Add image compression & CDN (optional)
- [ ] Enable multi-language support (i18n)

### 📌 Phase 4: Testing & Launch

- [ ] Write unit tests and integration tests
- [ ] SEO audit and improvements
- [ ] Deploy on VPS or hosting
- [ ] Monitor logs and performance

---

## 👨‍💻 Contributing

Pull requests are welcome. Please fork and submit via a feature branch. Make sure to run:

```bash
composer test
npm run lint
```

---

## 📄 License

This project is licensed under the **MIT License**.

---

## 🧠 About SoftGeek

**SoftGeek** is a modern tech company focused on smart digital products and automation.
Visit us at [https://softgeek.ro](https://softgeek.ro)
