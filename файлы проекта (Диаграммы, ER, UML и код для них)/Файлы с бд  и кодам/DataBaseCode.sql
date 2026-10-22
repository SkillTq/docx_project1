CREATE TABLE "users" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "role_id" uuid NOT NULL,
  "username" varchar(50) UNIQUE NOT NULL,
  "email" varchar(100) UNIQUE,
  "password_hash" text NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "roles" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "name" varchar(50) UNIQUE NOT NULL
);

CREATE TABLE "role_permissions" (
  "role_id" uuid NOT NULL,
  "permission_id" uuid NOT NULL,
  PRIMARY KEY ("role_id", "permission_id")
);

CREATE TABLE "permissions" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "name" varchar(100) UNIQUE NOT NULL
);

CREATE TABLE "applications" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "title" varchar(100) NOT NULL,
  "description" text,
  "image_url" text,
  "is_active" boolean NOT NULL DEFAULT true,
  "created_by_user_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz
);

CREATE TABLE "applications_plans" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "application_id" uuid NOT NULL,
  "name" varchar(100) NOT NULL,
  "duration_days" int NOT NULL,
  "price" decimal(10,2) NOT NULL,
  "is_active" boolean NOT NULL DEFAULT true,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz,
  CHECK (duration_days > 0),
  CHECK (price >= 0)
);

CREATE TABLE "keys" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "key_code" varchar(255) UNIQUE NOT NULL,
  "plan_id" uuid NOT NULL,
  "status" varchar(30) NOT NULL DEFAULT 'available',
  "created_by_user_id" uuid,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  CHECK (status IN ('available', 'reserved', 'sold', 'revoked'))
);

CREATE TABLE "orders" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "user_id" uuid NOT NULL,
  "status" varchar(30) NOT NULL DEFAULT 'pending_payment',
  "total_amount" decimal(10,2) NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz,
  CHECK (total_amount >= 0),
  CHECK (status IN ('pending_payment', 'paid', 'processing', 'completed', 'cancelled', 'refunded'))
);

CREATE TABLE "payments" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "order_id" uuid NOT NULL,
  "provider" varchar(50) NOT NULL,
  "provider_payment_id" varchar(255) UNIQUE,
  "amount" decimal(10,2) NOT NULL,
  "status" varchar(30) NOT NULL DEFAULT 'pending',
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "paid_at" timestamptz,
  CHECK (amount >= 0),
  CHECK (status IN ('pending', 'succeeded', 'failed', 'refunded'))
);

CREATE TABLE "order_items" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "order_id" uuid NOT NULL,
  "plan_id" uuid NOT NULL,
  "key_id" uuid UNIQUE,
  "plan_name" varchar(100) NOT NULL,
  "duration_days" int NOT NULL,
  "price" decimal(10,2) NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  CHECK (duration_days > 0),
  CHECK (price >= 0)
);

CREATE TABLE "activations" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "key_id" uuid UNIQUE NOT NULL,
  "user_id" uuid NOT NULL,
  "hwid" varchar(255) NOT NULL,
  "activated_at" timestamptz NOT NULL DEFAULT (now()),
  "expires_at" timestamptz NOT NULL,
  "deactivated_at" timestamptz,
  CHECK (expires_at > activated_at),
  CHECK (deactivated_at IS NULL OR deactivated_at >= activated_at)
);

CREATE UNIQUE INDEX ON "applications_plans" ("application_id", "duration_days");

CREATE INDEX ON "keys" ("plan_id", "status");

CREATE INDEX ON "orders" ("user_id", "created_at");

CREATE INDEX ON "orders" ("status", "created_at");

CREATE INDEX ON "payments" ("order_id", "created_at");

CREATE INDEX ON "order_items" ("order_id");

CREATE INDEX ON "activations" ("user_id", "activated_at");

CREATE INDEX ON "activations" ("key_id", "activated_at");

ALTER TABLE "users" ADD FOREIGN KEY ("role_id") REFERENCES "roles" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "role_permissions" ADD FOREIGN KEY ("role_id") REFERENCES "roles" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "role_permissions" ADD FOREIGN KEY ("permission_id") REFERENCES "permissions" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "applications" ADD FOREIGN KEY ("created_by_user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "applications_plans" ADD FOREIGN KEY ("application_id") REFERENCES "applications" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "keys" ADD FOREIGN KEY ("plan_id") REFERENCES "applications_plans" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "keys" ADD FOREIGN KEY ("created_by_user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "orders" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "payments" ADD FOREIGN KEY ("order_id") REFERENCES "orders" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order_items" ADD FOREIGN KEY ("order_id") REFERENCES "orders" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order_items" ADD FOREIGN KEY ("plan_id") REFERENCES "applications_plans" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order_items" ADD FOREIGN KEY ("key_id") REFERENCES "keys" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "activations" ADD FOREIGN KEY ("key_id") REFERENCES "keys" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "activations" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;
