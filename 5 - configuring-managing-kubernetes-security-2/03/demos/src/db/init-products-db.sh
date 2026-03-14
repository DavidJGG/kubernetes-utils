#!/bin/sh
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL

    CREATE TABLE public.products (
        id bigint NOT NULL,
        name character varying(255) NULL,
        price numeric(19,2) NULL,
        stock bigint NOT NULL
    );

    ALTER TABLE public.products ADD CONSTRAINT products_pkey PRIMARY KEY (id);

    INSERT INTO "public"."products" ("id", "name", "price", "stock")
        VALUES (1, 'Espresso', 4.00, 600);

    INSERT INTO "public"."products" ("id", "name", "price", "stock")
        VALUES (2, 'Americano', 5.00, 400);

    INSERT INTO "public"."products" ("id", "name", "price", "stock")
        VALUES (3, 'Flat White', 6.50, 750);

EOSQL