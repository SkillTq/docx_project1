CREATE TABLE "user" (
  "id" SERIAL PRIMARY KEY NOT NULL,
  "username" "VARCHAR(50)" NOT NULL,
  "user_email" VARCHAR UNIQUE NOT NULL,
  "user_password" TEXT NOT NULL,
  "created_at" "timestamptz(CURRENT_TIMESTAMPTZ)"
);

CREATE TABLE "admin" (
  "id" SERIAL PRIMARY KEY NOT NULL,
  "username" "VARCAHR(100)" UNIQUE NOT NULL,
  "password" "PASSWORD_HASH" NOT NULL,
  "created_at" "timestamptz(CURRENT_TIMESTAMPTZ)"
);

CREATE TABLE "application" (
  "id" SERIAL PRIMARY KEY NOT NULL,
  "title" "VARCHAR(100)" NOT NULL,
  "created_at" "timestamptz(CURRENT_TIMESTAMPTZ)"
);

CREATE TABLE "key" (
  "id" SERIAL PRIMARY KEY NOT NULL,
  "key_kode" "VARCHAR(50)" UNIQUE NOT NULL,
  "key_duration" INT NOT NULL,
  "key_state" "BOOLEAN(false)" NOT NULL,
  "activated_at" timestamptz,
  "expires_at" timestamptz,
  "created_by" INT,
  "application_id" INT
);

CREATE TABLE "order" (
  "id" SERIAL PRIMARY KEY NOT NULL,
  "user_id" INT,
  "status" "VARCHAR(30)",
  "total_amount" "DECIMAL(5,0)" NOT NULL,
  "payment_method" "VARCHAR(30)" NOT NULL,
  "created_at" "timestamptz(CURRENT_TIMESTAMPTZ)"
);

CREATE TABLE "order_keys" (
  "id" SERIAL PRIMARY KEY NOT NULL,
  "user_id" INT,
  "order_id" INT,
  "key_id" INT,
  "duration_days" INT NOT NULL,
  "purchase_date" "timestamptz(CURRENT_TIMESTAMPTZ)"
);

CREATE TABLE "user_key" (
  "id" SERIAL PRIMARY KEY NOT NULL,
  "user_id" INT,
  "key_id" INT,
  "activation_date" timestamptz(),
  "end_date" timestamptz
);

ALTER TABLE "key" ADD FOREIGN KEY ("created_by") REFERENCES "admin" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "key" ADD FOREIGN KEY ("application_id") REFERENCES "application" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order" ADD FOREIGN KEY ("user_id") REFERENCES "user" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order_keys" ADD FOREIGN KEY ("user_id") REFERENCES "user" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order_keys" ADD FOREIGN KEY ("order_id") REFERENCES "order" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order_keys" ADD FOREIGN KEY ("key_id") REFERENCES "key" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "user_key" ADD FOREIGN KEY ("user_id") REFERENCES "user" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "user_key" ADD FOREIGN KEY ("key_id") REFERENCES "key" ("id") DEFERRABLE INITIALLY IMMEDIATE;
