#!/usr/bin/env sh
# First time setup for the API: dependencies, database, schema, first admin login and CSS.
# Set DATABASE_URL, ADMIN_USERNAME and ADMIN_PASSWORD in .env.local before running this.
set -e
cd "$(dirname "$0")"

composer install
npm install

php bin/console doctrine:database:create --if-not-exists
php bin/console doctrine:migrations:migrate --no-interaction
# --append, otherwise the fixtures purge the whole database first.
php bin/console doctrine:fixtures:load --append --no-interaction

php bin/console tailwind:build

echo "Setup done."
