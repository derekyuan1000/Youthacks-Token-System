# Youthacks Token System

A token system for hackathons. Try it out at [aha.youthacks.org](https://aha.youthacks.org).

---

## Table of Contents
- [Features](#features)
- [Requirements](#requirements)
- [Installation (Windows)](#installation-windows)
- [Configuration](#configuration)
- [Running the Application](#running-the-application)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Features
- Participant and event management
- Token transactions
- Admin and manager roles
- Email notifications

## Requirements
- Ruby (see `.ruby-version` or Gemfile for version)
- Rails (see Gemfile)
- PostgreSQL
- Node.js & Yarn (for asset compilation)
- Git

## Installation (Windows)

### 1. Install Ruby and Rails
- Download and install Ruby from [rubyinstaller.org](https://rubyinstaller.org/).
- Install Rails:
  ```sh
  gem install rails
  ```

### 2. Install PostgreSQL
- Download and install PostgreSQL from [postgresql.org](https://www.postgresql.org/download/windows/).
- During installation, ensure the command line tools are included.
- Add the PostgreSQL `bin` directory (e.g., `C:\Program Files\PostgreSQL\16\bin`) to your PATH environment variable.

### 3. Install Node.js and Yarn
- Download and install Node.js from [nodejs.org](https://nodejs.org/).
- Install Yarn:
  ```sh
  npm install --global yarn
  ```

### 4. Clone the Repository
```sh
git clone https://github.com/yourusername/Youthacks-Token-System.git
cd Youthacks-Token-System
```

### 5. Install Dependencies
```sh
bundle install
yarn install
```

### 6. Database Setup
- Create a PostgreSQL user and database, or update `config/database.yml` with your credentials.
- Run:
  ```sh
  rails db:setup
  ```

---

## Configuration
- Copy `config/credentials.yml.enc` and `config/master.key` if needed (for secrets).
- Set up email server settings in `config/environments/production.rb` and/or `config/environments/development.rb`.

---

## Running the Application
```sh
rails server
```
- Visit [http://localhost:3000](http://localhost:3000) in your browser.

---

## Deployment
You can deploy this app using:
- **Heroku**: Push to a Heroku app with a PostgreSQL add-on.
- **Docker**: Use the provided `Dockerfile`:
  ```sh
  docker build -t youthacks-token-system .
  docker run -e RAILS_ENV=production -p 3000:3000 youthacks-token-system
  ```
- **VPS/Cloud**: Set up Ruby, Rails, PostgreSQL, and follow the installation steps above.

---

## Troubleshooting
- If you get errors installing the `pg` gem, ensure PostgreSQL is installed and `pg_config` is in your PATH.
- For Windows, you may need to run:
  ```sh
  gem install pg -- --with-pg-config="C:/Program Files/PostgreSQL/16/bin/pg_config.exe"
  ```
- If you have other issues, check the logs or open an issue.

---

## License
See [LICENSE](LICENSE).

## Help and Support
Add and issue on GitHub or (contact us)[mailto:matthew@youthacks.org)