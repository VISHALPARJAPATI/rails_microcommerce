# Rails Microcommerce

A small API-only e-commerce backend built with Rails 8. It handles user accounts, a product catalog with search and filters, and checkout via Stripe. Orders are created when a customer completes payment; the app can optionally cache product listings with Redis and publish order events to Kafka.

## What’s in it

- **Auth** — Sign up, sign in, sign out using Devise with JWT (no sessions; tokens in the `Authorization` header).
- **Products** — List with search, category filter, sort, and pagination. Create and update products (auth required). List responses can be cached with Redis when configured.
- **Checkout** — Create a Stripe Checkout Session from cart-style line items; the frontend redirects to Stripe to pay. A webhook marks the order completed and can publish an event to Kafka.
- **Orders** — Authenticated users can list their orders and fetch one by id.

The app is API-only (JSON only, no HTML views). It uses MySQL for data, and optionally Redis for caching and Kafka for event publishing.

## Tech stack

- **Rails 8**, **Ruby 3.4**
- **MySQL** (via `mysql2`)
- **Devise** + **devise-jwt** for API auth
- **Stripe** for payment and webhooks
- **Redis** for caching product list API (optional)
- **Kafka** (ruby-kafka) for publishing order-completed events (optional)
- **Docker** and **Kubernetes** manifests for running and deploying the app

## Running it locally

You need Ruby 3.4 and MySQL. Clone the repo, then:

```bash
bundle install
cp .env.example .env   # edit with your DB and optional keys
bin/rails db:create db:migrate db:seed   # seed adds categories and sample products
bin/rails server
```

The API is at `http://localhost:3000`. For Stripe checkout, set `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` in `.env` and configure Stripe’s webhook to `POST /stripe/webhook`. Redis and Kafka are optional: with `REDIS_URL` the product list is cached; with `KAFKA_BROKERS` completed orders are published to the `order.completed` topic.

## Tests

```bash
bundle exec rails test
```

The suite uses Minitest and includes model, service, and integration tests. Auth in integration tests uses `Devise::JWT::TestHelpers.auth_headers`.

## API overview

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/users` | No | Register (JSON: `email`, `password`, `password_confirmation`) |
| POST | `/users/sign_in` | No | Sign in (JSON: `email`, `password`) → JWT in `Authorization` |
| DELETE | `/users/sign_out` | Yes | Sign out (revokes token) |
| GET | `/me` | Yes | Current user |
| GET | `/products` | No | List products (`q`, `category_id`, `sort`, `order`, `page`, `per_page`) |
| POST | `/products` | Yes | Create product |
| PATCH | `/products/:id` | Yes | Update product |
| POST | `/checkout` | Yes | Create Stripe session (JSON: `items` array, optional `success_url` / `cancel_url`) |
| POST | `/stripe/webhook` | No | Stripe webhook (signature verified) |
| GET | `/orders` | Yes | Current user’s orders |
| GET | `/orders/:id` | Yes | One order |
| GET | `/up` | No | Health check |

Send the JWT in the header: `Authorization: Bearer <token>`.

## Environment variables

See `.env.example` for a list. Main ones:

- **Database** — `DATABASE_URL` or configure `config/database.yml`.
- **Auth** — Devise/JWT use `config/credentials` or env for the JWT secret; no extra env required for basic sign up/sign in.
- **Stripe** — `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` (or from credentials).
- **Optional** — `REDIS_URL` for product list cache; `KAFKA_BROKERS` for order events.

## Docker and Kubernetes

- **Production-style image:** `docker build -t rails_microcommerce .` — see the Dockerfile; the app listens on port 80.
- **Local stack (app + MySQL + Redis + Kafka):** `docker compose up -d` then run migrations with `docker compose run --rm app bin/rails db:create db:migrate`. Details and Kubernetes manifests (namespace, deployment, service, configmap, secret, ingress) are in the repo under `kubernetes/` and described in `docs/DOCKER_KUBERNETES.md`.

## License

MIT.
