--
-- PostgreSQL database dump
--

\restrict 0oC8l3COQFEqbTjRT8jl1ohTJ2JagdVK3mgjVDbdezkURkxg5aiErzRXyyBIyZk

-- Dumped from database version 15.17
-- Dumped by pg_dump version 15.17

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auth;


--
-- Name: beauty; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA beauty;


--
-- Name: logic; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA logic;


--
-- Name: pos; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pos;


--
-- Name: rest; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA rest;


--
-- Name: wms; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA wms;


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: verify_login(text, text, text); Type: FUNCTION; Schema: logic; Owner: -
--

CREATE FUNCTION logic.verify_login(username text, password text, firm_nr text) RETURNS TABLE(id uuid, username text, email text, full_name text, firm_nr text, store_id uuid, role_id uuid, role_name text, role_permissions jsonb, role_color text, role_landing_route text, allowed_firm_nrs jsonb, allowed_periods jsonb, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT u.id, u.username, u.email, u.full_name, u.firm_nr, u.store_id,
         r.id, r.name, r.permissions, r.color, r.landing_route,
         u.allowed_firm_nrs, u.allowed_periods, u.created_at
  FROM public.users u
  LEFT JOIN public.roles r ON r.id = u.role_id
  WHERE u.is_active = true
    AND LOWER(u.username) = LOWER(verify_login.username)
    AND u.password_hash IS NOT NULL
    AND u.password_hash = crypt(verify_login.password, u.password_hash)
    AND (
      verify_login.firm_nr IS NULL OR verify_login.firm_nr = ''
      OR u.firm_nr = verify_login.firm_nr::text
      OR (COALESCE(jsonb_array_length(u.allowed_firm_nrs), 0) > 0
          AND u.allowed_firm_nrs @> jsonb_build_array(verify_login.firm_nr::text))
    )
  LIMIT 1;
$$;


--
-- Name: apply_sync_triggers(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apply_sync_triggers(p_table_name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I; CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON %I FOR EACH ROW EXECUTE PROCEDURE public.enqueue_sync_event();',
    'sync_trg_' || p_table_name, p_table_name, 'sync_trg_' || p_table_name, p_table_name);
END;
$$;


--
-- Name: attach_audit_log(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.attach_audit_log(p_table_name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  EXECUTE format('DROP TRIGGER IF EXISTS audit_trigger ON %I', p_table_name);
  EXECUTE format('CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON %I FOR EACH ROW EXECUTE PROCEDURE public.log_row_change()', p_table_name);
END;
$$;


--
-- Name: create_firm_tables(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_firm_tables(p_firm_nr character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_prefix    TEXT := lower('rex_' || p_firm_nr);
  v_unitset_id UUID;
BEGIN
  -- 1. Products (tam şema — tüm kolonlar dahil)
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      firm_nr           VARCHAR(10) NOT NULL,
      ref_id            INTEGER UNIQUE,
      code              VARCHAR(100) UNIQUE,
      barcode           VARCHAR(100),
      name              VARCHAR(255) NOT NULL,
      name2             VARCHAR(255),
      image_url         TEXT,
      image_url_cdn     TEXT,
      description       TEXT,
      description_tr    TEXT,
      description_en    TEXT,
      description_ar    TEXT,
      description_ku    TEXT,
      category_id       UUID,
      category_code     VARCHAR(50),
      categorycode      VARCHAR(50),
      "categoryCode"    VARCHAR(50),
      group_code        VARCHAR(50),
      groupcode         VARCHAR(50),
      "groupCode"       VARCHAR(50),
      sub_group_code    VARCHAR(50),
      subgroupcode      VARCHAR(50),
      "subGroupCode"    VARCHAR(50),
      brand             VARCHAR(100),
      model             VARCHAR(100),
      manufacturer      VARCHAR(100),
      supplier          VARCHAR(100),
      origin            VARCHAR(50),
      material_type     VARCHAR(50),
      materialtype      VARCHAR(50),
      "materialType"    VARCHAR(50),
      unit              VARCHAR(50) DEFAULT ''Adet'',
      unit2             VARCHAR(20),
      unit3             VARCHAR(20),
      unit_id           UUID,
      unitset_id        UUID,
      unitsetid         UUID,
      "unitsetId"       UUID,
      vat_rate          DECIMAL(5,2) DEFAULT 20,
      vatrate           DECIMAL(5,2) DEFAULT 20,
      "vatRate"         DECIMAL(5,2) DEFAULT 20,
      tax_type          VARCHAR(20),
      withholding_rate  DECIMAL(5,2),
      currency          VARCHAR(10) DEFAULT ''IQD'',
      price             DECIMAL(15,2) DEFAULT 0,
      cost              DECIMAL(15,2) DEFAULT 0,
      stock             DECIMAL(15,2) DEFAULT 0,
      min_stock         DECIMAL(15,2) DEFAULT 0,
      max_stock         DECIMAL(15,2) DEFAULT 0,
      critical_stock    DECIMAL(15,2) DEFAULT 0,
      tracking_type     VARCHAR(20) DEFAULT ''none'',
      shelf_location    VARCHAR(50),
      warehouse_code    VARCHAR(50),
      special_code_1    VARCHAR(50),
      special_code_2    VARCHAR(50),
      special_code_3    VARCHAR(50),
      special_code_4    VARCHAR(50),
      special_code_5    VARCHAR(50),
      special_code_6    VARCHAR(50),
      specialcode1      VARCHAR(50),
      specialcode2      VARCHAR(50),
      specialcode3      VARCHAR(50),
      specialcode4      VARCHAR(50),
      specialcode5      VARCHAR(50),
      specialcode6      VARCHAR(50),
      price_list_1      DECIMAL(15,2) DEFAULT 0,
      price_list_2      DECIMAL(15,2) DEFAULT 0,
      price_list_3      DECIMAL(15,2) DEFAULT 0,
      price_list_4      DECIMAL(15,2) DEFAULT 0,
      price_list_5      DECIMAL(15,2) DEFAULT 0,
      price_list_6      DECIMAL(15,2) DEFAULT 0,
      pricelist1        DECIMAL(15,2),
      pricelist2        DECIMAL(15,2),
      pricelist3        DECIMAL(15,2),
      pricelist4        DECIMAL(15,2),
      pricelist5        DECIMAL(15,2),
      pricelist6        DECIMAL(15,2),
      purchase_price    DECIMAL(15,4) DEFAULT 0,
      purchase_price_usd DECIMAL(15,2) DEFAULT 0,
      purchase_price_eur DECIMAL(15,2) DEFAULT 0,
      sale_price_usd    DECIMAL(15,2) DEFAULT 0,
      sale_price_eur    DECIMAL(15,2) DEFAULT 0,
      custom_exchange_rate NUMERIC DEFAULT 0,
      auto_calculate_usd BOOLEAN DEFAULT false,
      preparation_time  INTEGER DEFAULT 5,
      follow_up_reminder_days INTEGER,
      has_variants      BOOLEAN DEFAULT false,
      hasvariants       BOOLEAN DEFAULT false,
      "hasVariants"     BOOLEAN DEFAULT false,
      is_active         BOOLEAN DEFAULT true,
      created_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
      updated_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
  ', v_prefix || '_products');

  -- 2. Customers
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      firm_nr      VARCHAR(10) NOT NULL,
      code         VARCHAR(50) UNIQUE,
      name         VARCHAR(255) NOT NULL,
      phone        VARCHAR(50),
      phone2       VARCHAR(50),
      age          INTEGER,
      file_id      VARCHAR(120),
      occupation   VARCHAR(150),
      gender       VARCHAR(20),
      customer_tier VARCHAR(20) DEFAULT ''normal'',
      heard_from   VARCHAR(150),
      email        VARCHAR(255),
      tax_nr       VARCHAR(50),
      taxi_nr      VARCHAR(50),
      tax_office   VARCHAR(100),
      address      TEXT,
      city         VARCHAR(100),
      neighborhood VARCHAR(100),
      district     VARCHAR(100),
      balance      DECIMAL(15,2) DEFAULT 0,
      points       DECIMAL(15,2) DEFAULT 0,
      total_spent  DECIMAL(15,2) DEFAULT 0,
      notes        TEXT,
      is_active    BOOLEAN DEFAULT true,
      created_at   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
  ', v_prefix || '_customers');

  -- 3. Suppliers
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      firm_nr              VARCHAR(10) NOT NULL,
      code                 VARCHAR(50) UNIQUE,
      name                 VARCHAR(255) NOT NULL,
      phone                VARCHAR(50),
      email                VARCHAR(255),
      tax_nr               VARCHAR(50),
      tax_office           VARCHAR(100),
      address              TEXT,
      city                 VARCHAR(100),
      neighborhood         VARCHAR(100),
      district             VARCHAR(100),
      contact_person       VARCHAR(150),
      contact_person_phone VARCHAR(50),
      payment_terms        VARCHAR(100),
      credit_limit         DECIMAL(15,2) DEFAULT 0,
      notes                TEXT,
      balance              DECIMAL(15,2) DEFAULT 0,
      is_active            BOOLEAN DEFAULT true,
      created_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
  ', v_prefix || '_suppliers');

  -- 3b. Services (hizmet kartları — fatura / Excel / kasa)
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      firm_nr VARCHAR(10) NOT NULL,
      code VARCHAR(100) NOT NULL,
      name VARCHAR(255) NOT NULL,
      description TEXT,
      description_tr TEXT,
      description_en TEXT,
      description_ar TEXT,
      description_ku TEXT,
      category VARCHAR(255),
      category_id UUID,
      category_code VARCHAR(50),
      brand VARCHAR(100),
      model VARCHAR(100),
      manufacturer VARCHAR(100),
      supplier VARCHAR(100),
      origin VARCHAR(50),
      group_code VARCHAR(50),
      sub_group_code VARCHAR(50),
      special_code_1 VARCHAR(50),
      special_code_2 VARCHAR(50),
      special_code_3 VARCHAR(50),
      special_code_4 VARCHAR(50),
      special_code_5 VARCHAR(50),
      special_code_6 VARCHAR(50),
      unit VARCHAR(50) DEFAULT ''Adet'',
      unit_price DECIMAL(15,2) DEFAULT 0,
      unit_price_usd DECIMAL(15,2) DEFAULT 0,
      unit_price_eur DECIMAL(15,2) DEFAULT 0,
      purchase_price DECIMAL(15,2) DEFAULT 0,
      purchase_price_usd DECIMAL(15,2) DEFAULT 0,
      purchase_price_eur DECIMAL(15,2) DEFAULT 0,
      tax_rate DECIMAL(5,2) DEFAULT 18,
      tax_type VARCHAR(20),
      withholding_rate DECIMAL(5,2) DEFAULT 0,
      discount1 DECIMAL(15,2) DEFAULT 0,
      discount2 DECIMAL(15,2) DEFAULT 0,
      discount3 DECIMAL(15,2) DEFAULT 0,
      image_url TEXT,
      price_list_1 DECIMAL(15,2) DEFAULT 0,
      price_list_2 DECIMAL(15,2) DEFAULT 0,
      price_list_3 DECIMAL(15,2) DEFAULT 0,
      price_list_4 DECIMAL(15,2) DEFAULT 0,
      price_list_5 DECIMAL(15,2) DEFAULT 0,
      price_list_6 DECIMAL(15,2) DEFAULT 0,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT %I UNIQUE (firm_nr, code)
    );
  ', v_prefix || '_services', v_prefix || '_services_firm_code_uq');

  -- 4. Definitions (Categories, Brands, Units)
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      code          VARCHAR(50) UNIQUE,
      name          VARCHAR(255) NOT NULL,
      description   TEXT,
      parent_id     UUID,
      is_restaurant BOOLEAN DEFAULT false,
      icon          VARCHAR(100),
      is_active     BOOLEAN DEFAULT true,
      created_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
  ', v_prefix || '_categories');

  EXECUTE format('CREATE TABLE IF NOT EXISTS %I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), code VARCHAR(50) UNIQUE, name VARCHAR(255) NOT NULL, description TEXT, is_active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP);', v_prefix || '_brands');
  EXECUTE format('CREATE TABLE IF NOT EXISTS %I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), code VARCHAR(20) UNIQUE, name VARCHAR(100) NOT NULL, description TEXT, is_active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP);', v_prefix || '_units');

  -- Tax Rates
  EXECUTE format('CREATE TABLE IF NOT EXISTS %I (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rate        DECIMAL(5,2) NOT NULL,
    description VARCHAR(255),
    is_active   BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
  );', v_prefix || '_tax_rates');

  -- Special Codes
  EXECUTE format('CREATE TABLE IF NOT EXISTS %I (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code        VARCHAR(50),
    name        VARCHAR(255) NOT NULL,
    description TEXT,
    module_type VARCHAR(50),
    is_active   BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
  );', v_prefix || '_special_codes');

  -- Seed standard tax rates
  EXECUTE format('INSERT INTO %I (rate, description) VALUES
    (0,    ''Vergisiz''),
    (1,    ''%%1 KDV''),
    (8,    ''%%8 KDV''),
    (10,   ''%%10 KDV''),
    (18,   ''%%18 KDV''),
    (20,   ''%%20 KDV'')
    ON CONFLICT DO NOTHING;', v_prefix || '_tax_rates');

  -- Seed standard units (Comprehensive list matching default unit sets)
  EXECUTE format('INSERT INTO %I (code, name) VALUES 
    (''ADET'', ''Adet''), (''KG'', ''Kilogram''), (''GRAM'', ''Gram''), (''TON'', ''Ton''),
    (''METRE'', ''Metre''), (''TOP'', ''Top''), (''LITRE'', ''Litre''), (''ML'', ''Mililitre''),
    (''PAKET'', ''Paket''), (''KOLI'', ''Koli''), (''PALET'', ''Palet''), (''DUZINE'', ''Düzine''),
    (''M2'', ''Metrekare''), (''SAAT'', ''Saat''), (''DAK'', ''Dakika''), (''KUTU'', ''Kutu''),
    (''SET'', ''Set''), (''PARCA'', ''Parca''), (''SISE'', ''Sise''), (''KASA'', ''Kasa'')
    ON CONFLICT (code) DO NOTHING;', v_prefix || '_units');

  -- 5. Unit Sets & Lines (tam şema — code, name, main_unit, conv_fact1, conv_fact2)
  EXECUTE format('CREATE TABLE IF NOT EXISTS %I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), code VARCHAR(50) UNIQUE, name VARCHAR(255) NOT NULL, is_active BOOLEAN DEFAULT true);', v_prefix || '_unitsets');
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      unitset_id  UUID,
      item_code   VARCHAR(20) NOT NULL,
      code        VARCHAR(50),
      name        VARCHAR(100),
      main_unit   BOOLEAN DEFAULT false,
      multiplier1 DECIMAL(15,2) DEFAULT 1,
      multiplier2 DECIMAL(15,2) DEFAULT 1,
      conv_fact1  DECIMAL(15,6) DEFAULT 1,
      conv_fact2  DECIMAL(15,6) DEFAULT 1,
      CONSTRAINT %I UNIQUE(unitset_id, item_code)
    );
  ', v_prefix || '_unitsetl', v_prefix || '_unitsetl_unique');

  -- 6. Product Variants
  EXECUTE format('CREATE TABLE IF NOT EXISTS %I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), product_id UUID, sku VARCHAR(100) UNIQUE, attributes JSONB);', v_prefix || '_product_variants');

  -- 6b. Product Barcodes (multiple barcodes per product, each with its own unit)
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      product_id   UUID NOT NULL,
      barcode_code VARCHAR(100) NOT NULL,
      unit         VARCHAR(50),
      sale_price   DECIMAL(15,2) DEFAULT 0,
      is_primary   BOOLEAN DEFAULT false,
      created_at   TIMESTAMPTZ DEFAULT NOW()
    );
  ', v_prefix || '_product_barcodes');

  -- 6c. Product Unit Conversions (e.g. 1 Koli = 12 Adet)
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      product_id UUID NOT NULL,
      from_unit  VARCHAR(50) NOT NULL,
      to_unit    VARCHAR(50) NOT NULL,
      factor     DECIMAL(15,6) NOT NULL DEFAULT 1,
      created_at TIMESTAMPTZ DEFAULT NOW()
    );
  ', v_prefix || '_product_unit_conversions');

  -- 7. Campaigns
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      firm_nr               VARCHAR(10) NOT NULL,
      name                  VARCHAR(255) NOT NULL,
      description           TEXT,
      type                  VARCHAR(50) NOT NULL,
      discount_type         VARCHAR(50) NOT NULL,
      discount_value        DECIMAL(15,2) DEFAULT 0,
      start_date            TIMESTAMPTZ,
      end_date              TIMESTAMPTZ,
      is_active             BOOLEAN DEFAULT true,
      min_purchase_amount   DECIMAL(15,2) DEFAULT 0,
      max_discount_amount   DECIMAL(15,2),
      applicable_categories VARCHAR(255),
      applicable_products   JSONB DEFAULT ''[]'',
      priority              INTEGER DEFAULT 0,
      created_at            TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
      updated_at            TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
  ', v_prefix || '_campaigns');

  -- 8. Finance Registers
  EXECUTE format('CREATE TABLE IF NOT EXISTS %I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), firm_nr VARCHAR(10) NOT NULL, code VARCHAR(50) UNIQUE, name VARCHAR(255) NOT NULL, currency_code VARCHAR(10) DEFAULT ''IQD'', balance DECIMAL(15,2) DEFAULT 0, is_active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW());', v_prefix || '_cash_registers');
  EXECUTE format('CREATE TABLE IF NOT EXISTS %I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), firm_nr VARCHAR(10) NOT NULL, code VARCHAR(50) UNIQUE, name VARCHAR(255) NOT NULL, bank_name VARCHAR(255), iban VARCHAR(50), currency_code VARCHAR(10) DEFAULT ''IQD'', balance DECIMAL(15,2) DEFAULT 0, is_active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW());', v_prefix || '_bank_registers');
  EXECUTE format('CREATE TABLE IF NOT EXISTS %I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), firm_nr VARCHAR(10) NOT NULL, code VARCHAR(50) UNIQUE, name VARCHAR(255) NOT NULL, description TEXT, is_active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW());', v_prefix || '_expense_cards');
  EXECUTE format('CREATE TABLE IF NOT EXISTS %I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), firm_nr VARCHAR(10) NOT NULL, code VARCHAR(50) UNIQUE, name VARCHAR(255) NOT NULL, phone VARCHAR(50), email VARCHAR(255), is_active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW());', v_prefix || '_sales_reps');

  -- Sync Triggers
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_products');
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_customers');
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_suppliers');
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_services');
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_cash_registers');
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_bank_registers');
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_expense_cards');
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_sales_reps');
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_categories');
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_brands');
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_units');
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_tax_rates');
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_special_codes');
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_campaigns');

  -- ═══════════════════════════════════════════════════════════════════
  -- STANDART BİRİM SETLERİ — tüm perakende/toptan senaryoları
  -- Ana birim = faturada varsayılan olarak kullanılan birim
  -- conv_fact1 = "1 ana birimde kaç alt birim var" (stok çarpanı)
  -- ═══════════════════════════════════════════════════════════════════

  -- 01 · Tekil (sadece Adet)
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''01-ADET'', ''Tekil (Adet)'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''ADET'', ''ADET'', ''Adet'', true, 1, 1 FROM %I WHERE code = ''01-ADET'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- 02 · Kilogram / Gram
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''02-KG'', ''Kilogram / Gram'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''KG'',   ''KG'',   ''Kilogram'', true,  1,    1 FROM %I WHERE code = ''02-KG'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''GRAM'', ''GRAM'', ''Gram'',     false, 1000, 1 FROM %I WHERE code = ''02-KG'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- 03 · Litre / Mililitre
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''03-LT'', ''Litre / Mililitre'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''LT'', ''LT'', ''Litre'',     true,  1,    1 FROM %I WHERE code = ''03-LT'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''ML'', ''ML'', ''Mililitre'', false, 1000, 1 FROM %I WHERE code = ''03-LT'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- 04 · Koli (6 Adet) — büyük ürünler / elektrikli ev aletleri
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''04-KOLI6'', ''Koli (6 Adet)'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''ADET'', ''ADET'', ''Adet'', true,  1, 1 FROM %I WHERE code = ''04-KOLI6'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''KOLI'', ''KOLI'', ''Koli'', false, 6, 1 FROM %I WHERE code = ''04-KOLI6'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- 05 · Koli (12 Adet) — içecek / deterjan
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''05-KOLI12'', ''Koli (12 Adet)'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''ADET'', ''ADET'', ''Adet'', true,  1,  1 FROM %I WHERE code = ''05-KOLI12'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''KOLI'', ''KOLI'', ''Koli'', false, 12, 1 FROM %I WHERE code = ''05-KOLI12'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- 06 · Koli (24 Adet) — su / küçük gıda ürünleri
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''06-KOLI24'', ''Koli (24 Adet)'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''ADET'', ''ADET'', ''Adet'', true,  1,  1 FROM %I WHERE code = ''06-KOLI24'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''KOLI'', ''KOLI'', ''Koli'', false, 24, 1 FROM %I WHERE code = ''06-KOLI24'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- 07 · Koli (48 Adet) — küçük paket ürünler / atıştırmalık
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''07-KOLI48'', ''Koli (48 Adet)'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''ADET'', ''ADET'', ''Adet'', true,  1,  1 FROM %I WHERE code = ''07-KOLI48'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''KOLI'', ''KOLI'', ''Koli'', false, 48, 1 FROM %I WHERE code = ''07-KOLI48'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- 08 · Adet / Koli (12) / Palet (144) — 3 kademeli hiyerarşi
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''08-PALET'', ''Adet / Koli(12) / Palet(144)'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''ADET'',  ''ADET'',  ''Adet'',  true,  1,   1 FROM %I WHERE code = ''08-PALET'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''KOLI'',  ''KOLI'',  ''Koli'',  false, 12,  1 FROM %I WHERE code = ''08-PALET'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''PALET'', ''PALET'', ''Palet'', false, 144, 1 FROM %I WHERE code = ''08-PALET'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- 09 · Düzine (12 Adet) — küçük aksesuar / tuhafiye
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''09-DUZINE'', ''Düzine (12 Adet)'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''ADET'',   ''ADET'',   ''Adet'',   true,  1,  1 FROM %I WHERE code = ''09-DUZINE'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''DUZINE'', ''DUZINE'', ''Düzine'', false, 12, 1 FROM %I WHERE code = ''09-DUZINE'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- 10 · Paket (10 Adet) — kırtasiye / ilaç / ambalaj
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''10-PKT10'', ''Paket (10 Adet)'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''ADET'',  ''ADET'',  ''Adet'',  true,  1,  1 FROM %I WHERE code = ''10-PKT10'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''PAKET'', ''PAKET'', ''Paket'', false, 10, 1 FROM %I WHERE code = ''10-PKT10'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- 11 · Paket (5 Adet) — güzellik / sağlık ürünleri
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''11-PKT5'', ''Paket (5 Adet)'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''ADET'',  ''ADET'',  ''Adet'',  true,  1, 1 FROM %I WHERE code = ''11-PKT5'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''PAKET'', ''PAKET'', ''Paket'', false, 5, 1 FROM %I WHERE code = ''11-PKT5'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- 12 · Metre / Top (50m) — tekstil / kumaş
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''12-METRE-TOP50'', ''Metre / Top (50m)'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''METRE'', ''METRE'', ''Metre'', true,  1,  1 FROM %I WHERE code = ''12-METRE-TOP50'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''TOP'',   ''TOP'',   ''Top'',   false, 50, 1 FROM %I WHERE code = ''12-METRE-TOP50'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- 13 · Metre / Top (100m) — halı / ip / büyük rulolar
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''13-METRE-TOP100'', ''Metre / Top (100m)'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''METRE'', ''METRE'', ''Metre'', true,  1,   1 FROM %I WHERE code = ''13-METRE-TOP100'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''TOP'',   ''TOP'',   ''Top'',   false, 100, 1 FROM %I WHERE code = ''13-METRE-TOP100'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- 14 · KG / Ton — demir-çelik / inşaat malzemesi
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''14-KG-TON'', ''Kilogram / Ton'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''KG'',  ''KG'',  ''Kilogram'', true,  1,    1 FROM %I WHERE code = ''14-KG-TON'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''TON'', ''TON'', ''Ton'',      false, 1000, 1 FROM %I WHERE code = ''14-KG-TON'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- 15 · Metrekare (M²) — zemin / fayans / cam
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''15-M2'', ''Metrekare (M²)'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''M2'', ''M2'', ''Metrekare'', true, 1, 1 FROM %I WHERE code = ''15-M2'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- 16 · Saat / Dakika — hizmet / iş gücü
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''16-SAAT'', ''Saat / Dakika'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''SAAT'', ''SAAT'', ''Saat'',    true,  1,  1 FROM %I WHERE code = ''16-SAAT'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''DAK'',  ''DAK'',  ''Dakika'',  false, 60, 1 FROM %I WHERE code = ''16-SAAT'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- 17 · Kutu / Adet — ilaç / kimyasal / ampul
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''17-KUTU'', ''Kutu / Adet'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''ADET'', ''ADET'', ''Adet'', true,  1,  1 FROM %I WHERE code = ''17-KUTU'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''KUTU'', ''KUTU'', ''Kutu'', false, 10, 1 FROM %I WHERE code = ''17-KUTU'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- 18 · Set (Takım) — mobilya / spor ekipmanı
  EXECUTE format('INSERT INTO %I (code, name) VALUES (''18-SET'', ''Set / Parca'') ON CONFLICT (code) DO NOTHING;', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''SET'',   ''SET'',   ''Set'',   true,  1, 1 FROM %I WHERE code = ''18-SET'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');
  EXECUTE format('INSERT INTO %I (unitset_id, item_code, code, name, main_unit, conv_fact1, conv_fact2) SELECT id, ''PARCA'', ''PARCA'', ''Parca'', false, 1, 1 FROM %I WHERE code = ''18-SET'' ON CONFLICT DO NOTHING;', v_prefix || '_unitsetl', v_prefix || '_unitsets');

  -- Varsayılan Kasa
  EXECUTE format('INSERT INTO %I (id, firm_nr, code, name, is_active) VALUES (''00000000-0000-0000-0000-000000000001'', %L, ''KASA.001'', ''MERKEZ KASA'', true) ON CONFLICT DO NOTHING;', v_prefix || '_cash_registers', p_firm_nr);
END;
$$;


--
-- Name: create_period_tables(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_period_tables(p_firm_nr character varying, p_period_nr character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_prefix       TEXT := lower('rex_' || p_firm_nr || '_' || p_period_nr);
  v_tbl_sales    TEXT := v_prefix || '_sales';
  v_tbl_items    TEXT := v_prefix || '_sale_items';
BEGIN
  -- 1. Sales Header
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      firm_nr        VARCHAR(10) NOT NULL,
      period_nr      VARCHAR(10) NOT NULL,
      fiche_no       VARCHAR(100) UNIQUE,
      document_no    VARCHAR(100),
      trcode         INTEGER,
      fiche_type     VARCHAR(50),
      date           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
      customer_id    UUID,
      customer_name  VARCHAR(255),
      store_id       UUID REFERENCES stores(id),
      total_net      DECIMAL(15,2) DEFAULT 0,
      total_vat      DECIMAL(15,2) DEFAULT 0,
      total_gross    DECIMAL(15,2) DEFAULT 0,
      total_discount DECIMAL(15,2) DEFAULT 0,
      net_amount     DECIMAL(15,2) DEFAULT 0,
      total_cost     DECIMAL(15,2) DEFAULT 0,
      gross_profit   DECIMAL(15,2) DEFAULT 0,
      profit_margin  DECIMAL(15,2) DEFAULT 0,
      currency       VARCHAR(10) DEFAULT ''IQD'',
      currency_rate  DECIMAL(15,6) DEFAULT 1,
      status         VARCHAR(20) DEFAULT ''completed'',
      logo_sync_status VARCHAR(20) DEFAULT ''pending'',
      payment_method VARCHAR(50),
      cashier        VARCHAR(100),
      is_cancelled   BOOLEAN DEFAULT false,
      credit_amount  DECIMAL(15,2) DEFAULT 0,
      notes          TEXT,
      created_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
      updated_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
  ', v_tbl_sales);

  -- 2. Sale Items (kur desteği + birim çarpan dahil)
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      invoice_id      UUID REFERENCES %I(id) ON DELETE CASCADE,
      firm_nr         VARCHAR(10),
      period_nr       VARCHAR(10),
      item_code       VARCHAR(100),
      item_name       VARCHAR(255),
      product_id      UUID,
      quantity        DECIMAL(15,3) NOT NULL,
      unit_price      DECIMAL(15,2) NOT NULL,
      vat_rate        DECIMAL(5,2) DEFAULT 0,
      discount_rate   DECIMAL(15,4) DEFAULT 0,
      discount_amount DECIMAL(15,2) DEFAULT 0,
      total_amount    DECIMAL(15,2) DEFAULT 0,
      net_amount      DECIMAL(15,2) NOT NULL,
      unit_cost       DECIMAL(15,2) DEFAULT 0,
      total_cost      DECIMAL(15,2) DEFAULT 0,
      gross_profit    DECIMAL(15,2) DEFAULT 0,
      unit            VARCHAR(20) DEFAULT ''Adet'',
      unit_multiplier DECIMAL(15,6) DEFAULT 1,
      base_quantity   DECIMAL(15,3),
      unit_price_fc   DECIMAL(15,4) DEFAULT 0,
      currency        VARCHAR(10) DEFAULT ''IQD''
    );
  ', v_tbl_items, v_tbl_sales);

  -- 3. Cash Transactions
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      firm_nr              VARCHAR(10) NOT NULL,
      period_nr            VARCHAR(10),
      register_id          UUID,
      fiche_no             VARCHAR(100) UNIQUE,
      date                 TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
      amount               DECIMAL(15,2) DEFAULT 0,
      sign                 INTEGER DEFAULT 1,
      trcode               INTEGER,
      definition           TEXT,
      transaction_type     VARCHAR(50),
      customer_id          UUID,
      bank_id              UUID,
      bank_account_id      UUID,
      target_register_id   UUID,
      expense_card_id      UUID,
      currency_code        VARCHAR(10) DEFAULT ''IQD'',
      exchange_rate        DECIMAL(15,6) DEFAULT 1,
      f_amount             DECIMAL(15,2) DEFAULT 0,
      transfer_status      INTEGER DEFAULT 0,
      special_code         VARCHAR(50),
      tax_rate             DECIMAL(5,2) DEFAULT 0,
      withholding_tax_rate DECIMAL(5,2) DEFAULT 0,
      created_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
  ', v_prefix || '_cash_lines');

  -- 4. Bank Transactions
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      firm_nr          VARCHAR(10) NOT NULL,
      period_nr        VARCHAR(10),
      register_id      UUID,
      fiche_no         VARCHAR(100) UNIQUE,
      date             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
      amount           DECIMAL(15,2) DEFAULT 0,
      sign             INTEGER DEFAULT 1,
      trcode           INTEGER,
      definition       TEXT,
      transaction_type VARCHAR(50),
      customer_id      UUID,
      cash_register_id UUID,
      currency_code    VARCHAR(10) DEFAULT ''IQD'',
      exchange_rate    DECIMAL(15,6) DEFAULT 1,
      f_amount         DECIMAL(15,2) DEFAULT 0,
      created_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
  ', v_prefix || '_bank_lines');

  -- 5. Virman (Warehouse Transfer Notes)
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      firm_nr          VARCHAR(10) NOT NULL,
      period_nr        VARCHAR(10),
      virman_no        VARCHAR(100) NOT NULL,
      from_warehouse_id UUID,
      to_warehouse_id  UUID,
      operation_date   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
      status           VARCHAR(50) DEFAULT ''draft'',
      notes            TEXT,
      created_by       VARCHAR(100),
      created_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
      updated_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
  ', v_prefix || '_virman_operations');

  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      virman_id   UUID REFERENCES %I(id) ON DELETE CASCADE,
      product_id  UUID,
      quantity    DECIMAL(15,4) DEFAULT 0,
      notes       TEXT,
      created_at  TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
  ', v_prefix || '_virman_items', v_prefix || '_virman_operations');

  -- 6. Stock Movements (Header)
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      firm_nr          VARCHAR(10) NOT NULL,
      period_nr        VARCHAR(10) NOT NULL,
      document_no      VARCHAR(50) UNIQUE,
      trcode           INTEGER,
      movement_type    VARCHAR(20), -- ''in'' | ''out'' | ''transfer'' | ''adjustment''
      warehouse_id     UUID REFERENCES stores(id),
      target_warehouse_id UUID REFERENCES stores(id),
      movement_date    TIMESTAMPTZ DEFAULT NOW(),
      exchange_rate    NUMERIC DEFAULT 1,
      description      TEXT,
      status           VARCHAR(20) DEFAULT ''completed'',
      created_by       UUID,
      created_at       TIMESTAMPTZ DEFAULT NOW(),
      updated_at       TIMESTAMPTZ DEFAULT NOW()
    );
  ', v_prefix || '_stock_movements');

  -- 7. Stock Movement Items (Lines)
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I (
      id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      movement_id      UUID REFERENCES %I(id) ON DELETE CASCADE,
      product_id       UUID,
      quantity         DECIMAL(15,4) DEFAULT 0,
      unit_price       DECIMAL(15,2) DEFAULT 0,
      cost_price       DECIMAL(15,2) DEFAULT 0,
      exchange_rate    NUMERIC DEFAULT 1,
      unit_name        VARCHAR(100),
      convert_factor   NUMERIC DEFAULT 1,
      notes            TEXT,
      created_at       TIMESTAMPTZ DEFAULT NOW()
    );
  ', v_prefix || '_stock_movement_items', v_prefix || '_stock_movements');

  PERFORM public.APPLY_SYNC_TRIGGERS(v_tbl_sales);
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_cash_lines');
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_bank_lines');
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_stock_movements');
  PERFORM public.APPLY_SYNC_TRIGGERS(v_prefix || '_stock_movement_items');
END;
$$;


--
-- Name: enqueue_sync_event(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enqueue_sync_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_firm_nr  VARCHAR;
  v_record_id UUID;
  v_data     JSONB;
BEGIN
  BEGIN
    IF (TG_OP = 'DELETE') THEN
      v_firm_nr := OLD.firm_nr; v_record_id := OLD.id; v_data := row_to_json(OLD)::JSONB;
    ELSE
      v_firm_nr := NEW.firm_nr; v_record_id := NEW.id; v_data := row_to_json(NEW)::JSONB;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_firm_nr := '001';
    IF (TG_OP = 'DELETE') THEN v_record_id := OLD.id; v_data := row_to_json(OLD)::JSONB;
    ELSE v_record_id := NEW.id; v_data := row_to_json(NEW)::JSONB; END IF;
  END;
  UPDATE sync_queue SET data = v_data, action = TG_OP, created_at = NOW()
  WHERE table_name = TG_TABLE_NAME AND record_id = v_record_id AND status = 'pending';
  IF NOT FOUND THEN
    INSERT INTO sync_queue (table_name, record_id, action, firm_nr, data)
    VALUES (TG_TABLE_NAME, v_record_id, TG_OP, v_firm_nr, v_data);
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: init_beauty_firm_tables(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.init_beauty_firm_tables(p_firm_nr character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE v_prefix TEXT := lower('rex_' || p_firm_nr);
BEGIN
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name VARCHAR(255) NOT NULL, phone VARCHAR(50), email VARCHAR(255), specialty VARCHAR(100), color VARCHAR(20) DEFAULT ''#9333ea'', commission_rate DECIMAL(5,2) DEFAULT 0, product_unit_commission DECIMAL(15,2) NOT NULL DEFAULT 0, avatar_url TEXT, working_hours JSONB, is_active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_specialists');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name VARCHAR(255) NOT NULL, category VARCHAR(50) DEFAULT ''beauty'', parent_category VARCHAR(100), duration_min INTEGER DEFAULT 30, price DECIMAL(15,2) DEFAULT 0, cost_price DECIMAL(15,2) DEFAULT 0, color VARCHAR(20) DEFAULT ''#9333ea'', commission_rate DECIMAL(5,2) DEFAULT 0, description TEXT, requires_device BOOLEAN DEFAULT false, expected_shots INTEGER DEFAULT 0, default_sessions INTEGER NOT NULL DEFAULT 1, follow_up_reminder_days INTEGER, is_active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_services');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name VARCHAR(255) NOT NULL, description TEXT, service_id UUID, total_sessions INTEGER DEFAULT 1, price DECIMAL(15,2) DEFAULT 0, cost_price DECIMAL(15,2) DEFAULT 0, discount_pct DECIMAL(5,2) DEFAULT 0, validity_days INTEGER DEFAULT 365, color VARCHAR(20) DEFAULT ''#6366f1'', is_active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_packages');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name VARCHAR(255) NOT NULL, device_type VARCHAR(50) DEFAULT ''laser'', serial_number VARCHAR(100), manufacturer VARCHAR(100), model VARCHAR(100), total_shots BIGINT DEFAULT 0, max_shots BIGINT DEFAULT 500000, maintenance_due DATE, last_maintenance DATE, purchase_date DATE, warranty_expiry DATE, status VARCHAR(20) DEFAULT ''active'', notes TEXT, is_active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_devices');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name VARCHAR(255) NOT NULL, phone VARCHAR(50), email VARCHAR(255), source VARCHAR(30) DEFAULT ''other'', status VARCHAR(30) DEFAULT ''new'', interested_services JSONB DEFAULT ''[]'', notes TEXT, assigned_to UUID, first_contact_date DATE DEFAULT CURRENT_DATE, last_contact_date DATE, converted_customer_id UUID, lost_reason TEXT, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_leads');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name VARCHAR(255) NOT NULL, is_active BOOLEAN DEFAULT false, sort_order INTEGER DEFAULT 0, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_satisfaction_surveys');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), survey_id UUID NOT NULL REFERENCES beauty.%I(id) ON DELETE CASCADE, sort_order INTEGER DEFAULT 0, question_type VARCHAR(30) DEFAULT ''rating'', scale_max SMALLINT DEFAULT 5, is_required BOOLEAN DEFAULT true, labels_json JSONB NOT NULL DEFAULT ''{}''::jsonb, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_satisfaction_questions', v_prefix || '_beauty_satisfaction_surveys');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name VARCHAR(255) NOT NULL, address TEXT, phone VARCHAR(50), is_active BOOLEAN DEFAULT true, sort_order INTEGER DEFAULT 0, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_branches');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), branch_id UUID, name VARCHAR(255) NOT NULL, capacity INTEGER DEFAULT 1, is_active BOOLEAN DEFAULT true, sort_order INTEGER DEFAULT 0, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_rooms');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), online_booking_enabled BOOLEAN DEFAULT false, allow_staff_slot_overlap BOOLEAN DEFAULT false, public_slug VARCHAR(120), public_token VARCHAR(128) NOT NULL DEFAULT encode(gen_random_bytes(24), ''hex''), reminder_hours_before SMALLINT DEFAULT 24, sms_template TEXT, whatsapp_template TEXT, sms_user VARCHAR(255), sms_password VARCHAR(255), sms_sender VARCHAR(80), whatsapp_provider VARCHAR(30) DEFAULT ''NONE'', whatsapp_base_url TEXT, whatsapp_token TEXT, whatsapp_instance_id VARCHAR(255), whatsapp_phone_id VARCHAR(80), default_reminder_channel VARCHAR(20) DEFAULT ''sms'', created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_portal_settings');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name VARCHAR(255) NOT NULL, tax_nr VARCHAR(50), discount_pct DECIMAL(5,2) DEFAULT 0, notes TEXT, is_active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_corporate_accounts');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), title VARCHAR(255) NOT NULL, body_html TEXT, is_active BOOLEAN DEFAULT true, sort_order INTEGER DEFAULT 0, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_consent_templates');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name VARCHAR(255) NOT NULL, monthly_price DECIMAL(15,2) DEFAULT 0, session_credit INTEGER DEFAULT 0, benefits_json JSONB DEFAULT ''{}''::jsonb, is_active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_memberships');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), service_id UUID NOT NULL, product_id UUID NOT NULL, qty_per_service DECIMAL(15,4) NOT NULL DEFAULT 1, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_service_consumables');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (customer_id UUID PRIMARY KEY, allergies TEXT, medications TEXT, pregnancy BOOLEAN DEFAULT false, chronic_notes TEXT, warnings_banner TEXT, kvkk_consent_at TIMESTAMPTZ, updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_customer_health');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), product_id UUID NOT NULL, lot_code VARCHAR(80), expiry_date DATE, qty DECIMAL(15,3) DEFAULT 0, barcode VARCHAR(80), created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_product_batches');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name VARCHAR(255) NOT NULL, channel VARCHAR(30) DEFAULT ''sms'', segment_filter_json JSONB DEFAULT ''{}''::jsonb, message_template TEXT, scheduled_at TIMESTAMPTZ, status VARCHAR(20) DEFAULT ''draft'', sent_count INTEGER DEFAULT 0, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_marketing_campaigns');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id SMALLINT PRIMARY KEY DEFAULT 1 CHECK (id = 1), google_calendar_id TEXT, external_calendar_json JSONB DEFAULT ''{}''::jsonb, updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_integration_settings');
  EXECUTE format('INSERT INTO beauty.%I (id) VALUES (1) ON CONFLICT (id) DO NOTHING', v_prefix || '_beauty_integration_settings');
  EXECUTE format(
    'CREATE TABLE IF NOT EXISTS beauty.%I (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      firm_nr VARCHAR(10) NOT NULL,
      customer_id UUID NOT NULL,
      service_id UUID NOT NULL,
      product_id UUID,
      reminder_kind VARCHAR(20) NOT NULL DEFAULT ''service'',
      last_completed_date DATE NOT NULL,
      natural_due_date DATE NOT NULL,
      reminder_days INTEGER,
      customer_name VARCHAR(255),
      customer_phone VARCHAR(50),
      service_name VARCHAR(255),
      product_name VARCHAR(255),
      status VARCHAR(30) NOT NULL DEFAULT ''due'',
      postponed_due_date DATE,
      note TEXT,
      created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    )',
    v_prefix || '_follow_up_reminder_actions'
  );
  EXECUTE format(
    'CREATE UNIQUE INDEX IF NOT EXISTS %I ON beauty.%I (
      customer_id, service_id, COALESCE(product_id, ''00000000-0000-0000-0000-000000000000''::uuid),
      last_completed_date, natural_due_date, reminder_kind
    )',
    v_prefix || '_follow_up_reminder_actions_uniq',
    v_prefix || '_follow_up_reminder_actions'
  );
  EXECUTE format(
    'CREATE INDEX IF NOT EXISTS %I ON beauty.%I (postponed_due_date)',
    v_prefix || '_follow_up_reminder_actions_postponed_idx',
    v_prefix || '_follow_up_reminder_actions'
  );
END;
$$;


--
-- Name: init_beauty_period_tables(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.init_beauty_period_tables(p_firm_nr character varying, p_period_nr character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE v_prefix TEXT := lower('rex_' || p_firm_nr || '_' || p_period_nr);
BEGIN
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), client_id UUID, service_id UUID, specialist_id UUID, device_id UUID, body_region_id UUID, appointment_date DATE, appointment_time TIME, duration INTEGER DEFAULT 30, status VARCHAR(20) DEFAULT ''scheduled'', type VARCHAR(20) DEFAULT ''regular'', notes TEXT, total_price DECIMAL(15,2) DEFAULT 0, commission_amount DECIMAL(15,2) DEFAULT 0, is_package_session BOOLEAN DEFAULT false, package_purchase_id UUID, reminder_sent BOOLEAN DEFAULT false, branch_id UUID, room_id UUID, tele_meeting_url TEXT, booking_channel VARCHAR(40) DEFAULT ''staff'', corporate_account_id UUID, reminder_sent_at TIMESTAMPTZ, last_notification_channel VARCHAR(30), session_series_id UUID, confirmation_call_at TIMESTAMPTZ, pre_visit_activity_at TIMESTAMPTZ, treatment_degree VARCHAR(80), treatment_shots VARCHAR(80), clinical_data JSONB DEFAULT ''{}''::jsonb, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_appointments');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), customer_id UUID, specialist_id UUID, service_id UUID, appointment_id UUID, session_date DATE DEFAULT CURRENT_DATE, shots_used INTEGER DEFAULT 0, skin_type VARCHAR(20), before_photo TEXT, after_photo TEXT, notes TEXT, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_sessions');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), package_purchase_id UUID, appointment_id UUID, session_number INTEGER, recorded_at TIMESTAMPTZ DEFAULT NOW())', v_prefix || '_beauty_session_logs');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), customer_id UUID, package_id UUID, total_sessions INTEGER DEFAULT 1, used_sessions INTEGER DEFAULT 0, remaining_sessions INTEGER DEFAULT 1, sale_price DECIMAL(15,2) DEFAULT 0, purchase_date DATE DEFAULT CURRENT_DATE, expiry_date DATE, status VARCHAR(20) DEFAULT ''active'', created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_package_purchases');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), customer_id UUID, package_id UUID, total_sessions INTEGER, sale_price DECIMAL(15,2), sale_date DATE, expiry_date DATE, status VARCHAR(20))', v_prefix || '_beauty_package_sales');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), device_id UUID, appointment_id UUID, customer_id UUID, specialist_id UUID, body_region_id UUID, shots_used INTEGER DEFAULT 0, expected_shots INTEGER DEFAULT 0, is_excessive BOOLEAN DEFAULT false, usage_date DATE DEFAULT CURRENT_DATE, notes TEXT, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_device_usage');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), device_id UUID, usage_id UUID, alert_type VARCHAR(50), message TEXT, severity VARCHAR(20) DEFAULT ''warning'', acknowledged BOOLEAN DEFAULT false, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_device_alerts');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), appointment_id UUID, customer_id UUID, service_rating SMALLINT DEFAULT 5, staff_rating SMALLINT DEFAULT 5, cleanliness_rating SMALLINT DEFAULT 5, overall_rating SMALLINT DEFAULT 5, comment TEXT, would_recommend BOOLEAN DEFAULT true, survey_id UUID, survey_answers JSONB, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_customer_feedback');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), invoice_number VARCHAR(30), customer_id UUID, subtotal DECIMAL(15,2) DEFAULT 0, discount DECIMAL(15,2) DEFAULT 0, tax DECIMAL(15,2) DEFAULT 0, total DECIMAL(15,2) DEFAULT 0, payment_method VARCHAR(30) DEFAULT ''cash'', payment_status VARCHAR(20) DEFAULT ''paid'', paid_amount DECIMAL(15,2) DEFAULT 0, remaining_amount DECIMAL(15,2) DEFAULT 0, notes TEXT, created_by UUID, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_sales');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), sale_id UUID, item_type VARCHAR(20) DEFAULT ''service'', item_id UUID, name VARCHAR(255), quantity INTEGER DEFAULT 1, unit_price DECIMAL(15,2) DEFAULT 0, discount DECIMAL(15,2) DEFAULT 0, total DECIMAL(15,2) DEFAULT 0, staff_id UUID, commission_amount DECIMAL(15,2) DEFAULT 0, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_sale_items');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), customer_id UUID, service_id UUID, specialist_id UUID, preferred_date_from DATE, preferred_date_to DATE, notes TEXT, status VARCHAR(20) DEFAULT ''active'', created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_waitlist');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name VARCHAR(255) NOT NULL, phone VARCHAR(50) NOT NULL, email VARCHAR(255), service_id UUID, requested_date DATE, requested_time TIME, notes TEXT, status VARCHAR(20) DEFAULT ''pending'', public_token_used VARCHAR(128), processed_appointment_id UUID, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_booking_requests');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), appointment_id UUID, channel VARCHAR(30) NOT NULL, payload_json JSONB DEFAULT ''{}''::jsonb, status VARCHAR(20) DEFAULT ''pending'', scheduled_at TIMESTAMPTZ, sent_at TIMESTAMPTZ, error_text TEXT, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_notification_queue');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), customer_id UUID, appointment_id UUID, template_id UUID, signed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, signature_data TEXT, meta_json JSONB DEFAULT ''{}''::jsonb, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_consent_submissions');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), appointment_id UUID, customer_id UUID, subjective TEXT, objective TEXT, assessment TEXT, plan TEXT, extra_json JSONB DEFAULT ''{}''::jsonb, created_by UUID, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_clinical_notes');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), customer_id UUID NOT NULL, appointment_id UUID, kind VARCHAR(20) DEFAULT ''before'', storage_url TEXT NOT NULL, caption TEXT, taken_at DATE, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_patient_photos');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), customer_id UUID NOT NULL, membership_id UUID NOT NULL, start_date DATE, end_date DATE, status VARCHAR(20) DEFAULT ''active'', auto_renew BOOLEAN DEFAULT false, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_membership_subscriptions');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), table_name VARCHAR(80) NOT NULL, record_id UUID, action VARCHAR(40) NOT NULL, user_id UUID, payload_json JSONB DEFAULT ''{}''::jsonb, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_audit_log');
  EXECUTE format('CREATE TABLE IF NOT EXISTS beauty.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), appointment_id UUID, product_id UUID NOT NULL, qty DECIMAL(15,4) NOT NULL, batch_id UUID, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP)', v_prefix || '_beauty_consumable_usage_log');
END;
$$;


--
-- Name: init_production_tables(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.init_production_tables(p_firm_nr character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE v_prefix TEXT := lower('rex_' || p_firm_nr);
BEGIN
  EXECUTE format('CREATE TABLE IF NOT EXISTS public.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), firm_nr VARCHAR(10) NOT NULL, product_id UUID NOT NULL, name VARCHAR(255) NOT NULL, description TEXT, total_cost DECIMAL(15,2) DEFAULT 0, wastage_percent DECIMAL(5,2) DEFAULT 0, is_active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP);', v_prefix || '_production_recipes');
  EXECUTE format('CREATE TABLE IF NOT EXISTS public.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), recipe_id UUID NOT NULL, material_id UUID NOT NULL, quantity DECIMAL(15,3) NOT NULL, unit VARCHAR(20), cost DECIMAL(15,2) DEFAULT 0, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP);', v_prefix || '_production_recipe_ingredients');
  EXECUTE format('CREATE TABLE IF NOT EXISTS public.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), firm_nr VARCHAR(10) NOT NULL, order_no VARCHAR(50) UNIQUE, recipe_id UUID NOT NULL, product_id UUID NOT NULL, planned_qty DECIMAL(15,3) NOT NULL, produced_qty DECIMAL(15,3) DEFAULT 0, status VARCHAR(20) DEFAULT ''draft'', start_date DATE, end_date DATE, completed_at TIMESTAMPTZ, note TEXT, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP);', v_prefix || '_production_orders');
  PERFORM public.ATTACH_AUDIT_LOG(v_prefix || '_production_recipes');
  PERFORM public.ATTACH_AUDIT_LOG(v_prefix || '_production_recipe_ingredients');
  PERFORM public.ATTACH_AUDIT_LOG(v_prefix || '_production_orders');
END;
$$;


--
-- Name: init_restaurant_firm_tables(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.init_restaurant_firm_tables(p_firm_nr character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE v_prefix TEXT := lower('rex_' || p_firm_nr);
BEGIN
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS rest.%I (
      id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      floor_id             UUID REFERENCES rest.floors(id),
      number               VARCHAR(50) NOT NULL,
      seats                INTEGER DEFAULT 4,
      status               VARCHAR(20) DEFAULT ''empty'',
      total                DECIMAL(15,2) DEFAULT 0,
      pos_x                INTEGER DEFAULT 0,
      pos_y                INTEGER DEFAULT 0,
      is_large             BOOLEAN DEFAULT false,
      waiter               VARCHAR(255),
      staff_id             UUID,
      start_time           TIMESTAMPTZ,
      locked_by_staff_id   UUID,
      locked_by_staff_name VARCHAR(255),
      locked_at            TIMESTAMPTZ,
      linked_order_ids     text[] DEFAULT ''{}'',
      color                VARCHAR(20) DEFAULT NULL,
      updated_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
  ', v_prefix || '_rest_tables');
  EXECUTE format('CREATE TABLE IF NOT EXISTS rest.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), menu_item_id UUID, product_id UUID, total_cost DECIMAL(15,2) DEFAULT 0, wastage_percent DECIMAL(5,2) DEFAULT 0, is_active BOOLEAN DEFAULT true, updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP);', v_prefix || '_rest_recipes');
  EXECUTE format('CREATE TABLE IF NOT EXISTS rest.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), recipe_id UUID REFERENCES rest.%I(id) ON DELETE CASCADE, material_id UUID, quantity DECIMAL(15,3), unit VARCHAR(20), cost DECIMAL(15,2) DEFAULT 0);', v_prefix || '_rest_recipe_ingredients', v_prefix || '_rest_recipes');
  EXECUTE format('CREATE TABLE IF NOT EXISTS rest.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name VARCHAR(100) NOT NULL, role VARCHAR(50) DEFAULT ''Waiter'', pin VARCHAR(10) NOT NULL UNIQUE, is_active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP);', v_prefix || '_rest_staff');
END;
$$;


--
-- Name: init_restaurant_period_tables(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.init_restaurant_period_tables(p_firm_nr character varying, p_period_nr character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE v_prefix TEXT := lower('rex_' || p_firm_nr || '_' || p_period_nr);
BEGIN
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS rest.%I (
      id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      order_no        VARCHAR(50) UNIQUE,
      table_id        UUID,
      floor_id        UUID REFERENCES rest.floors(id),
      waiter          VARCHAR(255),
      staff_id        UUID,
      customer_id     UUID,
      status          VARCHAR(20) DEFAULT ''open'',
      total_amount    DECIMAL(15,2) DEFAULT 0,
      discount_amount DECIMAL(15,2) DEFAULT 0,
      order_discount_pct DECIMAL(5,2) DEFAULT 0,
      tax_amount      DECIMAL(15,2) DEFAULT 0,
      note            TEXT,
      parent_order_id UUID,
      kitchen_note    TEXT,
      estimated_ready_at TIMESTAMPTZ,
      opened_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
      billed_at       TIMESTAMPTZ,
      closed_at       TIMESTAMPTZ,
      payment_method  VARCHAR(50),
      created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
      updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
  ', v_prefix || '_rest_orders');
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS rest.%I (
      id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      order_id         UUID REFERENCES rest.%I(id) ON DELETE CASCADE,
      product_id       UUID,
      product_name     VARCHAR(255) NOT NULL,
      quantity         DECIMAL(15,3) NOT NULL DEFAULT 1,
      unit_price       DECIMAL(15,2) NOT NULL,
      discount_pct     DECIMAL(5,2) DEFAULT 0,
      subtotal         DECIMAL(15,2) NOT NULL,
      status           VARCHAR(20) DEFAULT ''pending'',
      course           VARCHAR(50),
      note             TEXT,
      options          JSONB,
      is_void          BOOLEAN DEFAULT false,
      void_reason      TEXT,
      is_complimentary BOOLEAN DEFAULT false,
      preparation_time INTEGER,
      sent_to_kitchen_at TIMESTAMPTZ,
      served_at        TIMESTAMPTZ,
      created_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
  ', v_prefix || '_rest_order_items', v_prefix || '_rest_orders');
  EXECUTE format('CREATE TABLE IF NOT EXISTS rest.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), order_id UUID REFERENCES rest.%I(id) ON DELETE CASCADE, table_number VARCHAR(50), floor_name VARCHAR(100), waiter VARCHAR(255), staff_id UUID, status VARCHAR(20) DEFAULT ''new'', note TEXT, estimated_ready_at TIMESTAMPTZ, sent_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP);', v_prefix || '_rest_kitchen_orders', v_prefix || '_rest_orders');
  EXECUTE format('CREATE TABLE IF NOT EXISTS rest.%I (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), kitchen_order_id UUID REFERENCES rest.%I(id) ON DELETE CASCADE, order_item_id UUID REFERENCES rest.%I(id) ON DELETE CASCADE, product_name VARCHAR(255) NOT NULL, quantity DECIMAL(15,3) NOT NULL, course VARCHAR(50), note TEXT, status VARCHAR(20) DEFAULT ''new'', preparation_time INTEGER, start_at TIMESTAMPTZ, estimated_ready_at TIMESTAMPTZ, served_at TIMESTAMPTZ);', v_prefix || '_rest_kitchen_items', v_prefix || '_rest_kitchen_orders', v_prefix || '_rest_order_items');
END;
$$;


--
-- Name: log_row_change(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.log_row_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_old_data JSONB := NULL;
  v_new_data JSONB := NULL;
  v_firm_nr  VARCHAR(10);
BEGIN
  IF (TG_OP = 'UPDATE') THEN v_old_data := to_jsonb(OLD); v_new_data := to_jsonb(NEW);
  ELSIF (TG_OP = 'DELETE') THEN v_old_data := to_jsonb(OLD);
  ELSIF (TG_OP = 'INSERT') THEN v_new_data := to_jsonb(NEW);
  END IF;
  BEGIN v_firm_nr := NEW.firm_nr; EXCEPTION WHEN OTHERS THEN
  BEGIN v_firm_nr := OLD.firm_nr; EXCEPTION WHEN OTHERS THEN v_firm_nr := 'SYSTEM'; END; END;
  INSERT INTO public.audit_logs (user_id, firm_nr, table_name, record_id, action, old_data, new_data, client_info)
  VALUES (current_setting('app.current_user_id', true)::UUID,
          COALESCE(v_firm_nr, 'SYSTEM'), TG_TABLE_NAME,
          COALESCE(NEW.id, OLD.id), TG_OP, v_old_data, v_new_data,
          jsonb_build_object('ip', inet_client_addr(), 'backend_pid', pg_backend_pid()));
  IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$;


--
-- Name: refresh_all_firm_tables(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.refresh_all_firm_tables() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  f RECORD;
  p RECORD;
BEGIN
  FOR f IN SELECT firm_nr FROM firms WHERE is_active = true LOOP
    RAISE NOTICE 'Refreshing firm: %', f.firm_nr;
    PERFORM CREATE_FIRM_TABLES(f.firm_nr);
    FOR p IN SELECT nr FROM periods WHERE firm_id = (SELECT id FROM firms WHERE firm_nr = f.firm_nr) LOOP
      RAISE NOTICE 'Refreshing period: % / %', f.firm_nr, p.nr;
      PERFORM CREATE_PERIOD_TABLES(f.firm_nr, p.nr::varchar);
    END LOOP;
    PERFORM INIT_RESTAURANT_FIRM_TABLES(f.firm_nr);
    PERFORM INIT_BEAUTY_FIRM_TABLES(f.firm_nr);
    FOR p IN SELECT nr FROM periods WHERE firm_id = (SELECT id FROM firms WHERE firm_nr = f.firm_nr) LOOP
      PERFORM INIT_RESTAURANT_PERIOD_TABLES(f.firm_nr, p.nr::varchar);
      PERFORM INIT_BEAUTY_PERIOD_TABLES(f.firm_nr, p.nr::varchar);
    END LOOP;
  END LOOP;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


--
-- Name: update_counting_slips_updated_at(); Type: FUNCTION; Schema: wms; Owner: -
--

CREATE FUNCTION wms.update_counting_slips_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;


--
-- Name: update_timestamp(); Type: FUNCTION; Schema: wms; Owner: -
--

CREATE FUNCTION wms.update_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN NEW.updated_at = CURRENT_TIMESTAMP; RETURN NEW; END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255),
    encrypted_password character varying(255),
    raw_user_meta_data jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: body_regions; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.body_regions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    avg_shots integer DEFAULT 100,
    min_shots integer DEFAULT 50,
    max_shots integer DEFAULT 200,
    sort_order integer DEFAULT 0
);


--
-- Name: rex_001_01_beauty_appointments; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_appointments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_id uuid,
    service_id uuid,
    specialist_id uuid,
    device_id uuid,
    body_region_id uuid,
    appointment_date date,
    appointment_time time without time zone,
    duration integer DEFAULT 30,
    status character varying(20) DEFAULT 'scheduled'::character varying,
    type character varying(20) DEFAULT 'regular'::character varying,
    notes text,
    total_price numeric(15,2) DEFAULT 0,
    commission_amount numeric(15,2) DEFAULT 0,
    is_package_session boolean DEFAULT false,
    package_purchase_id uuid,
    reminder_sent boolean DEFAULT false,
    branch_id uuid,
    room_id uuid,
    tele_meeting_url text,
    booking_channel character varying(40) DEFAULT 'staff'::character varying,
    corporate_account_id uuid,
    reminder_sent_at timestamp with time zone,
    last_notification_channel character varying(30),
    session_series_id uuid,
    confirmation_call_at timestamp with time zone,
    pre_visit_activity_at timestamp with time zone,
    treatment_degree character varying(80),
    treatment_shots character varying(80),
    clinical_data jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_beauty_audit_log; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_audit_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    table_name character varying(80) NOT NULL,
    record_id uuid,
    action character varying(40) NOT NULL,
    user_id uuid,
    payload_json jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_beauty_booking_requests; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_booking_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    phone character varying(50) NOT NULL,
    email character varying(255),
    service_id uuid,
    requested_date date,
    requested_time time without time zone,
    notes text,
    status character varying(20) DEFAULT 'pending'::character varying,
    public_token_used character varying(128),
    processed_appointment_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_beauty_clinical_notes; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_clinical_notes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    appointment_id uuid,
    customer_id uuid,
    subjective text,
    objective text,
    assessment text,
    plan text,
    extra_json jsonb DEFAULT '{}'::jsonb,
    created_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_beauty_consent_submissions; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_consent_submissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_id uuid,
    appointment_id uuid,
    template_id uuid,
    signed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    signature_data text,
    meta_json jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_beauty_consumable_usage_log; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_consumable_usage_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    appointment_id uuid,
    product_id uuid NOT NULL,
    qty numeric(15,4) NOT NULL,
    batch_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_beauty_customer_feedback; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_customer_feedback (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    appointment_id uuid,
    customer_id uuid,
    service_rating smallint DEFAULT 5,
    staff_rating smallint DEFAULT 5,
    cleanliness_rating smallint DEFAULT 5,
    overall_rating smallint DEFAULT 5,
    comment text,
    would_recommend boolean DEFAULT true,
    survey_id uuid,
    survey_answers jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_beauty_device_alerts; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_device_alerts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    device_id uuid,
    usage_id uuid,
    alert_type character varying(50),
    message text,
    severity character varying(20) DEFAULT 'warning'::character varying,
    acknowledged boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_beauty_device_usage; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_device_usage (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    device_id uuid,
    appointment_id uuid,
    customer_id uuid,
    specialist_id uuid,
    body_region_id uuid,
    shots_used integer DEFAULT 0,
    expected_shots integer DEFAULT 0,
    is_excessive boolean DEFAULT false,
    usage_date date DEFAULT CURRENT_DATE,
    notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_beauty_membership_subscriptions; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_membership_subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_id uuid NOT NULL,
    membership_id uuid NOT NULL,
    start_date date,
    end_date date,
    status character varying(20) DEFAULT 'active'::character varying,
    auto_renew boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_beauty_notification_queue; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_notification_queue (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    appointment_id uuid,
    channel character varying(30) NOT NULL,
    payload_json jsonb DEFAULT '{}'::jsonb,
    status character varying(20) DEFAULT 'pending'::character varying,
    scheduled_at timestamp with time zone,
    sent_at timestamp with time zone,
    error_text text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_beauty_package_purchases; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_package_purchases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_id uuid,
    package_id uuid,
    total_sessions integer DEFAULT 1,
    used_sessions integer DEFAULT 0,
    remaining_sessions integer DEFAULT 1,
    sale_price numeric(15,2) DEFAULT 0,
    purchase_date date DEFAULT CURRENT_DATE,
    expiry_date date,
    status character varying(20) DEFAULT 'active'::character varying,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_beauty_package_sales; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_package_sales (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_id uuid,
    package_id uuid,
    total_sessions integer,
    sale_price numeric(15,2),
    sale_date date,
    expiry_date date,
    status character varying(20)
);


--
-- Name: rex_001_01_beauty_patient_photos; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_patient_photos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_id uuid NOT NULL,
    appointment_id uuid,
    kind character varying(20) DEFAULT 'before'::character varying,
    storage_url text NOT NULL,
    caption text,
    taken_at date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_beauty_sale_items; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_sale_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sale_id uuid,
    item_type character varying(20) DEFAULT 'service'::character varying,
    item_id uuid,
    name character varying(255),
    quantity integer DEFAULT 1,
    unit_price numeric(15,2) DEFAULT 0,
    discount numeric(15,2) DEFAULT 0,
    total numeric(15,2) DEFAULT 0,
    staff_id uuid,
    commission_amount numeric(15,2) DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_beauty_sales; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_sales (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_number character varying(30),
    customer_id uuid,
    subtotal numeric(15,2) DEFAULT 0,
    discount numeric(15,2) DEFAULT 0,
    tax numeric(15,2) DEFAULT 0,
    total numeric(15,2) DEFAULT 0,
    payment_method character varying(30) DEFAULT 'cash'::character varying,
    payment_status character varying(20) DEFAULT 'paid'::character varying,
    paid_amount numeric(15,2) DEFAULT 0,
    remaining_amount numeric(15,2) DEFAULT 0,
    notes text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_beauty_session_logs; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_session_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    package_purchase_id uuid,
    appointment_id uuid,
    session_number integer,
    recorded_at timestamp with time zone DEFAULT now()
);


--
-- Name: rex_001_01_beauty_sessions; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_id uuid,
    specialist_id uuid,
    service_id uuid,
    appointment_id uuid,
    session_date date DEFAULT CURRENT_DATE,
    shots_used integer DEFAULT 0,
    skin_type character varying(20),
    before_photo text,
    after_photo text,
    notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_beauty_waitlist; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_01_beauty_waitlist (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_id uuid,
    service_id uuid,
    specialist_id uuid,
    preferred_date_from date,
    preferred_date_to date,
    notes text,
    status character varying(20) DEFAULT 'active'::character varying,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_beauty_branches; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_branches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    address text,
    phone character varying(50),
    is_active boolean DEFAULT true,
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_beauty_consent_templates; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_consent_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying(255) NOT NULL,
    body_html text,
    is_active boolean DEFAULT true,
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_beauty_corporate_accounts; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_corporate_accounts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    tax_nr character varying(50),
    discount_pct numeric(5,2) DEFAULT 0,
    notes text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_beauty_customer_health; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_customer_health (
    customer_id uuid NOT NULL,
    allergies text,
    medications text,
    pregnancy boolean DEFAULT false,
    chronic_notes text,
    warnings_banner text,
    kvkk_consent_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_beauty_devices; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_devices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    device_type character varying(50) DEFAULT 'laser'::character varying,
    serial_number character varying(100),
    manufacturer character varying(100),
    model character varying(100),
    total_shots bigint DEFAULT 0,
    max_shots bigint DEFAULT 500000,
    maintenance_due date,
    last_maintenance date,
    purchase_date date,
    warranty_expiry date,
    status character varying(20) DEFAULT 'active'::character varying,
    notes text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_beauty_integration_settings; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_integration_settings (
    id smallint DEFAULT 1 NOT NULL,
    google_calendar_id text,
    external_calendar_json jsonb DEFAULT '{}'::jsonb,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT rex_001_beauty_integration_settings_id_check CHECK ((id = 1))
);


--
-- Name: rex_001_beauty_leads; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_leads (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    phone character varying(50),
    email character varying(255),
    source character varying(30) DEFAULT 'other'::character varying,
    status character varying(30) DEFAULT 'new'::character varying,
    interested_services jsonb DEFAULT '[]'::jsonb,
    notes text,
    assigned_to uuid,
    first_contact_date date DEFAULT CURRENT_DATE,
    last_contact_date date,
    converted_customer_id uuid,
    lost_reason text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_beauty_marketing_campaigns; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_marketing_campaigns (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    channel character varying(30) DEFAULT 'sms'::character varying,
    segment_filter_json jsonb DEFAULT '{}'::jsonb,
    message_template text,
    scheduled_at timestamp with time zone,
    status character varying(20) DEFAULT 'draft'::character varying,
    sent_count integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_beauty_memberships; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_memberships (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    monthly_price numeric(15,2) DEFAULT 0,
    session_credit integer DEFAULT 0,
    benefits_json jsonb DEFAULT '{}'::jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_beauty_packages; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_packages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    service_id uuid,
    total_sessions integer DEFAULT 1,
    price numeric(15,2) DEFAULT 0,
    cost_price numeric(15,2) DEFAULT 0,
    discount_pct numeric(5,2) DEFAULT 0,
    validity_days integer DEFAULT 365,
    color character varying(20) DEFAULT '#6366f1'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_beauty_portal_settings; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_portal_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    online_booking_enabled boolean DEFAULT false,
    allow_staff_slot_overlap boolean DEFAULT false,
    public_slug character varying(120),
    public_token character varying(128) DEFAULT encode(public.gen_random_bytes(24), 'hex'::text) NOT NULL,
    reminder_hours_before smallint DEFAULT 24,
    sms_template text,
    whatsapp_template text,
    sms_user character varying(255),
    sms_password character varying(255),
    sms_sender character varying(80),
    whatsapp_provider character varying(30) DEFAULT 'NONE'::character varying,
    whatsapp_base_url text,
    whatsapp_token text,
    whatsapp_instance_id character varying(255),
    whatsapp_phone_id character varying(80),
    default_reminder_channel character varying(20) DEFAULT 'sms'::character varying,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_beauty_product_batches; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_product_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    lot_code character varying(80),
    expiry_date date,
    qty numeric(15,3) DEFAULT 0,
    barcode character varying(80),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_beauty_rooms; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_rooms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid,
    name character varying(255) NOT NULL,
    capacity integer DEFAULT 1,
    is_active boolean DEFAULT true,
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_beauty_satisfaction_questions; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_satisfaction_questions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    survey_id uuid NOT NULL,
    sort_order integer DEFAULT 0,
    question_type character varying(30) DEFAULT 'rating'::character varying,
    scale_max smallint DEFAULT 5,
    is_required boolean DEFAULT true,
    labels_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_beauty_satisfaction_surveys; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_satisfaction_surveys (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    is_active boolean DEFAULT false,
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_beauty_service_consumables; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_service_consumables (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    service_id uuid NOT NULL,
    product_id uuid NOT NULL,
    qty_per_service numeric(15,4) DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_beauty_services; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_services (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    category character varying(50) DEFAULT 'beauty'::character varying,
    parent_category character varying(100),
    duration_min integer DEFAULT 30,
    price numeric(15,2) DEFAULT 0,
    cost_price numeric(15,2) DEFAULT 0,
    color character varying(20) DEFAULT '#9333ea'::character varying,
    commission_rate numeric(5,2) DEFAULT 0,
    description text,
    requires_device boolean DEFAULT false,
    expected_shots integer DEFAULT 0,
    default_sessions integer DEFAULT 1 NOT NULL,
    follow_up_reminder_days integer,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_beauty_specialists; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_beauty_specialists (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    phone character varying(50),
    email character varying(255),
    specialty character varying(100),
    color character varying(20) DEFAULT '#9333ea'::character varying,
    commission_rate numeric(5,2) DEFAULT 0,
    product_unit_commission numeric(15,2) DEFAULT 0 NOT NULL,
    avatar_url text,
    working_hours jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_follow_up_reminder_actions; Type: TABLE; Schema: beauty; Owner: -
--

CREATE TABLE beauty.rex_001_follow_up_reminder_actions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    customer_id uuid NOT NULL,
    service_id uuid NOT NULL,
    product_id uuid,
    reminder_kind character varying(20) DEFAULT 'service'::character varying NOT NULL,
    last_completed_date date NOT NULL,
    natural_due_date date NOT NULL,
    reminder_days integer,
    customer_name character varying(255),
    customer_phone character varying(50),
    service_name character varying(255),
    product_name character varying(255),
    status character varying(30) DEFAULT 'due'::character varying NOT NULL,
    postponed_due_date date,
    note text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: bank_accounts; Type: TABLE; Schema: logic; Owner: -
--

CREATE TABLE logic.bank_accounts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    bank_name character varying(255),
    iban character varying(50),
    currency_code character varying(10),
    balance numeric(15,2) DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: campaigns; Type: TABLE; Schema: logic; Owner: -
--

CREATE TABLE logic.campaigns (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    campaign_type character varying(50) NOT NULL,
    discount_value numeric(15,2),
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    is_active boolean DEFAULT true,
    conditions jsonb,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: app_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    key character varying(100) NOT NULL,
    value jsonb NOT NULL,
    firm_nr character varying(10) NOT NULL
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    firm_nr character varying(10) NOT NULL,
    table_name character varying(100) NOT NULL,
    record_id uuid NOT NULL,
    action character varying(20) NOT NULL,
    old_data jsonb,
    new_data jsonb,
    client_info jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: barcode_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.barcode_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) DEFAULT 'Varsayilan Sablon'::character varying NOT NULL,
    prefix character varying(20) DEFAULT '869'::character varying,
    current_value bigint DEFAULT 1000000,
    length integer DEFAULT 13,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: brands; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.brands (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    is_active boolean DEFAULT true
);


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    parent_id uuid,
    is_restaurant boolean DEFAULT false,
    icon character varying(100),
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: currencies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.currencies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(10) NOT NULL,
    name character varying(100) NOT NULL,
    symbol character varying(10),
    is_base_currency boolean DEFAULT false,
    sort_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: exchange_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exchange_rates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    currency_code character varying(10) NOT NULL,
    date date NOT NULL,
    buy_rate numeric(18,8) NOT NULL,
    sell_rate numeric(18,8) NOT NULL,
    effective_buy numeric(18,8),
    effective_sell numeric(18,8),
    source character varying(50) DEFAULT 'manual'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: firms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.firms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    name character varying(255) NOT NULL,
    title character varying(255),
    tax_nr character varying(50),
    tax_office character varying(100),
    address text,
    city character varying(100),
    country character varying(100),
    email character varying(100),
    phone character varying(50),
    ana_para_birimi character varying(10) DEFAULT 'IQD'::character varying,
    raporlama_para_birimi character varying(10) DEFAULT 'IQD'::character varying,
    regulatory_region character varying(2) DEFAULT 'IQ'::character varying NOT NULL,
    gib_integration_mode character varying(20) DEFAULT 'mock'::character varying NOT NULL,
    gib_ubl_profile character varying(40) DEFAULT 'TICARIFATURA'::character varying,
    gib_sender_alias character varying(255),
    gib_integrator_base_url character varying(512),
    gib_integrator_username character varying(255),
    gib_integrator_password character varying(255),
    gib_use_test_environment boolean DEFAULT true,
    "default" boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    supabase_firm_id character varying(255)
);


--
-- Name: gib_edocument_queue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gib_edocument_queue (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    period_nr character varying(10) NOT NULL,
    source_type character varying(32) DEFAULT 'sales_fiche'::character varying NOT NULL,
    source_id uuid NOT NULL,
    document_no character varying(100),
    doc_type character varying(32) DEFAULT 'E-Fatura'::character varying NOT NULL,
    customer_name text,
    doc_date date,
    amount numeric(18,4) DEFAULT 0,
    tax_amount numeric(18,4) DEFAULT 0,
    status character varying(32) DEFAULT 'Taslak'::character varying NOT NULL,
    gib_uuid uuid,
    payload_json jsonb,
    xml_snapshot text,
    gib_response_json jsonb,
    error_message text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    sent_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: menu_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu_items (
    id integer NOT NULL,
    menu_type character varying(50) NOT NULL,
    title character varying(255),
    label character varying(255) NOT NULL,
    label_tr character varying(255),
    label_en character varying(255),
    label_ar character varying(255),
    parent_id integer,
    section_id integer,
    screen_id character varying(100),
    icon_name character varying(100),
    badge character varying(50),
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    is_visible boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: menu_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menu_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menu_items_id_seq OWNED BY public.menu_items.id;


--
-- Name: periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.periods (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_id uuid,
    nr integer NOT NULL,
    beg_date date NOT NULL,
    end_date date NOT NULL,
    is_active boolean DEFAULT true,
    "default" boolean DEFAULT false
);


--
-- Name: product_exchange_rate_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_exchange_rate_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    old_rate numeric,
    new_rate numeric,
    changed_by text,
    changed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: product_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    is_active boolean DEFAULT true
);


--
-- Name: report_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.report_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    category character varying(50) NOT NULL,
    template_type character varying(50) DEFAULT 'json'::character varying,
    content jsonb NOT NULL,
    is_default boolean DEFAULT false,
    firm_nr character varying(10),
    period_nr character varying(10),
    created_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_bank_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_01_bank_lines (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    period_nr character varying(10),
    register_id uuid,
    fiche_no character varying(100),
    date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    amount numeric(15,2) DEFAULT 0,
    sign integer DEFAULT 1,
    trcode integer,
    definition text,
    transaction_type character varying(50),
    customer_id uuid,
    cash_register_id uuid,
    currency_code character varying(10) DEFAULT 'IQD'::character varying,
    exchange_rate numeric(15,6) DEFAULT 1,
    f_amount numeric(15,2) DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_cash_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_01_cash_lines (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    period_nr character varying(10),
    register_id uuid,
    fiche_no character varying(100),
    date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    amount numeric(15,2) DEFAULT 0,
    sign integer DEFAULT 1,
    trcode integer,
    definition text,
    transaction_type character varying(50),
    customer_id uuid,
    bank_id uuid,
    bank_account_id uuid,
    target_register_id uuid,
    expense_card_id uuid,
    currency_code character varying(10) DEFAULT 'IQD'::character varying,
    exchange_rate numeric(15,6) DEFAULT 1,
    f_amount numeric(15,2) DEFAULT 0,
    transfer_status integer DEFAULT 0,
    special_code character varying(50),
    tax_rate numeric(5,2) DEFAULT 0,
    withholding_tax_rate numeric(5,2) DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_sale_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_01_sale_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_id uuid,
    firm_nr character varying(10),
    period_nr character varying(10),
    item_code character varying(100),
    item_name character varying(255),
    product_id uuid,
    quantity numeric(15,3) NOT NULL,
    unit_price numeric(15,2) NOT NULL,
    vat_rate numeric(5,2) DEFAULT 0,
    discount_rate numeric(15,4) DEFAULT 0,
    discount_amount numeric(15,2) DEFAULT 0,
    total_amount numeric(15,2) DEFAULT 0,
    net_amount numeric(15,2) NOT NULL,
    unit_cost numeric(15,2) DEFAULT 0,
    total_cost numeric(15,2) DEFAULT 0,
    gross_profit numeric(15,2) DEFAULT 0,
    unit character varying(20) DEFAULT 'Adet'::character varying,
    unit_multiplier numeric(15,6) DEFAULT 1,
    base_quantity numeric(15,3),
    unit_price_fc numeric(15,4) DEFAULT 0,
    currency character varying(10) DEFAULT 'IQD'::character varying
);


--
-- Name: rex_001_01_sales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_01_sales (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    period_nr character varying(10) NOT NULL,
    fiche_no character varying(100),
    document_no character varying(100),
    trcode integer,
    fiche_type character varying(50),
    date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    customer_id uuid,
    customer_name character varying(255),
    store_id uuid,
    total_net numeric(15,2) DEFAULT 0,
    total_vat numeric(15,2) DEFAULT 0,
    total_gross numeric(15,2) DEFAULT 0,
    total_discount numeric(15,2) DEFAULT 0,
    net_amount numeric(15,2) DEFAULT 0,
    total_cost numeric(15,2) DEFAULT 0,
    gross_profit numeric(15,2) DEFAULT 0,
    profit_margin numeric(15,2) DEFAULT 0,
    currency character varying(10) DEFAULT 'IQD'::character varying,
    currency_rate numeric(15,6) DEFAULT 1,
    status character varying(20) DEFAULT 'completed'::character varying,
    logo_sync_status character varying(20) DEFAULT 'pending'::character varying,
    payment_method character varying(50),
    cashier character varying(100),
    is_cancelled boolean DEFAULT false,
    credit_amount numeric(15,2) DEFAULT 0,
    notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_stock_movement_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_01_stock_movement_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    movement_id uuid,
    product_id uuid,
    quantity numeric(15,4) DEFAULT 0,
    unit_price numeric(15,2) DEFAULT 0,
    cost_price numeric(15,2) DEFAULT 0,
    exchange_rate numeric DEFAULT 1,
    unit_name character varying(100),
    convert_factor numeric DEFAULT 1,
    notes text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: rex_001_01_stock_movements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_01_stock_movements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    period_nr character varying(10) NOT NULL,
    document_no character varying(50),
    trcode integer,
    movement_type character varying(20),
    warehouse_id uuid,
    target_warehouse_id uuid,
    movement_date timestamp with time zone DEFAULT now(),
    exchange_rate numeric DEFAULT 1,
    description text,
    status character varying(20) DEFAULT 'completed'::character varying,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: rex_001_01_virman_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_01_virman_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    virman_id uuid,
    product_id uuid,
    quantity numeric(15,4) DEFAULT 0,
    notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_virman_operations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_01_virman_operations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    period_nr character varying(10),
    virman_no character varying(100) NOT NULL,
    from_warehouse_id uuid,
    to_warehouse_id uuid,
    operation_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(50) DEFAULT 'draft'::character varying,
    notes text,
    created_by character varying(100),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_bank_registers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_bank_registers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    code character varying(50),
    name character varying(255) NOT NULL,
    bank_name character varying(255),
    iban character varying(50),
    currency_code character varying(10) DEFAULT 'IQD'::character varying,
    balance numeric(15,2) DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: rex_001_brands; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_brands (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50),
    name character varying(255) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_campaigns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_campaigns (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    type character varying(50) NOT NULL,
    discount_type character varying(50) NOT NULL,
    discount_value numeric(15,2) DEFAULT 0,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    is_active boolean DEFAULT true,
    min_purchase_amount numeric(15,2) DEFAULT 0,
    max_discount_amount numeric(15,2),
    applicable_categories character varying(255),
    applicable_products jsonb DEFAULT '[]'::jsonb,
    priority integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_cash_registers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_cash_registers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    code character varying(50),
    name character varying(255) NOT NULL,
    currency_code character varying(10) DEFAULT 'IQD'::character varying,
    balance numeric(15,2) DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: rex_001_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50),
    name character varying(255) NOT NULL,
    description text,
    parent_id uuid,
    is_restaurant boolean DEFAULT false,
    icon character varying(100),
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_customers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    code character varying(50),
    name character varying(255) NOT NULL,
    phone character varying(50),
    phone2 character varying(50),
    age integer,
    file_id character varying(120),
    occupation character varying(150),
    gender character varying(20),
    customer_tier character varying(20) DEFAULT 'normal'::character varying,
    heard_from character varying(150),
    email character varying(255),
    tax_nr character varying(50),
    taxi_nr character varying(50),
    tax_office character varying(100),
    address text,
    city character varying(100),
    neighborhood character varying(100),
    district character varying(100),
    balance numeric(15,2) DEFAULT 0,
    points numeric(15,2) DEFAULT 0,
    total_spent numeric(15,2) DEFAULT 0,
    notes text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_expense_cards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_expense_cards (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    code character varying(50),
    name character varying(255) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: rex_001_product_barcodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_product_barcodes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    barcode_code character varying(100) NOT NULL,
    unit character varying(50),
    sale_price numeric(15,2) DEFAULT 0,
    is_primary boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: rex_001_product_unit_conversions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_product_unit_conversions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    from_unit character varying(50) NOT NULL,
    to_unit character varying(50) NOT NULL,
    factor numeric(15,6) DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: rex_001_product_variants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_product_variants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid,
    sku character varying(100),
    attributes jsonb
);


--
-- Name: rex_001_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    ref_id integer,
    code character varying(100),
    barcode character varying(100),
    name character varying(255) NOT NULL,
    name2 character varying(255),
    image_url text,
    image_url_cdn text,
    description text,
    description_tr text,
    description_en text,
    description_ar text,
    description_ku text,
    category_id uuid,
    category_code character varying(50),
    categorycode character varying(50),
    "categoryCode" character varying(50),
    group_code character varying(50),
    groupcode character varying(50),
    "groupCode" character varying(50),
    sub_group_code character varying(50),
    subgroupcode character varying(50),
    "subGroupCode" character varying(50),
    brand character varying(100),
    model character varying(100),
    manufacturer character varying(100),
    supplier character varying(100),
    origin character varying(50),
    material_type character varying(50),
    materialtype character varying(50),
    "materialType" character varying(50),
    unit character varying(50) DEFAULT 'Adet'::character varying,
    unit2 character varying(20),
    unit3 character varying(20),
    unit_id uuid,
    unitset_id uuid,
    unitsetid uuid,
    "unitsetId" uuid,
    vat_rate numeric(5,2) DEFAULT 20,
    vatrate numeric(5,2) DEFAULT 20,
    "vatRate" numeric(5,2) DEFAULT 20,
    tax_type character varying(20),
    withholding_rate numeric(5,2),
    currency character varying(10) DEFAULT 'IQD'::character varying,
    price numeric(15,2) DEFAULT 0,
    cost numeric(15,2) DEFAULT 0,
    stock numeric(15,2) DEFAULT 0,
    min_stock numeric(15,2) DEFAULT 0,
    max_stock numeric(15,2) DEFAULT 0,
    critical_stock numeric(15,2) DEFAULT 0,
    tracking_type character varying(20) DEFAULT 'none'::character varying,
    shelf_location character varying(50),
    warehouse_code character varying(50),
    special_code_1 character varying(50),
    special_code_2 character varying(50),
    special_code_3 character varying(50),
    special_code_4 character varying(50),
    special_code_5 character varying(50),
    special_code_6 character varying(50),
    specialcode1 character varying(50),
    specialcode2 character varying(50),
    specialcode3 character varying(50),
    specialcode4 character varying(50),
    specialcode5 character varying(50),
    specialcode6 character varying(50),
    price_list_1 numeric(15,2) DEFAULT 0,
    price_list_2 numeric(15,2) DEFAULT 0,
    price_list_3 numeric(15,2) DEFAULT 0,
    price_list_4 numeric(15,2) DEFAULT 0,
    price_list_5 numeric(15,2) DEFAULT 0,
    price_list_6 numeric(15,2) DEFAULT 0,
    pricelist1 numeric(15,2),
    pricelist2 numeric(15,2),
    pricelist3 numeric(15,2),
    pricelist4 numeric(15,2),
    pricelist5 numeric(15,2),
    pricelist6 numeric(15,2),
    purchase_price numeric(15,4) DEFAULT 0,
    purchase_price_usd numeric(15,2) DEFAULT 0,
    purchase_price_eur numeric(15,2) DEFAULT 0,
    sale_price_usd numeric(15,2) DEFAULT 0,
    sale_price_eur numeric(15,2) DEFAULT 0,
    custom_exchange_rate numeric DEFAULT 0,
    auto_calculate_usd boolean DEFAULT false,
    preparation_time integer DEFAULT 5,
    follow_up_reminder_days integer,
    has_variants boolean DEFAULT false,
    hasvariants boolean DEFAULT false,
    "hasVariants" boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_sales_reps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_sales_reps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    code character varying(50),
    name character varying(255) NOT NULL,
    phone character varying(50),
    email character varying(255),
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: rex_001_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_services (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    code character varying(100) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    description_tr text,
    description_en text,
    description_ar text,
    description_ku text,
    category character varying(255),
    category_id uuid,
    category_code character varying(50),
    brand character varying(100),
    model character varying(100),
    manufacturer character varying(100),
    supplier character varying(100),
    origin character varying(50),
    group_code character varying(50),
    sub_group_code character varying(50),
    special_code_1 character varying(50),
    special_code_2 character varying(50),
    special_code_3 character varying(50),
    special_code_4 character varying(50),
    special_code_5 character varying(50),
    special_code_6 character varying(50),
    unit character varying(50) DEFAULT 'Adet'::character varying,
    unit_price numeric(15,2) DEFAULT 0,
    unit_price_usd numeric(15,2) DEFAULT 0,
    unit_price_eur numeric(15,2) DEFAULT 0,
    purchase_price numeric(15,2) DEFAULT 0,
    purchase_price_usd numeric(15,2) DEFAULT 0,
    purchase_price_eur numeric(15,2) DEFAULT 0,
    tax_rate numeric(5,2) DEFAULT 18,
    tax_type character varying(20),
    withholding_rate numeric(5,2) DEFAULT 0,
    discount1 numeric(15,2) DEFAULT 0,
    discount2 numeric(15,2) DEFAULT 0,
    discount3 numeric(15,2) DEFAULT 0,
    image_url text,
    price_list_1 numeric(15,2) DEFAULT 0,
    price_list_2 numeric(15,2) DEFAULT 0,
    price_list_3 numeric(15,2) DEFAULT 0,
    price_list_4 numeric(15,2) DEFAULT 0,
    price_list_5 numeric(15,2) DEFAULT 0,
    price_list_6 numeric(15,2) DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_special_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_special_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50),
    name character varying(255) NOT NULL,
    description text,
    module_type character varying(50),
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_suppliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_suppliers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    code character varying(50),
    name character varying(255) NOT NULL,
    phone character varying(50),
    email character varying(255),
    tax_nr character varying(50),
    tax_office character varying(100),
    address text,
    city character varying(100),
    neighborhood character varying(100),
    district character varying(100),
    contact_person character varying(150),
    contact_person_phone character varying(50),
    payment_terms character varying(100),
    credit_limit numeric(15,2) DEFAULT 0,
    notes text,
    balance numeric(15,2) DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_tax_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_tax_rates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    rate numeric(5,2) NOT NULL,
    description character varying(255),
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_units; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_units (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(20),
    name character varying(100) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_unitsetl; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_unitsetl (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    unitset_id uuid,
    item_code character varying(20) NOT NULL,
    code character varying(50),
    name character varying(100),
    main_unit boolean DEFAULT false,
    multiplier1 numeric(15,2) DEFAULT 1,
    multiplier2 numeric(15,2) DEFAULT 1,
    conv_fact1 numeric(15,6) DEFAULT 1,
    conv_fact2 numeric(15,6) DEFAULT 1
);


--
-- Name: rex_001_unitsets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rex_001_unitsets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50),
    name character varying(255) NOT NULL,
    is_active boolean DEFAULT true
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    permissions jsonb DEFAULT '[]'::jsonb,
    is_system_role boolean DEFAULT false,
    color character varying(20) DEFAULT '#3B82F6'::character varying,
    landing_route character varying(100) DEFAULT NULL::character varying,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: COLUMN roles.landing_route; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.roles.landing_route IS 'Giriş sonrası açılacak modül: restaurant, pos, management, wms, beauty veya boş (ana sayfa).';


--
-- Name: service_health; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_health (
    service_id uuid DEFAULT gen_random_uuid() NOT NULL,
    service_name text NOT NULL,
    last_heartbeat timestamp with time zone DEFAULT now() NOT NULL,
    status text NOT NULL,
    version text,
    metadata jsonb DEFAULT '{}'::jsonb,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT service_health_status_check CHECK ((status = ANY (ARRAY['ONLINE'::text, 'OFFLINE'::text, 'ERROR'::text, 'MAINTENANCE'::text])))
);


--
-- Name: service_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    store_id uuid,
    transaction_type character varying(20) NOT NULL,
    provider character varying(50) NOT NULL,
    target_number character varying(50) NOT NULL,
    package_name character varying(100),
    amount numeric(15,2) NOT NULL,
    cost numeric(15,2) DEFAULT 0,
    profit numeric(15,2) GENERATED ALWAYS AS ((amount - cost)) STORED,
    currency character varying(10) DEFAULT 'IQD'::character varying,
    status character varying(20) DEFAULT 'completed'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: stores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stores (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(50),
    city character varying(100),
    region character varying(100),
    address text,
    phone character varying(50),
    email character varying(100),
    tax_office character varying(100),
    tax_number character varying(50),
    firm_nr character varying(10) NOT NULL,
    manager_name character varying(100),
    is_main boolean DEFAULT false,
    is_active boolean DEFAULT true,
    "default" boolean DEFAULT false,
    logo_warehouse_id integer,
    logo_division_id integer,
    logo_firm_id integer,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: sync_queue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sync_queue (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    table_name character varying(100) NOT NULL,
    record_id uuid NOT NULL,
    action character varying(20) NOT NULL,
    firm_nr character varying(10) NOT NULL,
    data jsonb,
    status character varying(20) DEFAULT 'pending'::character varying,
    target_store_id uuid,
    source_system character varying(50) DEFAULT 'RetailEX'::character varying,
    synced_at timestamp with time zone,
    retry_count integer DEFAULT 0,
    error_message text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: sys_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_migrations (
    id integer NOT NULL,
    version character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    applied_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    app_version character varying(50)
);


--
-- Name: sys_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sys_migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sys_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sys_migrations_id_seq OWNED BY public.sys_migrations.id;


--
-- Name: system_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_settings (
    id smallint DEFAULT 1 NOT NULL,
    default_currency character varying(10) DEFAULT 'IQD'::character varying NOT NULL,
    primary_firm_nr character varying(10),
    primary_period_nr character varying(10),
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT system_settings_singleton CHECK ((id = 1))
);


--
-- Name: units; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.units (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    is_active boolean DEFAULT true
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    username character varying(100) NOT NULL,
    password_hash text,
    full_name character varying(255) NOT NULL,
    email character varying(255),
    phone character varying(50),
    role character varying(50) DEFAULT 'cashier'::character varying,
    role_id uuid,
    store_id uuid,
    is_active boolean DEFAULT true,
    last_login_at timestamp with time zone,
    allowed_firm_nrs jsonb DEFAULT '[]'::jsonb,
    allowed_periods jsonb DEFAULT '[]'::jsonb,
    allowed_store_ids jsonb DEFAULT '[]'::jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: floors; Type: TABLE; Schema: rest; Owner: -
--

CREATE TABLE rest.floors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    store_id uuid,
    name character varying(100) NOT NULL,
    color character varying(50) DEFAULT '#3B82F6'::character varying,
    display_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: kroki_layouts; Type: TABLE; Schema: rest; Owner: -
--

CREATE TABLE rest.kroki_layouts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    store_id uuid,
    floor_name character varying(100) DEFAULT 'Tümü'::character varying NOT NULL,
    layout_data jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: printer_profiles; Type: TABLE; Schema: rest; Owner: -
--

CREATE TABLE rest.printer_profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    store_id uuid,
    name character varying(100) NOT NULL,
    type character varying(20) DEFAULT 'thermal'::character varying,
    address character varying(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: return_log; Type: TABLE; Schema: rest; Owner: -
--

CREATE TABLE rest.return_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    return_number character varying(50) NOT NULL,
    original_receipt character varying(100),
    product_id uuid,
    product_name character varying(255) NOT NULL,
    quantity numeric(15,3) DEFAULT 1 NOT NULL,
    unit_price numeric(15,2) DEFAULT 0 NOT NULL,
    total_amount numeric(15,2) DEFAULT 0 NOT NULL,
    return_reason text NOT NULL,
    staff_name character varying(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_rest_kitchen_items; Type: TABLE; Schema: rest; Owner: -
--

CREATE TABLE rest.rex_001_01_rest_kitchen_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    kitchen_order_id uuid,
    order_item_id uuid,
    product_name character varying(255) NOT NULL,
    quantity numeric(15,3) NOT NULL,
    course character varying(50),
    note text,
    status character varying(20) DEFAULT 'new'::character varying,
    preparation_time integer,
    start_at timestamp with time zone,
    estimated_ready_at timestamp with time zone,
    served_at timestamp with time zone
);


--
-- Name: rex_001_01_rest_kitchen_orders; Type: TABLE; Schema: rest; Owner: -
--

CREATE TABLE rest.rex_001_01_rest_kitchen_orders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid,
    table_number character varying(50),
    floor_name character varying(100),
    waiter character varying(255),
    staff_id uuid,
    status character varying(20) DEFAULT 'new'::character varying,
    note text,
    estimated_ready_at timestamp with time zone,
    sent_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_rest_order_items; Type: TABLE; Schema: rest; Owner: -
--

CREATE TABLE rest.rex_001_01_rest_order_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid,
    product_id uuid,
    product_name character varying(255) NOT NULL,
    quantity numeric(15,3) DEFAULT 1 NOT NULL,
    unit_price numeric(15,2) NOT NULL,
    discount_pct numeric(5,2) DEFAULT 0,
    subtotal numeric(15,2) NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying,
    course character varying(50),
    note text,
    options jsonb,
    is_void boolean DEFAULT false,
    void_reason text,
    is_complimentary boolean DEFAULT false,
    preparation_time integer,
    sent_to_kitchen_at timestamp with time zone,
    served_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_rest_orders; Type: TABLE; Schema: rest; Owner: -
--

CREATE TABLE rest.rex_001_01_rest_orders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_no character varying(50),
    table_id uuid,
    floor_id uuid,
    waiter character varying(255),
    staff_id uuid,
    customer_id uuid,
    status character varying(20) DEFAULT 'open'::character varying,
    total_amount numeric(15,2) DEFAULT 0,
    discount_amount numeric(15,2) DEFAULT 0,
    order_discount_pct numeric(5,2) DEFAULT 0,
    tax_amount numeric(15,2) DEFAULT 0,
    note text,
    parent_order_id uuid,
    kitchen_note text,
    estimated_ready_at timestamp with time zone,
    opened_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    billed_at timestamp with time zone,
    closed_at timestamp with time zone,
    payment_method character varying(50),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_01_rest_reservations; Type: TABLE; Schema: rest; Owner: -
--

CREATE TABLE rest.rex_001_01_rest_reservations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_id uuid,
    customer_name text NOT NULL,
    phone text NOT NULL,
    reservation_date date NOT NULL,
    reservation_time time without time zone NOT NULL,
    guest_count integer DEFAULT 2 NOT NULL,
    table_id uuid,
    table_number text,
    status text DEFAULT 'pending'::text NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: rex_001_rest_recipe_ingredients; Type: TABLE; Schema: rest; Owner: -
--

CREATE TABLE rest.rex_001_rest_recipe_ingredients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    recipe_id uuid,
    material_id uuid,
    quantity numeric(15,3),
    unit character varying(20),
    cost numeric(15,2) DEFAULT 0
);


--
-- Name: rex_001_rest_recipes; Type: TABLE; Schema: rest; Owner: -
--

CREATE TABLE rest.rex_001_rest_recipes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    menu_item_id uuid,
    product_id uuid,
    total_cost numeric(15,2) DEFAULT 0,
    wastage_percent numeric(5,2) DEFAULT 0,
    is_active boolean DEFAULT true,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_rest_staff; Type: TABLE; Schema: rest; Owner: -
--

CREATE TABLE rest.rex_001_rest_staff (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    role character varying(50) DEFAULT 'Waiter'::character varying,
    pin character varying(10) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rex_001_rest_tables; Type: TABLE; Schema: rest; Owner: -
--

CREATE TABLE rest.rex_001_rest_tables (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    floor_id uuid,
    number character varying(50) NOT NULL,
    seats integer DEFAULT 4,
    status character varying(20) DEFAULT 'empty'::character varying,
    total numeric(15,2) DEFAULT 0,
    pos_x integer DEFAULT 0,
    pos_y integer DEFAULT 0,
    is_large boolean DEFAULT false,
    waiter character varying(255),
    staff_id uuid,
    start_time timestamp with time zone,
    locked_by_staff_id uuid,
    locked_by_staff_name character varying(255),
    locked_at timestamp with time zone,
    linked_order_ids text[] DEFAULT '{}'::text[],
    color character varying(20) DEFAULT NULL::character varying,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: staff_roles; Type: TABLE; Schema: rest; Owner: -
--

CREATE TABLE rest.staff_roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(50) NOT NULL,
    permissions jsonb DEFAULT '{}'::jsonb
);


--
-- Name: bins; Type: TABLE; Schema: wms; Owner: -
--

CREATE TABLE wms.bins (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    store_id uuid,
    code character varying(50) NOT NULL,
    zone character varying(50),
    aisle character varying(50),
    shelf character varying(50),
    bin character varying(50),
    capacity_m3 numeric(15,3),
    max_weight numeric(15,2),
    is_active boolean DEFAULT true
);


--
-- Name: counting_lines; Type: TABLE; Schema: wms; Owner: -
--

CREATE TABLE wms.counting_lines (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    slip_id uuid,
    firm_nr character varying(10),
    product_id uuid,
    product_ref integer,
    barcode character varying(100),
    product_name character varying(500),
    bin_id uuid,
    location_code character varying(50),
    expected_qty numeric(15,2),
    counted_qty numeric(15,2),
    variance numeric(15,2),
    counted_by character varying(255),
    counted_at timestamp with time zone,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: counting_slips; Type: TABLE; Schema: wms; Owner: -
--

CREATE TABLE wms.counting_slips (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    store_id uuid NOT NULL,
    fiche_no character varying(50) NOT NULL,
    date timestamp with time zone DEFAULT now(),
    status character varying(20) DEFAULT 'draft'::character varying,
    count_type character varying(20) DEFAULT 'full'::character varying,
    location_code character varying(50),
    description text,
    created_by uuid,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN counting_slips.status; Type: COMMENT; Schema: wms; Owner: -
--

COMMENT ON COLUMN wms.counting_slips.status IS 'draft | active | counting | reconciliation | completed | cancelled';


--
-- Name: COLUMN counting_slips.count_type; Type: COMMENT; Schema: wms; Owner: -
--

COMMENT ON COLUMN wms.counting_slips.count_type IS 'full | cycle | location';


--
-- Name: dispatch_lines; Type: TABLE; Schema: wms; Owner: -
--

CREATE TABLE wms.dispatch_lines (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    slip_id uuid,
    product_id uuid,
    product_code character varying(100),
    product_name character varying(255),
    barcode character varying(100),
    requested_qty numeric(15,3) DEFAULT 0,
    picked_qty numeric(15,3) DEFAULT 0,
    unit character varying(20),
    notes text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: dispatch_slips; Type: TABLE; Schema: wms; Owner: -
--

CREATE TABLE wms.dispatch_slips (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    store_id uuid,
    slip_no character varying(50) NOT NULL,
    customer_name character varying(255),
    priority character varying(20) DEFAULT 'normal'::character varying,
    notes text,
    status character varying(20) DEFAULT 'draft'::character varying,
    created_by character varying(100),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: dock_doors; Type: TABLE; Schema: wms; Owner: -
--

CREATE TABLE wms.dock_doors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10),
    code character varying(20) NOT NULL,
    name character varying(100) NOT NULL,
    type character varying(20) DEFAULT 'inbound'::character varying,
    warehouse_id uuid,
    status character varying(20) DEFAULT 'available'::character varying,
    vehicle_plate character varying(20),
    carrier_name character varying(100),
    assigned_at timestamp with time zone,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: labor_productivity; Type: TABLE; Schema: wms; Owner: -
--

CREATE TABLE wms.labor_productivity (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10),
    user_id uuid,
    username character varying(255),
    task_type character varying(50),
    reference_id uuid,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone,
    duration_min numeric(10,2) GENERATED ALWAYS AS (
CASE
    WHEN (end_time IS NOT NULL) THEN (EXTRACT(epoch FROM (end_time - start_time)) / (60)::numeric)
    ELSE NULL::numeric
END) STORED,
    items_processed numeric(18,5) DEFAULT 0,
    lines_processed integer DEFAULT 0,
    efficiency_rate numeric(5,2),
    warehouse_id uuid,
    notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: personnel; Type: TABLE; Schema: wms; Owner: -
--

CREATE TABLE wms.personnel (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    store_id uuid,
    role character varying(50),
    is_active boolean DEFAULT true
);


--
-- Name: pick_waves; Type: TABLE; Schema: wms; Owner: -
--

CREATE TABLE wms.pick_waves (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    wave_no character varying(50) NOT NULL,
    firm_nr character varying(10),
    warehouse_id uuid,
    status character varying(20) DEFAULT 'draft'::character varying,
    priority integer DEFAULT 5,
    wave_type character varying(30) DEFAULT 'standard'::character varying,
    total_lines integer DEFAULT 0,
    picked_lines integer DEFAULT 0,
    total_qty numeric(18,5) DEFAULT 0,
    picked_qty numeric(18,5) DEFAULT 0,
    assigned_to character varying(255),
    released_at timestamp with time zone,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    due_date timestamp with time zone,
    notes text,
    created_by character varying(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: receiving_lines; Type: TABLE; Schema: wms; Owner: -
--

CREATE TABLE wms.receiving_lines (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    slip_id uuid,
    product_id uuid,
    product_code character varying(100),
    product_name character varying(255),
    barcode character varying(100),
    ordered_qty numeric(15,3) DEFAULT 0,
    received_qty numeric(15,3) DEFAULT 0,
    unit character varying(20),
    notes text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: receiving_slips; Type: TABLE; Schema: wms; Owner: -
--

CREATE TABLE wms.receiving_slips (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    store_id uuid,
    slip_no character varying(50) NOT NULL,
    supplier_name character varying(255),
    notes text,
    status character varying(20) DEFAULT 'draft'::character varying,
    created_by character varying(100),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: slotting_recommendations; Type: TABLE; Schema: wms; Owner: -
--

CREATE TABLE wms.slotting_recommendations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10),
    product_id uuid,
    product_code character varying(100),
    product_name character varying(255),
    current_location character varying(50),
    recommended_location character varying(50),
    reason character varying(255),
    velocity_class character varying(1),
    daily_picks numeric(10,2) DEFAULT 0,
    distance_saved_m numeric(8,2),
    is_applied boolean DEFAULT false,
    applied_at timestamp with time zone,
    applied_by character varying(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: task_queue; Type: TABLE; Schema: wms; Owner: -
--

CREATE TABLE wms.task_queue (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10),
    task_type character varying(30) NOT NULL,
    reference_id uuid,
    reference_no character varying(50),
    priority integer DEFAULT 5,
    status character varying(20) DEFAULT 'pending'::character varying,
    assigned_to character varying(255),
    assigned_at timestamp with time zone,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    warehouse_id uuid,
    bin_location character varying(50),
    product_code character varying(100),
    quantity numeric(18,5) DEFAULT 0,
    notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: transfer_items; Type: TABLE; Schema: wms; Owner: -
--

CREATE TABLE wms.transfer_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_id uuid,
    product_id uuid,
    quantity numeric(15,2) DEFAULT 0,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: transfers; Type: TABLE; Schema: wms; Owner: -
--

CREATE TABLE wms.transfers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10) NOT NULL,
    fiche_no character varying(50) NOT NULL,
    source_store_id uuid NOT NULL,
    target_store_id uuid NOT NULL,
    date timestamp with time zone DEFAULT now(),
    status character varying(20) DEFAULT 'pending'::character varying,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: yard_locations; Type: TABLE; Schema: wms; Owner: -
--

CREATE TABLE wms.yard_locations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    firm_nr character varying(10),
    code character varying(50) NOT NULL,
    type character varying(50) DEFAULT 'parking'::character varying,
    status character varying(20) DEFAULT 'available'::character varying,
    vehicle_plate character varying(20),
    driver_name character varying(255),
    entry_time timestamp with time zone,
    exit_time timestamp with time zone,
    warehouse_id uuid,
    notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: menu_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_items ALTER COLUMN id SET DEFAULT nextval('public.menu_items_id_seq'::regclass);


--
-- Name: sys_migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_migrations ALTER COLUMN id SET DEFAULT nextval('public.sys_migrations_id_seq'::regclass);


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.users (id, email, encrypted_password, raw_user_meta_data, created_at, updated_at) FROM stdin;
aee369ed-a268-42ca-8818-e55553378477	admin@retailex.local	$2a$06$itE51vfeOuqxLlXjadupNeS6b/T84L7XuyK59uWvv/dab5Gmox9ey	{"role": "admin", "firm_nr": "001", "username": "admin", "full_name": "Sistem Yöneticisi"}	2026-05-24 12:50:37.676047+03	2026-05-24 12:50:37.676047+03
9e62ab75-fe7f-48f2-b85b-6ef184a62a73	personel@retailex.local	$2a$06$g8xXG0dgwLm5Ak547YDqEuoBtWgIhAYlnwd.2JP9Fic7qrGTTiAoG	{"role": "user", "firm_nr": "001", "username": "personel", "full_name": "Saha Personeli"}	2026-05-24 12:50:37.732119+03	2026-05-24 12:50:37.732119+03
4cff678f-defe-4985-9270-64d8c0fb0a57	depo@retailex.local	$2a$06$Uri3trmrMiKoTeMsTYTK5exJJtIOUrbQhy6Gjc2Q3zS5sQrFSgzhu	{"role": "warehouse", "firm_nr": "001", "username": "depo", "full_name": "Depo Sorumlusu"}	2026-05-24 12:50:37.757772+03	2026-05-24 12:50:37.757772+03
0533208d-dac9-464c-8522-3f94befacb6f	kasiyer@retailex.local	$2a$06$bI/hq2uMyJFJuI3l1iqTE.dPUsLaVXaqMruU7s.jQnFoEJ8LJTE2C	{"role": "cashier", "firm_nr": "001", "username": "kasiyer", "full_name": "Kasa Görevlisi"}	2026-05-24 12:50:37.803411+03	2026-05-24 12:50:37.803411+03
\.


--
-- Data for Name: body_regions; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.body_regions (id, name, avg_shots, min_shots, max_shots, sort_order) FROM stdin;
340f2107-a452-4f08-8cf4-1e833b83d1ff	Yüz	200	150	350	1
4b70dad2-0695-49b8-9a13-fe9bc3960fab	Koltuk Altı	150	100	250	2
3162ccfd-05ca-45fb-9739-166ea77e20b3	Bacak (Tam)	1200	800	1800	3
1efb956e-8bf1-4ebf-a145-44596d23b3c5	Bacak (Alt Yarı)	600	400	900	4
f1879f9e-b7a7-4ad1-b2e0-71523ab93802	Bacak (Üst Yarı)	600	400	900	5
dd281d27-7a5e-447f-b8f3-6cdf5ecc79da	Bikini (Tam)	300	200	500	6
50d89b49-af42-459c-9192-240a2a6c200b	Bikini (Dar)	150	100	250	7
67c7c29e-ff90-48ce-a8af-179e243edd33	Kol (Tam)	500	350	750	8
88be75b9-1cf2-4aec-b912-7a84d6874e46	Kol (Yarım)	250	175	400	9
415115a0-9b60-4e83-90ef-e1a6fee2e811	Sırt	800	500	1200	10
9990d51f-b058-45f6-a506-b95aeaa63833	Göğüs	500	300	800	11
c62c543f-3501-4e43-9a62-c7deb2f054ef	Yüz + Boyun	350	250	500	12
36d9bb2e-d2b2-4e39-9a11-378a83a08593	Bıyık / Çene	100	60	180	13
\.


--
-- Data for Name: rex_001_01_beauty_appointments; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_appointments (id, client_id, service_id, specialist_id, device_id, body_region_id, appointment_date, appointment_time, duration, status, type, notes, total_price, commission_amount, is_package_session, package_purchase_id, reminder_sent, branch_id, room_id, tele_meeting_url, booking_channel, corporate_account_id, reminder_sent_at, last_notification_channel, session_series_id, confirmation_call_at, pre_visit_activity_at, treatment_degree, treatment_shots, clinical_data, created_at, updated_at) FROM stdin;
861a3e8f-1a5c-4338-8e8c-9c19303a962c	2dc07a6f-0f2b-420b-8837-5a7e65acdba7	f3445470-225c-4770-9e6d-484e65e3d1af	0b00a74e-0e92-4a15-9e46-e26759145e6d	\N	\N	2026-02-05	10:00:00	90	scheduled	regular	\N	2500.00	0.00	f	\N	f	\N	\N	\N	staff	\N	\N	\N	\N	\N	\N	\N	\N	{}	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
4d7b6c58-c9d1-4233-8de2-0fbc08a9b432	2dc07a6f-0f2b-420b-8837-5a7e65acdba7	f3445470-225c-4770-9e6d-484e65e3d1af	0b00a74e-0e92-4a15-9e46-e26759145e6d	\N	\N	2026-01-15	10:00:00	90	completed	regular	\N	2500.00	0.00	f	\N	f	\N	\N	\N	staff	\N	\N	\N	\N	\N	\N	\N	\N	{}	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
5d07f084-391d-452b-97ac-ce932e866b0e	2dc07a6f-0f2b-420b-8837-5a7e65acdba7	20b278f3-2140-4d8c-b44c-d28095adf841	0b00a74e-0e92-4a15-9e46-e26759145e6d	\N	\N	2026-01-22	10:00:00	30	completed	regular	\N	800.00	0.00	f	\N	f	\N	\N	\N	staff	\N	\N	\N	\N	\N	\N	\N	\N	{}	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
3832276f-a1dd-4f3e-9ffc-80a638a5e962	a273f014-47b6-4a4a-82f4-e38bb02b7353	e520ec15-61c3-431f-a850-fe7adced73d1	6a685998-be5e-4c2c-9c7a-e448653fde3d	\N	\N	2026-01-20	14:00:00	60	completed	regular	\N	1200.00	0.00	f	\N	f	\N	\N	\N	staff	\N	\N	\N	\N	\N	\N	\N	\N	{}	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
5d07a491-a1b9-47dd-8908-285827e16999	d00bc030-5e82-4004-91fc-134ee5da1c1c	f7092df9-94e6-485e-9c32-77e9a302e534	85875548-c89f-41bc-ba2b-280596fcd11d	\N	\N	2026-01-25	11:00:00	90	completed	regular	\N	1800.00	0.00	f	\N	f	\N	\N	\N	staff	\N	\N	\N	\N	\N	\N	\N	\N	{}	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
351dadce-781a-424c-9f99-1fae778850f8	a273f014-47b6-4a4a-82f4-e38bb02b7353	d3b8ab28-6919-442b-91c8-6e7b761e67d5	85875548-c89f-41bc-ba2b-280596fcd11d	\N	\N	2026-02-07	15:00:00	60	scheduled	regular	\N	650.00	0.00	f	\N	f	\N	\N	\N	staff	\N	\N	\N	\N	\N	\N	\N	\N	{}	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: rex_001_01_beauty_audit_log; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_audit_log (id, table_name, record_id, action, user_id, payload_json, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_beauty_booking_requests; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_booking_requests (id, name, phone, email, service_id, requested_date, requested_time, notes, status, public_token_used, processed_appointment_id, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_beauty_clinical_notes; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_clinical_notes (id, appointment_id, customer_id, subjective, objective, assessment, plan, extra_json, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_beauty_consent_submissions; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_consent_submissions (id, customer_id, appointment_id, template_id, signed_at, signature_data, meta_json, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_beauty_consumable_usage_log; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_consumable_usage_log (id, appointment_id, product_id, qty, batch_id, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_beauty_customer_feedback; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_customer_feedback (id, appointment_id, customer_id, service_rating, staff_rating, cleanliness_rating, overall_rating, comment, would_recommend, survey_id, survey_answers, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_beauty_device_alerts; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_device_alerts (id, device_id, usage_id, alert_type, message, severity, acknowledged, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_beauty_device_usage; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_device_usage (id, device_id, appointment_id, customer_id, specialist_id, body_region_id, shots_used, expected_shots, is_excessive, usage_date, notes, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_beauty_membership_subscriptions; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_membership_subscriptions (id, customer_id, membership_id, start_date, end_date, status, auto_renew, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_beauty_notification_queue; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_notification_queue (id, appointment_id, channel, payload_json, status, scheduled_at, sent_at, error_text, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_beauty_package_purchases; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_package_purchases (id, customer_id, package_id, total_sessions, used_sessions, remaining_sessions, sale_price, purchase_date, expiry_date, status, created_at) FROM stdin;
67182a86-2dd2-4d10-9943-83079cb5a511	2dc07a6f-0f2b-420b-8837-5a7e65acdba7	d02f847b-d188-4106-b746-c76d62a140b7	6	2	4	12750.00	2026-01-15	2027-01-15	active	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: rex_001_01_beauty_package_sales; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_package_sales (id, customer_id, package_id, total_sessions, sale_price, sale_date, expiry_date, status) FROM stdin;
\.


--
-- Data for Name: rex_001_01_beauty_patient_photos; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_patient_photos (id, customer_id, appointment_id, kind, storage_url, caption, taken_at, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_beauty_sale_items; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_sale_items (id, sale_id, item_type, item_id, name, quantity, unit_price, discount, total, staff_id, commission_amount, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_beauty_sales; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_sales (id, invoice_number, customer_id, subtotal, discount, tax, total, payment_method, payment_status, paid_amount, remaining_amount, notes, created_by, created_at) FROM stdin;
50b8ce1d-43ae-4751-82e3-8b1a8a40721c	BPOS-2026-001	a273f014-47b6-4a4a-82f4-e38bb02b7353	4300.00	0.00	0.00	4300.00	cash	paid	4300.00	0.00	\N	\N	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: rex_001_01_beauty_session_logs; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_session_logs (id, package_purchase_id, appointment_id, session_number, recorded_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_beauty_sessions; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_sessions (id, customer_id, specialist_id, service_id, appointment_id, session_date, shots_used, skin_type, before_photo, after_photo, notes, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_beauty_waitlist; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_01_beauty_waitlist (id, customer_id, service_id, specialist_id, preferred_date_from, preferred_date_to, notes, status, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_beauty_branches; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_branches (id, name, address, phone, is_active, sort_order, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_beauty_consent_templates; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_consent_templates (id, title, body_html, is_active, sort_order, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_beauty_corporate_accounts; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_corporate_accounts (id, name, tax_nr, discount_pct, notes, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_beauty_customer_health; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_customer_health (customer_id, allergies, medications, pregnancy, chronic_notes, warnings_banner, kvkk_consent_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rex_001_beauty_devices; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_devices (id, name, device_type, serial_number, manufacturer, model, total_shots, max_shots, maintenance_due, last_maintenance, purchase_date, warranty_expiry, status, notes, is_active, created_at, updated_at) FROM stdin;
3c4d2e72-b301-4057-b06c-73fce80dabc9	Candela 1	laser	CD-001	Candela	Gentle series	45200	500000	\N	\N	\N	\N	active	\N	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
7ecd8ed8-bb88-42d8-8095-cc1dfef6675e	Candela 2	laser	CD-002	Candela	Gentle series	38000	500000	\N	\N	\N	\N	active	\N	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
7c4a7c73-3f86-427a-ab79-6f5f3191c007	Epilyum 1	laser	EP-001	Epilyum	Epilyum	21000	500000	\N	\N	\N	\N	active	\N	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
d2a701c4-737d-409f-8b2d-9fdded1df897	Epilyum 2	laser	EP-002	Epilyum	Epilyum	19500	500000	\N	\N	\N	\N	active	\N	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
e5119a46-e424-48f9-aa77-d1d015c169fc	Hydrafacial	facial	HF-001	HydraFacial	Syndeo	0	0	\N	\N	\N	\N	active	\N	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: rex_001_beauty_integration_settings; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_integration_settings (id, google_calendar_id, external_calendar_json, updated_at) FROM stdin;
1	\N	{}	2026-05-24 12:50:05.210334+03
\.


--
-- Data for Name: rex_001_beauty_leads; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_leads (id, name, phone, email, source, status, interested_services, notes, assigned_to, first_contact_date, last_contact_date, converted_customer_id, lost_reason, created_at, updated_at) FROM stdin;
cc6f23d3-b842-48a6-bdfd-bb347890f338	Hira Al-Ansari	+964 770 500 0001	hira@mail.com	instagram	interested	["Bacak Lazer Epilasyon (Tam)"]	Instagram reklamından geldi	\N	2026-05-24	\N	\N	\N	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
d5f92d1c-8951-4e41-9fb0-8b1f1d9b1cc2	Nour Jamil	+964 770 500 0002	nour@mail.com	referral	contacted	["Yüz Bakımı", "Saç Boyama"]	BCust-001 tarafından yönlendirildi	\N	2026-05-24	\N	\N	\N	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
15e0689e-30aa-407e-b38f-4df38b772b63	Rania Said	+964 770 500 0003	rania@mail.com	walk_in	new	["Manikür & Pedikür"]	Mağaza önünden girdi	\N	2026-05-24	\N	\N	\N	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: rex_001_beauty_marketing_campaigns; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_marketing_campaigns (id, name, channel, segment_filter_json, message_template, scheduled_at, status, sent_count, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_beauty_memberships; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_memberships (id, name, monthly_price, session_credit, benefits_json, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rex_001_beauty_packages; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_packages (id, name, description, service_id, total_sessions, price, cost_price, discount_pct, validity_days, color, is_active, created_at, updated_at) FROM stdin;
d02f847b-d188-4106-b746-c76d62a140b7	Bacak Epilasyon 6li Paket	6 seans — %15 indirimli	f3445470-225c-4770-9e6d-484e65e3d1af	6	12750.00	4800.00	15.00	365	#6366f1	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
2e5eb76c-b24e-4515-84bc-60a1f0f2dba9	Yüz Bakımı 4lü Paket	4 seans — %10 indirimli	e520ec15-61c3-431f-a850-fe7adced73d1	4	4320.00	1600.00	10.00	180	#6366f1	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: rex_001_beauty_portal_settings; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_portal_settings (id, online_booking_enabled, allow_staff_slot_overlap, public_slug, public_token, reminder_hours_before, sms_template, whatsapp_template, sms_user, sms_password, sms_sender, whatsapp_provider, whatsapp_base_url, whatsapp_token, whatsapp_instance_id, whatsapp_phone_id, default_reminder_channel, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rex_001_beauty_product_batches; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_product_batches (id, product_id, lot_code, expiry_date, qty, barcode, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_beauty_rooms; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_rooms (id, branch_id, name, capacity, is_active, sort_order, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_beauty_satisfaction_questions; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_satisfaction_questions (id, survey_id, sort_order, question_type, scale_max, is_required, labels_json, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rex_001_beauty_satisfaction_surveys; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_satisfaction_surveys (id, name, is_active, sort_order, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rex_001_beauty_service_consumables; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_service_consumables (id, service_id, product_id, qty_per_service, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_beauty_services; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_services (id, name, category, parent_category, duration_min, price, cost_price, color, commission_rate, description, requires_device, expected_shots, default_sessions, follow_up_reminder_days, is_active, created_at, updated_at) FROM stdin;
f3445470-225c-4770-9e6d-484e65e3d1af	Bacak Lazer Epilasyon (Tam)	laser	\N	90	2500.00	800.00	#9333ea	15.00	\N	f	1200	1	\N	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
20b278f3-2140-4d8c-b44c-d28095adf841	Koltuk Altı Lazer	laser	\N	30	800.00	250.00	#9333ea	15.00	\N	f	150	1	\N	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
e520ec15-61c3-431f-a850-fe7adced73d1	Yüz Bakımı	facial	\N	60	1200.00	400.00	#9333ea	12.00	\N	f	0	1	\N	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
f7092df9-94e6-485e-9c32-77e9a302e534	Saç Boyama	hair	\N	90	1800.00	600.00	#9333ea	10.00	\N	f	0	1	\N	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
d3b8ab28-6919-442b-91c8-6e7b761e67d5	Manikür & Pedikür	nail	\N	60	650.00	200.00	#9333ea	10.00	\N	f	0	1	\N	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: rex_001_beauty_specialists; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_beauty_specialists (id, name, phone, email, specialty, color, commission_rate, product_unit_commission, avatar_url, working_hours, is_active, created_at, updated_at) FROM stdin;
0b00a74e-0e92-4a15-9e46-e26759145e6d	Zahra	+964 770 300 0001	\N	Lazer Epilasyon	#9333ea	15.00	0.00	\N	\N	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
6a685998-be5e-4c2c-9c7a-e448653fde3d	Fatma	+964 770 300 0002	\N	Cilt Bakımı	#ec4899	12.00	0.00	\N	\N	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
85875548-c89f-41bc-ba2b-280596fcd11d	Shoxan	+964 770 300 0003	\N	Saç Bakımı	#f97316	10.00	0.00	\N	\N	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: rex_001_follow_up_reminder_actions; Type: TABLE DATA; Schema: beauty; Owner: -
--

COPY beauty.rex_001_follow_up_reminder_actions (id, firm_nr, customer_id, service_id, product_id, reminder_kind, last_completed_date, natural_due_date, reminder_days, customer_name, customer_phone, service_name, product_name, status, postponed_due_date, note, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: bank_accounts; Type: TABLE DATA; Schema: logic; Owner: -
--

COPY logic.bank_accounts (id, firm_nr, code, name, bank_name, iban, currency_code, balance, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: campaigns; Type: TABLE DATA; Schema: logic; Owner: -
--

COPY logic.campaigns (id, firm_nr, code, name, campaign_type, discount_value, start_date, end_date, is_active, conditions, created_at) FROM stdin;
\.


--
-- Data for Name: app_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.app_settings (id, key, value, firm_nr) FROM stdin;
dbe38bd5-d92f-4247-ba8f-4d61d9a588e9	restaurant_printer_config	{"printerRoutes": [{"id": "e9fa79af-78ed-4289-94be-0f81227f0eab", "printerId": "732af68b-c579-4b3d-aa9d-7293c1ce4872", "categoryId": "ANA YEMEKLER", "printerName": "MUTFAK", "printerType": "thermal", "connectionType": "system"}, {"id": "a9a3e270-ca1e-4a5f-8150-e8d09f28244a", "printerId": "732af68b-c579-4b3d-aa9d-7293c1ce4872", "categoryId": "ATIŞTIRMALIK", "printerName": "MUTFAK", "printerType": "thermal", "connectionType": "system"}, {"id": "3f2ecfc8-67f9-4649-a73a-ce21ed0f30c8", "printerId": "732af68b-c579-4b3d-aa9d-7293c1ce4872", "categoryId": "Elektronik", "printerName": "MUTFAK", "printerType": "thermal", "connectionType": "system"}, {"id": "39e8d5dc-2016-4d8e-98ef-225bce5f61e9", "printerId": "732af68b-c579-4b3d-aa9d-7293c1ce4872", "categoryId": "Gıda & İçecek", "printerName": "MUTFAK", "printerType": "thermal", "connectionType": "system"}, {"id": "294ad3e4-f188-4b6b-9907-3d914061e380", "printerId": "732af68b-c579-4b3d-aa9d-7293c1ce4872", "categoryId": "Güzellik & Bakım", "printerName": "MUTFAK", "printerType": "thermal", "connectionType": "system"}, {"id": "8145756c-0735-4754-b414-511c65ab1edf", "printerId": "732af68b-c579-4b3d-aa9d-7293c1ce4872", "categoryId": "İÇECEKLER", "printerName": "MUTFAK", "printerType": "thermal", "connectionType": "system"}, {"id": "b6641931-e0f9-4819-9c9a-42bd5f7f925b", "printerId": "732af68b-c579-4b3d-aa9d-7293c1ce4872", "categoryId": "SALATALAR", "printerName": "MUTFAK", "printerType": "thermal", "connectionType": "system"}, {"id": "636efd3f-3a0a-4e40-ad23-d3f9ccd25915", "printerId": "732af68b-c579-4b3d-aa9d-7293c1ce4872", "categoryId": "TATLILAR", "printerName": "MUTFAK", "printerType": "thermal", "connectionType": "system"}, {"id": "0e073d0f-2b52-409a-aee5-eb68a2ecd3e6", "printerId": "732af68b-c579-4b3d-aa9d-7293c1ce4872", "categoryId": "Tekstil", "printerName": "MUTFAK", "printerType": "thermal", "connectionType": "system"}, {"id": "c73b09d4-2f5f-4852-b7b3-1da348ea7f4e", "printerId": "732af68b-c579-4b3d-aa9d-7293c1ce4872", "categoryId": "Temizlik", "printerName": "MUTFAK", "printerType": "thermal", "connectionType": "system"}, {"id": "5c957ee8-8761-4912-8737-d7bf871daf27", "printerId": "732af68b-c579-4b3d-aa9d-7293c1ce4872", "categoryId": "ÇORBALAR", "printerName": "MUTFAK", "printerType": "thermal", "connectionType": "system"}], "commonPrinterId": "732af68b-c579-4b3d-aa9d-7293c1ce4872", "printerProfiles": [{"id": "732af68b-c579-4b3d-aa9d-7293c1ce4872", "name": "MUTFAK", "type": "thermal", "status": "online", "connection": "system", "systemName": "MUTFAK", "paperWidthMm": 80}]}	001
5f5fdd82-00eb-4327-8fac-446fc171684b	receipt_settings	{"logoDataUrl": "data:image/png;base64,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scfS8oknnnBtlKEA8vzzzxePPPJIsu2BbZYPPvhgWtYN/KoXft19993F3//+98S9996byq0K6Ao+CubWn1bQHo8++mjyMw+CZVCGgjntzbJOvhzsQN28Ss96qzzs5zjRD1jmUGfatZ3yc+QP0B6gY1B1vCzKjw9CfYbtLOv4p/JYWltAn2Ufx1f9U+eDUH+w2+jDLLFR1TdsWcFgEwI3pOhkU8A4+uijizXWWKN4xzve0cSqq66aluz7zGc+Uxx33HHFHXfcMcmW/Q3YJHggQNtvv32x2mqrNdnzePe7313cdtttk2yB/FVZN954Y/Gtb32reM973lO87W1vK5ZffvniDW94Q/H2t7+92GyzzYojjzwyiZ0CjQ2gNrj95S9/aaq3/Mv9tL933XXX4oEHHmgEWtm1KNhqSft++ctfLq677rrkk03bConjj3/84+JTn/pUccwxxzSVrTIsBNr99tuv2G233YpLLrnETSOwc9999xUf/ehHi3e+853pWFnYBmuvvXbxxS9+sTj77LObhEE2crvC+ikxgquvvrrYe++9iwsuuKBxoWXtVNkE9uP3xz72sdQm2NCxZZ/qbOvO9htuuKHYeuuti49//ONJlMijfCAfTz/99KbjvsoqqzTWy1hnnXVK+3AwfITADTmcyASAgw46qHjFK15RLLDAAsUb3/jG4i1veUuxwgorFG9+85sTyy23XPHqV7+6mGeeeYp3vetdKchxtW8DikUBkKt/gsTLXvayYumll05ihG1svulNb2osAXFiFKa8FnxkO6OIX//61ynYzDnnnMmnt771rcWaa66Z/MLGggsuWMwxxxzFuuuuW1xxxRUNe6qr1hGaiy++OPmEH9gB6v3iF7+4eOELX1i85jWvafgJ+L7DDjukwGj9w56FbZQFV111VTHffPMVs846a/GJT3yiEczzPFVQhw9/+MPFS1/60mKnnXZqiB77VI61yah2mWWWKeaaa67ixBNPbBKWHOzcc8896QLhJS95SfH6178+1VPtQv3pExy/eeedt1hkkUWSqNx8881u2R55OzEifP/735/a5H3ve1/aRx3Zx7Kuzdtvv71YYoklihkzZhSHH354Y9pRabCh37L3xz/+MbUj/YR2ojyVTVq17RlnnJH6A20haA/agPyLLrpo03720ddvvfXWhq1guAmBG1J0UrPOCf2d73wn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"}	001
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_logs (id, user_id, firm_nr, table_name, record_id, action, old_data, new_data, client_info, created_at) FROM stdin;
a7598546-4060-4f8e-b213-10097e5f8307	\N	000	system	00000000-0000-0000-0000-000000000000	MASTER_SCHEMA_V6	\N	{"status": "completed", "version": "6.0", "description": "Clean consolidated master schema"}	\N	2026-05-24 12:50:05.210334+03
\.


--
-- Data for Name: barcode_templates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.barcode_templates (id, name, prefix, current_value, length, is_active, created_at, updated_at) FROM stdin;
bd0c2a05-0bf9-4e48-a716-1af3f5fe5b9c	Varsayilan Sablon	869	1000000	13	t	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
\.


--
-- Data for Name: brands; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.brands (id, code, name, description, is_active) FROM stdin;
3dbdf86b-53d1-4ed4-96aa-914956c91bff	APPLE	Apple	Apple Inc.	t
d245b407-64b5-4f88-a32d-9034593c094e	SAMSUNG	Samsung	Samsung Electronics	t
a51ed874-2027-4fa4-aa49-41fe8a279a4c	NESTLE	Nestlé	Nestlé Gıda	t
0f108ea9-1b8d-4be4-88a5-9e70a5cc20be	COLA	Cola-Cola	İçecek Grubu	t
8eb18603-2e2a-49b8-8706-ba05d59bcefa	LOREAL	L'Oréal	Güzellik & Bakım	t
ce320bd9-083a-4074-8c76-a8d96f91a8ad	DELL	Dell	Dell Bilgisayar	t
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.categories (id, code, name, description, parent_id, is_restaurant, icon, is_active, created_at) FROM stdin;
792f6f9a-4ff0-4fe5-8869-c5a0affbe848	GENEL	Genel Ürünler	\N	\N	f	\N	t	2026-05-24 12:50:05.210334+03
71d8b280-f82e-40ce-acf9-30658b616bba	HIZMET	Hizmetler	\N	\N	f	\N	t	2026-05-24 12:50:05.210334+03
26c934eb-095e-46a0-b478-231600e95098	GIDA	Gıda	\N	\N	f	\N	t	2026-05-24 12:50:05.210334+03
b60c88a5-9b33-406b-bad0-1db889be8ce5	ICECEK	İçecek	\N	\N	f	\N	t	2026-05-24 12:50:05.210334+03
c0000001-0000-0000-0000-000000000001	ELEC	Elektronik	\N	\N	f	\N	t	2026-05-24 12:50:36.457566+03
c0000001-0000-0000-0000-000000000002	ELEC-PHONE	Telefonlar	\N	c0000001-0000-0000-0000-000000000001	f	\N	t	2026-05-24 12:50:36.457566+03
c0000001-0000-0000-0000-000000000003	ELEC-PC	Bilgisayarlar	\N	c0000001-0000-0000-0000-000000000001	f	\N	t	2026-05-24 12:50:36.457566+03
c0000001-0000-0000-0000-000000000004	FOOD	Gıda	\N	\N	f	\N	t	2026-05-24 12:50:36.457566+03
c0000001-0000-0000-0000-000000000005	FOOD-SNACK	Atıştırmalık	\N	c0000001-0000-0000-0000-000000000004	f	\N	t	2026-05-24 12:50:36.457566+03
c0000001-0000-0000-0000-000000000006	FOOD-DRINK	İçecekler	\N	c0000001-0000-0000-0000-000000000004	f	\N	t	2026-05-24 12:50:36.457566+03
c0000001-0000-0000-0000-000000000007	BEAUTY-CAT	Güzellik	\N	\N	f	\N	t	2026-05-24 12:50:36.457566+03
c0000001-0000-0000-0000-000000000008	CLOTH	Giyim	\N	\N	f	\N	t	2026-05-24 12:50:36.457566+03
c0000001-0000-0000-0000-000000000010	REST-ANA	Ana Yemekler	\N	\N	t	\N	t	2026-05-24 12:50:36.457566+03
c0000001-0000-0000-0000-000000000011	REST-ICECEK	İçecekler (Rest)	\N	\N	t	\N	t	2026-05-24 12:50:36.457566+03
c0000001-0000-0000-0000-000000000012	REST-TATLI	Tatlılar	\N	\N	t	\N	t	2026-05-24 12:50:36.457566+03
c0000001-0000-0000-0000-000000000013	REST-FAST	Fast Food	\N	\N	t	\N	t	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: currencies; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.currencies (id, code, name, symbol, is_base_currency, sort_order, is_active, created_at, updated_at) FROM stdin;
c2fc6a3e-7221-4743-94e6-bc2603810053	IQD	Iraqi Dinar	د.ع	t	1	t	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
61b47669-4cba-4676-aa26-b0c498b184db	USD	US Dollar	$	f	2	t	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
3b474456-a823-461f-acf2-49e2a305d387	EUR	Euro	€	f	3	t	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
88d71860-ca9f-418b-842b-38165d5d98ac	TRY	Turkish Lira	₺	f	4	t	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
18f0e611-49b5-4c16-a75f-48e0c027337d	SAR	Saudi Riyal	﷼	f	5	t	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
8bc7dc2b-63d8-41d3-8e3a-750a3334d395	AED	UAE Dirham	د.إ	f	6	t	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
83b08a6f-250b-4a43-9446-cfaca36e80c6	KWD	Kuwaiti Dinar	د.ك	f	7	t	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
9157f985-d869-4e5d-a5ba-fafefa9c99ee	GBP	British Pound	£	f	8	t	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
\.


--
-- Data for Name: exchange_rates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.exchange_rates (id, currency_code, date, buy_rate, sell_rate, effective_buy, effective_sell, source, is_active, created_at, updated_at) FROM stdin;
420d2f1a-a7f6-4447-a69d-59a54febd8bd	USD	2026-01-01	1308.00000000	1312.00000000	\N	\N	manual	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
332437da-2ed0-4cf3-921e-a8a7757a9560	USD	2026-01-15	1305.00000000	1309.00000000	\N	\N	manual	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
8c2fe09b-3d67-488c-b861-c0af92fc2512	USD	2026-02-01	1310.00000000	1314.00000000	\N	\N	manual	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
c50e2cea-5b09-48af-b6e9-0f128f9c5126	USD	2026-03-01	1312.00000000	1316.00000000	\N	\N	manual	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
a8c19f8a-2538-44a1-9219-507533315805	EUR	2026-01-01	1420.00000000	1426.00000000	\N	\N	manual	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
f987ae24-bc4a-4a48-af78-11e45bbd798e	EUR	2026-02-01	1418.00000000	1424.00000000	\N	\N	manual	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
174c6f23-b134-41b7-89c6-6154828d1b84	TRY	2026-01-01	37.50000000	38.20000000	\N	\N	manual	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
02800022-6b9f-436a-9b90-b75da7ab7d12	TRY	2026-02-01	37.80000000	38.50000000	\N	\N	manual	t	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: firms; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.firms (id, firm_nr, name, title, tax_nr, tax_office, address, city, country, email, phone, ana_para_birimi, raporlama_para_birimi, regulatory_region, gib_integration_mode, gib_ubl_profile, gib_sender_alias, gib_integrator_base_url, gib_integrator_username, gib_integrator_password, gib_use_test_environment, "default", is_active, created_at, supabase_firm_id) FROM stdin;
00000000-0000-4000-a000-000000000001	001	DESTERHAN RESTUARANT	DESTERHAN RESTUARANT			\N		\N	\N	\N	IQD	IQD	IQ	mock	TICARIFATURA	\N	\N	\N	\N	t	t	t	2026-05-24 12:50:05.210334+03	\N
\.


--
-- Data for Name: gib_edocument_queue; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.gib_edocument_queue (id, firm_nr, period_nr, source_type, source_id, document_no, doc_type, customer_name, doc_date, amount, tax_amount, status, gib_uuid, payload_json, xml_snapshot, gib_response_json, error_message, created_at, sent_at, updated_at) FROM stdin;
\.


--
-- Data for Name: menu_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.menu_items (id, menu_type, title, label, label_tr, label_en, label_ar, parent_id, section_id, screen_id, icon_name, badge, display_order, is_active, is_visible, created_at) FROM stdin;
\.


--
-- Data for Name: periods; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.periods (id, firm_id, nr, beg_date, end_date, is_active, "default") FROM stdin;
940f5229-ffc2-4914-a5b7-19e8fa4f7fa7	00000000-0000-4000-a000-000000000001	1	2026-01-01	2030-12-31	t	t
\.


--
-- Data for Name: product_exchange_rate_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.product_exchange_rate_history (id, product_id, old_rate, new_rate, changed_by, changed_at) FROM stdin;
\.


--
-- Data for Name: product_groups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.product_groups (id, code, name, description, is_active) FROM stdin;
44db29bd-3677-47e6-8bd5-6e50257df10d	ELECTRONIC	Elektronik	Elektronik cihazlar	t
afb6dce3-b3f4-45c6-b68b-26d10955db4f	FOOD	Gıda & İçecek	Tüm gıda ürünleri	t
5d55c20c-d911-4867-b0e6-b56d8d897408	BEAUTY	Güzellik & Bakım	Kişisel bakım ürünleri	t
c6ab2de3-b076-49d9-94e9-d2e8afa32562	TEXTILE	Tekstil	Giyim ve kumaş	t
fd0d32a4-4421-4d84-91eb-8a9597713582	CLEANING	Temizlik	Temizlik ürünleri	t
\.


--
-- Data for Name: report_templates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.report_templates (id, name, description, category, template_type, content, is_default, firm_nr, period_nr, created_by, created_at, updated_at) FROM stdin;
58bc7ee4-8099-4130-978b-624797c5e452	Modern Satış Faturası	Temiz ve modern fatura tasarımı	fatura	json	{"pageSize": {"width": 210, "height": 297}, "components": []}	t	\N	\N	\N	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
faeb209a-b7c5-4bbd-8b9b-3e23bbc7ffd0	Standart Ürün Etiketi (40x20mm)	Barkodlu raf etiketi	etiket	json	{"pageSize": {"width": 40, "height": 20}, "components": []}	t	\N	\N	\N	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
\.


--
-- Data for Name: rex_001_01_bank_lines; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_01_bank_lines (id, firm_nr, period_nr, register_id, fiche_no, date, amount, sign, trcode, definition, transaction_type, customer_id, cash_register_id, currency_code, exchange_rate, f_amount, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_cash_lines; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_01_cash_lines (id, firm_nr, period_nr, register_id, fiche_no, date, amount, sign, trcode, definition, transaction_type, customer_id, bank_id, bank_account_id, target_register_id, expense_card_id, currency_code, exchange_rate, f_amount, transfer_status, special_code, tax_rate, withholding_tax_rate, created_at) FROM stdin;
7b4c4b72-eaa9-4a01-b73c-91cbe3e832dc	001	01	\N	KAS-2026-0001	2026-01-05 11:00:00+03	54000.00	1	11	iPhone 15 Pro Satış Tahsilatı	sales_payment	\N	\N	\N	\N	\N	IQD	1.000000	0.00	0	\N	0.00	0.00	2026-05-24 12:50:36.457566+03
f5beec03-f4a6-4142-b48a-2e5275cf5eca	001	01	\N	KAS-2026-0002	2026-01-07 15:00:00+03	114000.00	1	11	MacBook Pro Satış Tahsilatı	sales_payment	\N	\N	\N	\N	\N	IQD	1.000000	0.00	0	\N	0.00	0.00	2026-05-24 12:50:36.457566+03
45564c38-3adb-4810-bd5c-af1ce492110c	001	01	\N	KAS-2026-0003	2026-01-10 10:00:00+03	30000.00	1	11	Telefon Satış Tahsilatı	sales_payment	\N	\N	\N	\N	\N	IQD	1.000000	0.00	0	\N	0.00	0.00	2026-05-24 12:50:36.457566+03
46077eb4-7ee1-4c10-8f5d-e1537795d57d	001	01	\N	KAS-2026-0004	2026-01-12 09:00:00+03	-8800.00	-1	12	Gıda Tedarik Ödemesi	purchase_payment	\N	\N	\N	\N	\N	IQD	1.000000	0.00	0	\N	0.00	0.00	2026-05-24 12:50:36.457566+03
f466f04f-195c-4744-afcc-fac01ad64997	001	01	\N	KAS-2026-0005	2026-01-15 09:30:00+03	-5000.00	-1	12	Kira Ödemesi — Ocak	expense	\N	\N	\N	\N	\N	IQD	1.000000	0.00	0	\N	0.00	0.00	2026-05-24 12:50:36.457566+03
2d8250fd-83d6-4fcf-9012-af9f1321d5e4	001	01	\N	KAS-2026-0006	2026-01-20 10:00:00+03	-2500.00	-1	12	Elektrik Faturası	expense	\N	\N	\N	\N	\N	IQD	1.000000	0.00	0	\N	0.00	0.00	2026-05-24 12:50:36.457566+03
db1a4278-60fe-4f41-9522-67d0eb0d45f0	001	01	\N	KAS-2026-0007	2026-02-01 09:00:00+03	45600.00	1	11	Samsung Galaxy Satış Tahsilatı	sales_payment	\N	\N	\N	\N	\N	IQD	1.000000	0.00	0	\N	0.00	0.00	2026-05-24 12:50:36.457566+03
fd6080aa-12d2-4167-a294-5cf94e3ba67f	001	01	\N	KAS-2026-0008	2026-02-05 14:00:00+03	390000.00	1	11	USD Fatura Tahsilatı (IQD)	sales_payment	\N	\N	\N	\N	\N	IQD	1.000000	0.00	0	\N	0.00	0.00	2026-05-24 12:50:36.457566+03
b10ac7c5-e715-49d9-928e-01a94539c493	001	01	00000000-0000-0000-0000-000000000001	REST-1-1779616320536	2026-05-24 00:00:00+03	50.00	1	\N	Market Satışı - REST-1-1779616320536	KASA_GIRIS	\N	\N	\N	\N	\N	YEREL	1.000000	0.00	0		0.00	0.00	2026-05-24 12:52:01.480696+03
635e7c35-f047-4c0c-854d-e1b174793bba	001	01	00000000-0000-0000-0000-000000000001	REST-1-1779629158255	2026-05-24 00:00:00+03	8580.00	1	\N	Market Satışı - REST-1-1779629158255	KASA_GIRIS	\N	\N	\N	\N	\N	YEREL	1.000000	0.00	0		0.00	0.00	2026-05-24 16:25:59.345127+03
\.


--
-- Data for Name: rex_001_01_sale_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_01_sale_items (id, invoice_id, firm_nr, period_nr, item_code, item_name, product_id, quantity, unit_price, vat_rate, discount_rate, discount_amount, total_amount, net_amount, unit_cost, total_cost, gross_profit, unit, unit_multiplier, base_quantity, unit_price_fc, currency) FROM stdin;
da71d242-6c9b-4a31-b135-ee5b95da3a4d	40a8cda1-7e72-4080-b12f-84109cb4915b	001	01	PHONE-001	iPhone 15 Pro	af831dbf-90ef-47e0-9e9a-d9d41470355e	1.000	45000.00	20.00	0.0000	0.00	54000.00	45000.00	0.00	0.00	0.00	Adet	1.000000	1.000	45000.0000	IQD
06c0f15e-f5db-492f-ba3a-2b0759d35e50	14fe0e2e-6bbc-41e9-b9b3-d1daee90591b	001	01	PC-001	MacBook Pro 16"	8cc29e25-143b-40ec-a37f-45c0a0291b92	1.000	95000.00	20.00	0.0000	0.00	114000.00	95000.00	0.00	0.00	0.00	Adet	1.000000	1.000	95000.0000	IQD
87d641e1-3152-49ae-9d12-03bd387a47f9	698366f8-30d9-4bed-a4d7-bc142d07a1ba	001	01	PHONE-003	Xiaomi 14 Pro	e357f3d5-44fe-4523-b614-3ac5098a3a39	1.000	25000.00	20.00	0.0000	0.00	30000.00	25000.00	0.00	0.00	0.00	Adet	1.000000	1.000	25000.0000	IQD
17327b79-95c9-4efc-b754-b4f4bb667523	9de41dd8-1b48-4bc0-906b-63e5347c4f80	001	01	SNACK-001	Çikolata Bar	3a28e755-8755-4c5a-88ee-283b4aaa6dd4	2.000	288.00	10.00	0.0000	0.00	633.60	576.00	0.00	0.00	0.00	KOLI	24.000000	48.000	288.0000	IQD
cd309bdc-7ee2-408e-acd2-412200c3d80f	8ca7d561-d8c1-4176-bf77-2bf1468f012c	001	01	PHONE-001	iPhone 15 Pro	af831dbf-90ef-47e0-9e9a-d9d41470355e	2.000	162500.00	20.00	0.0000	0.00	390000.00	325000.00	0.00	0.00	0.00	Adet	1.000000	2.000	250.0000	USD
8d40fcac-04e5-4978-b6c0-d5cf74cb4e9f	9e141119-822f-447c-a6e7-72a3f67362b9	001	01	80720be4-a213-4dc4-afd1-58d3d4ad6a07	Ayran	\N	1.000	25.00	0.00	0.0000	0.00	25.00	25.00	0.00	0.00	25.00	Adet	1.000000	1.000	25.0000	IQD
4e6e8b59-1f3e-44af-9078-e999a1db0e90	9e141119-822f-447c-a6e7-72a3f67362b9	001	01	f483a7c5-d84f-4ca3-b7ae-e2363c887ae2	Bisküvi Paketi	\N	1.000	25.00	0.00	0.0000	0.00	25.00	25.00	0.00	0.00	25.00	Adet	1.000000	1.000	25.0000	IQD
ad244575-e19c-4843-8785-f7463d783d2e	72989e74-0d4c-4719-9f26-f354232eb5ad	001	01	3162b084-ea83-41c4-8c67-e1f5263dd740	Hamburger Menü	\N	1.000	180.00	0.00	0.0000	0.00	180.00	180.00	0.00	0.00	180.00	Adet	1.000000	1.000	180.0000	IQD
76654895-1e63-428c-a347-227b02b98c69	72989e74-0d4c-4719-9f26-f354232eb5ad	001	01	9a8f7096-e89c-43c4-9d50-c8b40fcc043a	Erkek Pantolon	\N	1.000	650.00	0.00	0.0000	0.00	650.00	650.00	0.00	0.00	650.00	Adet	1.000000	1.000	650.0000	IQD
802401b4-6077-4c64-ac80-aac698a5f821	72989e74-0d4c-4719-9f26-f354232eb5ad	001	01	102e4899-2368-4831-88ff-519515314eb1	KARIŞIK SALATA (DOMATES SALATALIK)	\N	1.000	3750.00	0.00	0.0000	0.00	3750.00	3750.00	0.00	0.00	3750.00	Adet	1.000000	1.000	3750.0000	IQD
f62a0976-4132-4636-8d8c-69786e8867bb	72989e74-0d4c-4719-9f26-f354232eb5ad	001	01	a012f83b-d3f3-4435-8f40-46f9ea7541a7	KAHVE	\N	1.000	0.00	0.00	0.0000	0.00	0.00	0.00	0.00	0.00	0.00	Adet	1.000000	1.000	0.0000	IQD
378d2534-569d-48ba-9bb6-1cf32e9cf807	72989e74-0d4c-4719-9f26-f354232eb5ad	001	01	2db1e771-61d8-46af-a6b9-5b23fe9a0ea5	7UP TENEKE	\N	1.000	2500.00	0.00	0.0000	0.00	2500.00	2500.00	0.00	0.00	2500.00	Adet	1.000000	1.000	2500.0000	IQD
122b95f1-89be-46aa-b457-db410e59d8c9	72989e74-0d4c-4719-9f26-f354232eb5ad	001	01	0230b49e-da04-4c01-8376-dcf39efcc266	AYRAN BARDAK	\N	1.000	1500.00	0.00	0.0000	0.00	1500.00	1500.00	0.00	0.00	1500.00	Adet	1.000000	1.000	1500.0000	IQD
de975a3f-b17b-4379-86c8-26d5fe3b7f34	72989e74-0d4c-4719-9f26-f354232eb5ad	001	01	6d2ba86e-cd03-436b-863d-791de70a281f	ÇAY	\N	1.000	0.00	0.00	0.0000	0.00	0.00	0.00	0.00	0.00	0.00	Adet	1.000000	1.000	0.0000	IQD
\.


--
-- Data for Name: rex_001_01_sales; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_01_sales (id, firm_nr, period_nr, fiche_no, document_no, trcode, fiche_type, date, customer_id, customer_name, store_id, total_net, total_vat, total_gross, total_discount, net_amount, total_cost, gross_profit, profit_margin, currency, currency_rate, status, logo_sync_status, payment_method, cashier, is_cancelled, credit_amount, notes, created_at, updated_at) FROM stdin;
40a8cda1-7e72-4080-b12f-84109cb4915b	001	01	SAT-2026-0001	\N	\N	S	2026-01-05 10:30:00+03	6134d937-b8ed-404f-806c-16e851c71de3	\N	\N	45000.00	9000.00	54000.00	0.00	0.00	0.00	0.00	0.00	IQD	1.000000	completed	pending	cash	\N	f	0.00	\N	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
14fe0e2e-6bbc-41e9-b9b3-d1daee90591b	001	01	SAT-2026-0002	\N	\N	S	2026-01-07 14:15:00+03	c62753d1-0015-43b9-995a-84c663daa020	\N	\N	95000.00	19000.00	114000.00	0.00	0.00	0.00	0.00	0.00	IQD	1.000000	completed	pending	credit	\N	f	0.00	\N	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
698366f8-30d9-4bed-a4d7-bc142d07a1ba	001	01	SAT-2026-0003	\N	\N	S	2026-01-10 09:20:00+03	4539a45d-229b-403a-bb72-8676047cf222	\N	\N	25000.00	5000.00	30000.00	0.00	0.00	0.00	0.00	0.00	IQD	1.000000	completed	pending	cash	\N	f	0.00	\N	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
9de41dd8-1b48-4bc0-906b-63e5347c4f80	001	01	SAT-2026-0004	\N	\N	S	2026-01-12 16:00:00+03	8b69acbf-75a8-4c07-98ea-1abd9dffbdff	\N	\N	1500.00	150.00	1650.00	0.00	0.00	0.00	0.00	0.00	IQD	1.000000	completed	pending	cash	\N	f	0.00	\N	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
bce41a6f-5ba4-4d9c-a168-9d6770ac0534	001	01	SAT-2026-0005	\N	\N	S	2026-01-15 11:45:00+03	3dee3608-a4b1-4b27-b569-e94f56dcb6ad	\N	\N	38000.00	7600.00	45600.00	0.00	0.00	0.00	0.00	0.00	IQD	1.000000	completed	pending	credit	\N	f	0.00	\N	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
8ca7d561-d8c1-4176-bf77-2bf1468f012c	001	01	SAT-2026-0006	\N	\N	S	2026-01-18 13:30:00+03	93198df4-6949-48d0-b29b-34eeb8bb0931	\N	\N	250.00	50.00	300.00	0.00	0.00	0.00	0.00	0.00	USD	1300.000000	completed	pending	cash	\N	f	0.00	\N	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
84f7c61b-562c-4b4f-b804-a85db9af44e8	001	01	ALI-2026-0001	\N	\N	A	2026-01-03 09:00:00+03	0811050d-d8a2-487a-a2b4-c9aea21d656d	\N	\N	120000.00	24000.00	144000.00	0.00	0.00	0.00	0.00	0.00	IQD	1.000000	completed	pending	credit	\N	f	0.00	Telefon stoğu alımı	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
184909b0-b2d4-4eea-8b22-40d624e797bc	001	01	ALI-2026-0002	\N	\N	A	2026-01-06 11:00:00+03	104a593e-9ea7-4f47-a587-aad1268958f6	\N	\N	8000.00	800.00	8800.00	0.00	0.00	0.00	0.00	0.00	IQD	1.000000	completed	pending	cash	\N	f	0.00	Atıştırmalık stoğu	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
dde6a074-6a49-4f7a-b8f2-b2044f2e6c58	001	01	ALI-2026-0003	\N	\N	A	2026-01-08 10:30:00+03	1481acd1-b545-4d76-ba3d-efde68b3c959	\N	\N	4000.00	400.00	4400.00	0.00	0.00	0.00	0.00	0.00	USD	1300.000000	completed	pending	credit	\N	f	0.00	İçecek stoğu USD	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
9e141119-822f-447c-a6e7-72a3f67362b9	001	01	REST-1-1779616320536	REST-1-1779616320536	7	sales_invoice	2026-05-24 12:52:01.198+03	\N	Peşin Müşteri	\N	50.00	0.00	0.00	0.00	50.00	0.00	50.00	100.00	IQD	1.000000	approved	pending	cash	admin	f	0.00	RestoranPOS|rest_order_id:44e147d8-1025-4599-8266-b2935b22af64	2026-05-24 12:52:01.215573+03	2026-05-24 12:52:01.215573+03
72989e74-0d4c-4719-9f26-f354232eb5ad	001	01	REST-1-1779629158255	REST-1-1779629158255	7	sales_invoice	2026-05-24 16:25:58.805+03	\N	Peşin Müşteri	\N	8580.00	0.00	0.00	0.00	8580.00	0.00	8580.00	100.00	IQD	1.000000	approved	pending	cash	admin	f	0.00	RestoranPOS|rest_order_id:01dec24f-ad0b-475d-98ea-42788f9e6727	2026-05-24 16:25:58.813159+03	2026-05-24 16:25:58.813159+03
\.


--
-- Data for Name: rex_001_01_stock_movement_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_01_stock_movement_items (id, movement_id, product_id, quantity, unit_price, cost_price, exchange_rate, unit_name, convert_factor, notes, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_stock_movements; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_01_stock_movements (id, firm_nr, period_nr, document_no, trcode, movement_type, warehouse_id, target_warehouse_id, movement_date, exchange_rate, description, status, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_virman_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_01_virman_items (id, virman_id, product_id, quantity, notes, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_virman_operations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_01_virman_operations (id, firm_nr, period_nr, virman_no, from_warehouse_id, to_warehouse_id, operation_date, status, notes, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rex_001_bank_registers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_bank_registers (id, firm_nr, code, name, bank_name, iban, currency_code, balance, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rex_001_brands; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_brands (id, code, name, description, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_campaigns; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_campaigns (id, firm_nr, name, description, type, discount_type, discount_value, start_date, end_date, is_active, min_purchase_amount, max_discount_amount, applicable_categories, applicable_products, priority, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rex_001_cash_registers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_cash_registers (id, firm_nr, code, name, currency_code, balance, is_active, created_at, updated_at) FROM stdin;
00000000-0000-0000-0000-000000000001	001	KASA.001	MERKEZ KASA	IQD	8630.00	t	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
\.


--
-- Data for Name: rex_001_categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_categories (id, code, name, description, parent_id, is_restaurant, icon, is_active, created_at) FROM stdin;
9bf0d905-7740-42bd-b875-60215cfd6eda	ELEC	Elektronik	\N	\N	f	\N	t	2026-05-24 12:50:36.457566+03
1eb458d5-8307-444c-85fe-b4da7898a934	ELEC-PHONE	Telefonlar	\N	\N	f	\N	t	2026-05-24 12:50:36.457566+03
ee4d6cda-6564-422d-b551-a85fd40db97f	ELEC-PC	Bilgisayarlar	\N	\N	f	\N	t	2026-05-24 12:50:36.457566+03
c12f15f6-2583-4f54-8d54-886c43485983	FOOD	Gıda	\N	\N	f	\N	t	2026-05-24 12:50:36.457566+03
432eaefc-f2ef-4df3-abd7-c6d50d646813	FOOD-SNACK	Atıştırmalık	\N	\N	f	\N	t	2026-05-24 12:50:36.457566+03
7bb67d97-2dbd-4301-9b86-e0373026e436	FOOD-DRINK	İçecekler	\N	\N	f	\N	t	2026-05-24 12:50:36.457566+03
7cdc0ede-2c44-4ba6-bfb1-ecfea07406cc	BEAUTY-P	Güzellik Ürünleri	\N	\N	f	\N	t	2026-05-24 12:50:36.457566+03
f7eb8335-f881-4bdc-9d84-97df0ab20aec	CLOTH	Giyim	\N	\N	f	\N	t	2026-05-24 12:50:36.457566+03
5b385721-22fc-4f66-8453-a5739c16975f	REST-ANA	Ana Yemekler	\N	\N	t	\N	t	2026-05-24 12:50:36.457566+03
a4c099bc-7e84-4970-a6aa-1e696ec50b07	REST-ICECEK	İçecekler	\N	\N	t	\N	t	2026-05-24 12:50:36.457566+03
907976d3-cec5-49da-b715-c19250d618f3	REST-TATLI	Tatlılar	\N	\N	t	\N	t	2026-05-24 12:50:36.457566+03
a709336b-b4bb-4b5d-bd7f-c77e79f62423	ATIŞTIRMALIK	ATIŞTIRMALIK		\N	f	\N	t	2026-05-24 14:54:24.126078+03
c3f2b98a-d6d3-4e2e-98fb-a47ff487c674	ÇORBALAR	ÇORBALAR		\N	f	\N	t	2026-05-24 14:54:24.147571+03
c12dbd8c-34a0-4dbd-8c8c-a3ae3473d505	TATLILAR	TATLILAR		\N	f	\N	t	2026-05-24 14:54:24.160708+03
fda65768-47c0-46c2-b513-f9ac226eff7e	SALATALAR	SALATALAR		\N	f	\N	t	2026-05-24 14:54:24.171843+03
\.


--
-- Data for Name: rex_001_customers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_customers (id, firm_nr, code, name, phone, phone2, age, file_id, occupation, gender, customer_tier, heard_from, email, tax_nr, taxi_nr, tax_office, address, city, neighborhood, district, balance, points, total_spent, notes, is_active, created_at) FROM stdin;
6134d937-b8ed-404f-806c-16e851c71de3	001	CUST-001	Ahmed Al-Rashidi	+964 770 100 0001	\N	\N	\N	\N	\N	normal	\N	ahmed@mail.com	9001001001	\N	\N	Kerkük Cad. No:12	Bağdat	\N	\N	0.00	0.00	0.00	\N	t	2026-05-24 12:50:36.457566+03
4539a45d-229b-403a-bb72-8676047cf222	001	CUST-002	Sara Mahmoud	+964 770 100 0002	\N	\N	\N	\N	\N	normal	\N	sara@mail.com	9002002002	\N	\N	Havalar Mh. No:45	Erbil	\N	\N	0.00	0.00	0.00	\N	t	2026-05-24 12:50:36.457566+03
3dee3608-a4b1-4b27-b569-e94f56dcb6ad	001	CUST-003	Karim Hassan	+964 770 100 0003	\N	\N	\N	\N	\N	normal	\N	karim@mail.com	9003003003	\N	\N	Salahaddin Blv. No:78	Süleymaniye	\N	\N	0.00	0.00	0.00	\N	t	2026-05-24 12:50:36.457566+03
44c4f595-0989-45f8-8951-3f586eb4a9a8	001	CUST-004	Lara Aziz	+964 770 100 0004	\N	\N	\N	\N	\N	normal	\N	lara@mail.com	9004004004	\N	\N	Yarmouk Mh. No:23	Musul	\N	\N	0.00	0.00	0.00	\N	t	2026-05-24 12:50:36.457566+03
08aece31-ba6e-4dee-a8c8-fc8ec0438378	001	CUST-005	Omar Khalil	+964 770 100 0005	\N	\N	\N	\N	\N	normal	\N	omar@mail.com	9005005005	\N	\N	Corniche Cad. No:5	Basra	\N	\N	0.00	0.00	0.00	\N	t	2026-05-24 12:50:36.457566+03
c62753d1-0015-43b9-995a-84c663daa020	001	CORP-001	Al-Noor Teknoloji	+964 770 200 0001	\N	\N	\N	\N	\N	normal	\N	info@alnoor.iq	8001001001	\N	\N	Mansour Mh. No:100	Bağdat	\N	\N	0.00	0.00	0.00	\N	t	2026-05-24 12:50:36.457566+03
8b69acbf-75a8-4c07-98ea-1abd9dffbdff	001	CORP-002	Kurdistan Market	+964 750 200 0002	\N	\N	\N	\N	\N	normal	\N	info@kurdmkt.iq	8002002002	\N	\N	Ankawa Cad. No:55	Erbil	\N	\N	0.00	0.00	0.00	\N	t	2026-05-24 12:50:36.457566+03
93198df4-6949-48d0-b29b-34eeb8bb0931	001	CORP-003	Basra Trade Co.	+964 780 200 0003	\N	\N	\N	\N	\N	normal	\N	info@basratrade.iq	8003003003	\N	\N	Port Mh. No:7	Basra	\N	\N	0.00	0.00	0.00	\N	t	2026-05-24 12:50:36.457566+03
2dc07a6f-0f2b-420b-8837-5a7e65acdba7	001	BCust-001	Lena Al-Rashidi	+964 770 400 0001	\N	\N	\N	\N	\N	normal	\N	lena@mail.com	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	\N	t	2026-05-24 12:50:36.457566+03
a273f014-47b6-4a4a-82f4-e38bb02b7353	001	BCust-002	Maya Hassan	+964 770 400 0002	\N	\N	\N	\N	\N	normal	\N	maya@mail.com	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	\N	t	2026-05-24 12:50:36.457566+03
d00bc030-5e82-4004-91fc-134ee5da1c1c	001	BCust-003	Sara Karim	+964 770 400 0003	\N	\N	\N	\N	\N	normal	\N	sara.k@mail.com	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	\N	t	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: rex_001_expense_cards; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_expense_cards (id, firm_nr, code, name, description, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rex_001_product_barcodes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_product_barcodes (id, product_id, barcode_code, unit, sale_price, is_primary, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_product_unit_conversions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_product_unit_conversions (id, product_id, from_unit, to_unit, factor, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_product_variants; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_product_variants (id, product_id, sku, attributes) FROM stdin;
2a9caf59-366c-4657-866a-46dc049d6bd0	3e22d00f-cdc8-4a35-b524-38f4f5987eae	TSHIRT-VAR-S-Beyaz	{"cost": 140.00, "size": "S", "color": "Beyaz", "price": 250.00, "stock": 10, "barcode": "", "is_active": true, "variant_name": "S Beyaz"}
cd57dc01-9e17-444c-b465-57801d27ccf3	3e22d00f-cdc8-4a35-b524-38f4f5987eae	TSHIRT-VAR-S-Siyah	{"cost": 140.00, "size": "S", "color": "Siyah", "price": 250.00, "stock": 10, "barcode": "", "is_active": true, "variant_name": "S Siyah"}
b4e89420-95ea-4ac6-b0ea-f14e6b7b9180	3e22d00f-cdc8-4a35-b524-38f4f5987eae	TSHIRT-VAR-S-Lacivert	{"cost": 140.00, "size": "S", "color": "Lacivert", "price": 250.00, "stock": 10, "barcode": "", "is_active": true, "variant_name": "S Lacivert"}
dead6e34-df21-4e3f-9ef1-ae3d8206c4f4	3e22d00f-cdc8-4a35-b524-38f4f5987eae	TSHIRT-VAR-M-Beyaz	{"cost": 140.00, "size": "M", "color": "Beyaz", "price": 250.00, "stock": 20, "barcode": "", "is_active": true, "variant_name": "M Beyaz"}
7eb82ef7-9b06-46e9-b5f6-8e12b9d0fb80	3e22d00f-cdc8-4a35-b524-38f4f5987eae	TSHIRT-VAR-M-Siyah	{"cost": 140.00, "size": "M", "color": "Siyah", "price": 250.00, "stock": 20, "barcode": "", "is_active": true, "variant_name": "M Siyah"}
3c413a93-afc2-4e16-89bd-800286614d48	3e22d00f-cdc8-4a35-b524-38f4f5987eae	TSHIRT-VAR-M-Lacivert	{"cost": 140.00, "size": "M", "color": "Lacivert", "price": 250.00, "stock": 20, "barcode": "", "is_active": true, "variant_name": "M Lacivert"}
c3f9c2b8-691d-466d-815d-996d038a13d9	3e22d00f-cdc8-4a35-b524-38f4f5987eae	TSHIRT-VAR-L-Beyaz	{"cost": 140.00, "size": "L", "color": "Beyaz", "price": 250.00, "stock": 20, "barcode": "", "is_active": true, "variant_name": "L Beyaz"}
937ba36a-74be-45b6-a68e-94a38a9cb11a	3e22d00f-cdc8-4a35-b524-38f4f5987eae	TSHIRT-VAR-L-Siyah	{"cost": 140.00, "size": "L", "color": "Siyah", "price": 250.00, "stock": 20, "barcode": "", "is_active": true, "variant_name": "L Siyah"}
a51c92f6-9010-4a8c-80d7-bc0664fdb29a	3e22d00f-cdc8-4a35-b524-38f4f5987eae	TSHIRT-VAR-L-Lacivert	{"cost": 140.00, "size": "L", "color": "Lacivert", "price": 250.00, "stock": 20, "barcode": "", "is_active": true, "variant_name": "L Lacivert"}
cabb20b6-ca7a-4e89-b2d9-4928633c5e3d	3e22d00f-cdc8-4a35-b524-38f4f5987eae	TSHIRT-VAR-XL-Beyaz	{"cost": 140.00, "size": "XL", "color": "Beyaz", "price": 250.00, "stock": 10, "barcode": "", "is_active": true, "variant_name": "XL Beyaz"}
fd4ff478-22c5-499b-ba2e-f977f98c39ab	3e22d00f-cdc8-4a35-b524-38f4f5987eae	TSHIRT-VAR-XL-Siyah	{"cost": 140.00, "size": "XL", "color": "Siyah", "price": 250.00, "stock": 10, "barcode": "", "is_active": true, "variant_name": "XL Siyah"}
f3fcf177-7022-455e-8e9d-70b979950f16	3e22d00f-cdc8-4a35-b524-38f4f5987eae	TSHIRT-VAR-XL-Lacivert	{"cost": 140.00, "size": "XL", "color": "Lacivert", "price": 250.00, "stock": 10, "barcode": "", "is_active": true, "variant_name": "XL Lacivert"}
9a3d5618-7f43-45f7-a471-ae2ed9182c86	5440758d-a1f4-4555-bd13-eeade9dfb89c	PHONE-VAR-Siyah-128GB	{"cost": 13500.00, "size": "128GB", "color": "Siyah", "price": 18000.00, "stock": 8, "barcode": "", "is_active": true, "variant_name": "128GB Siyah"}
a1f81dab-b6f5-4857-a7cb-1106259b8ad5	5440758d-a1f4-4555-bd13-eeade9dfb89c	PHONE-VAR-Siyah-256GB	{"cost": 15800.00, "size": "256GB", "color": "Siyah", "price": 21000.00, "stock": 8, "barcode": "", "is_active": true, "variant_name": "256GB Siyah"}
a7b7a73d-0efd-4ce2-ae9c-810abdedeb4f	5440758d-a1f4-4555-bd13-eeade9dfb89c	PHONE-VAR-Siyah-512GB	{"cost": 19500.00, "size": "512GB", "color": "Siyah", "price": 26000.00, "stock": 8, "barcode": "", "is_active": true, "variant_name": "512GB Siyah"}
4ce2f543-8a6b-491c-995d-02a7735277f8	5440758d-a1f4-4555-bd13-eeade9dfb89c	PHONE-VAR-Beyaz-128GB	{"cost": 13500.00, "size": "128GB", "color": "Beyaz", "price": 18000.00, "stock": 8, "barcode": "", "is_active": true, "variant_name": "128GB Beyaz"}
69a49734-6fe3-4728-9dc3-67f73838c032	5440758d-a1f4-4555-bd13-eeade9dfb89c	PHONE-VAR-Beyaz-256GB	{"cost": 15800.00, "size": "256GB", "color": "Beyaz", "price": 21000.00, "stock": 8, "barcode": "", "is_active": true, "variant_name": "256GB Beyaz"}
3baa2212-01e6-4ca6-909e-8b32e404db74	5440758d-a1f4-4555-bd13-eeade9dfb89c	PHONE-VAR-Beyaz-512GB	{"cost": 19500.00, "size": "512GB", "color": "Beyaz", "price": 26000.00, "stock": 8, "barcode": "", "is_active": true, "variant_name": "512GB Beyaz"}
95328cbc-70fe-449e-a895-6e00361902a1	5440758d-a1f4-4555-bd13-eeade9dfb89c	PHONE-VAR-Gümüş-128GB	{"cost": 13500.00, "size": "128GB", "color": "Gümüş", "price": 18000.00, "stock": 8, "barcode": "", "is_active": true, "variant_name": "128GB Gümüş"}
7ade9583-6c95-45f9-b7b2-e51ec5177078	5440758d-a1f4-4555-bd13-eeade9dfb89c	PHONE-VAR-Gümüş-256GB	{"cost": 15800.00, "size": "256GB", "color": "Gümüş", "price": 21000.00, "stock": 8, "barcode": "", "is_active": true, "variant_name": "256GB Gümüş"}
f25e9123-d20b-4969-8129-8fde7bee4841	5440758d-a1f4-4555-bd13-eeade9dfb89c	PHONE-VAR-Gümüş-512GB	{"cost": 19500.00, "size": "512GB", "color": "Gümüş", "price": 26000.00, "stock": 8, "barcode": "", "is_active": true, "variant_name": "512GB Gümüş"}
\.


--
-- Data for Name: rex_001_products; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_products (id, firm_nr, ref_id, code, barcode, name, name2, image_url, image_url_cdn, description, description_tr, description_en, description_ar, description_ku, category_id, category_code, categorycode, "categoryCode", group_code, groupcode, "groupCode", sub_group_code, subgroupcode, "subGroupCode", brand, model, manufacturer, supplier, origin, material_type, materialtype, "materialType", unit, unit2, unit3, unit_id, unitset_id, unitsetid, "unitsetId", vat_rate, vatrate, "vatRate", tax_type, withholding_rate, currency, price, cost, stock, min_stock, max_stock, critical_stock, tracking_type, shelf_location, warehouse_code, special_code_1, special_code_2, special_code_3, special_code_4, special_code_5, special_code_6, specialcode1, specialcode2, specialcode3, specialcode4, specialcode5, specialcode6, price_list_1, price_list_2, price_list_3, price_list_4, price_list_5, price_list_6, pricelist1, pricelist2, pricelist3, pricelist4, pricelist5, pricelist6, purchase_price, purchase_price_usd, purchase_price_eur, sale_price_usd, sale_price_eur, custom_exchange_rate, auto_calculate_usd, preparation_time, follow_up_reminder_days, has_variants, hasvariants, "hasVariants", is_active, created_at, updated_at) FROM stdin;
07138e50-60dd-4669-a979-8816864f6f12	001	\N	DRINK-001	8680000000030	Kola 500ml	Şişe	\N	\N	\N	\N	\N	\N	\N	7bb67d97-2dbd-4301-9b86-e0373026e436	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Adet	\N	\N	\N	52d0858a-01fd-4b65-800a-2b65b9b60a57	\N	\N	10.00	20.00	20.00	\N	\N	IQD	8.50	5.50	600.00	100.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
cbde588d-e929-4924-9943-734518ea0dd0	001	\N	MENU-003	\N	Mercimek Çorbası	Kase	\N	\N	\N	\N	\N	\N	\N	5b385721-22fc-4f66-8453-a5739c16975f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Porsiyon	\N	\N	\N	\N	\N	\N	10.00	20.00	20.00	\N	\N	IQD	80.00	20.00	999.00	1.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
9c615850-4150-4b1e-92bb-05b374408c47	001	\N	BEAUTY-002	8680000000041	Saç Bakım Kremi	250ml	\N	\N	\N	\N	\N	\N	\N	7cdc0ede-2c44-4ba6-bfb1-ecfea07406cc	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Adet	\N	\N	\N	\N	\N	\N	10.00	20.00	20.00	\N	\N	IQD	95.00	60.00	180.00	20.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
a60b4e43-28a1-4cc1-9267-f6d682cdbf34	001	\N	BEAUTY-001	8680000000040	Şampuan 400ml	Bakım Serisi	\N	\N	\N	\N	\N	\N	\N	7cdc0ede-2c44-4ba6-bfb1-ecfea07406cc	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Adet	\N	\N	\N	\N	\N	\N	10.00	20.00	20.00	\N	\N	IQD	120.00	75.00	200.00	20.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
b3932d01-23c2-433b-bd6e-d24bb8073dfd	001	\N	PHONE-002	8680000000002	Samsung Galaxy S24	512GB Siyah	\N	\N	\N	\N	\N	\N	\N	1eb458d5-8307-444c-85fe-b4da7898a934	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Adet	\N	\N	\N	\N	\N	\N	20.00	20.00	20.00	\N	\N	IQD	38000.00	29000.00	22.00	3.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
31a9ff19-31e3-49f8-a2f2-9381644cfc62	001	\N	DRINK-002	8680000000031	Su 1.5L	Büyük Şişe	\N	\N	\N	\N	\N	\N	\N	7bb67d97-2dbd-4301-9b86-e0373026e436	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Adet	\N	\N	\N	52d0858a-01fd-4b65-800a-2b65b9b60a57	\N	\N	10.00	20.00	20.00	\N	\N	IQD	4.00	2.50	800.00	100.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
11ba96b7-b0f5-4aa5-8a28-494079223b1b	001	\N	MENU-006	\N	Sütlaç	Fırın	\N	\N	\N	\N	\N	\N	\N	907976d3-cec5-49da-b715-c19250d618f3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Porsiyon	\N	\N	\N	\N	\N	\N	10.00	20.00	20.00	\N	\N	IQD	85.00	25.00	999.00	1.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
80720be4-a213-4dc4-afd1-58d3d4ad6a07	001	\N	MENU-005	\N	Ayran	300ml	\N	\N	\N	\N	\N	\N	\N	a4c099bc-7e84-4970-a6aa-1e696ec50b07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Bardak	\N	\N	\N	\N	\N	\N	10.00	20.00	20.00	\N	\N	IQD	25.00	6.00	998.00	1.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
f483a7c5-d84f-4ca3-b7ae-e2363c887ae2	001	\N	SNACK-003	8680000000022	Bisküvi Paketi	Çikolatalı 200g	\N	\N	\N	\N	\N	\N	\N	432eaefc-f2ef-4df3-abd7-c6d50d646813	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Adet	\N	\N	\N	52d0858a-01fd-4b65-800a-2b65b9b60a57	\N	\N	10.00	20.00	20.00	\N	\N	IQD	25.00	17.00	279.00	30.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
e9af8bb5-8242-462c-b87c-0e4a57f0fc6b	001	\N	MENU-004	\N	Çay	Demlik	\N	\N	\N	\N	\N	\N	\N	a4c099bc-7e84-4970-a6aa-1e696ec50b07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Bardak	\N	\N	\N	\N	\N	\N	0.00	20.00	20.00	\N	\N	IQD	20.00	4.00	999.00	1.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
6aa4a637-9b1c-4ffb-a2af-0387cf2ef110	001	\N	SNACK-002	8680000000021	Cips	Klasik Tuzlu 150g	\N	\N	\N	\N	\N	\N	\N	432eaefc-f2ef-4df3-abd7-c6d50d646813	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Adet	\N	\N	\N	52d0858a-01fd-4b65-800a-2b65b9b60a57	\N	\N	10.00	20.00	20.00	\N	\N	IQD	12.50	8.00	350.00	50.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
d1ee26fe-19e1-4b87-8059-bbda4697648c	001	\N	PC-002	8680000000011	Dell XPS 15	i9 32GB RTX4060	\N	\N	\N	\N	\N	\N	\N	ee4d6cda-6564-422d-b551-a85fd40db97f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Adet	\N	\N	\N	\N	\N	\N	20.00	20.00	20.00	\N	\N	IQD	55000.00	43000.00	12.00	2.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
a0fb4938-b6db-41a5-bd8d-e7f5a2fed940	001	\N	CLOTH-001	8680000000050	Erkek Gömlek	Beyaz Klasik	\N	\N	\N	\N	\N	\N	\N	f7eb8335-f881-4bdc-9d84-97df0ab20aec	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Adet	\N	\N	\N	e3e502ca-61d7-4885-8776-6a90d8b7b2b2	\N	\N	10.00	20.00	20.00	\N	\N	IQD	450.00	280.00	45.00	10.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
548baacc-2176-4a2f-b567-dd9e9cc72c42	001	\N	MENU-001	\N	Izgara Köfte	200g, Salata ile	\N	\N	\N	\N	\N	\N	\N	5b385721-22fc-4f66-8453-a5739c16975f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Porsiyon	\N	\N	\N	\N	\N	\N	10.00	20.00	20.00	\N	\N	IQD	250.00	80.00	999.00	1.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
b5fc427f-7e17-43c7-b18c-972009e4a080	001	\N	CLOTH-003	8680000000052	Kadın Bluz	Pembe Şifon	\N	\N	\N	\N	\N	\N	\N	f7eb8335-f881-4bdc-9d84-97df0ab20aec	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Adet	\N	\N	\N	e3e502ca-61d7-4885-8776-6a90d8b7b2b2	\N	\N	10.00	20.00	20.00	\N	\N	IQD	380.00	230.00	52.00	10.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
bef201e4-a721-4b6b-9c82-87b37d5b2c73	001	\N	MENU-002	\N	Tavuk Şiş	3'lü, Pilav ile	\N	\N	\N	\N	\N	\N	\N	5b385721-22fc-4f66-8453-a5739c16975f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Porsiyon	\N	\N	\N	\N	\N	\N	10.00	20.00	20.00	\N	\N	IQD	220.00	65.00	999.00	1.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
3162b084-ea83-41c4-8c67-e1f5263dd740	001	\N	MENU-007	\N	Hamburger Menü	Patates + İçecek	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Porsiyon	\N	\N	\N	\N	\N	\N	10.00	20.00	20.00	\N	\N	IQD	180.00	55.00	998.00	1.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
9a8f7096-e89c-43c4-9d50-c8b40fcc043a	001	\N	CLOTH-002	8680000000051	Erkek Pantolon	Lacivert Kumaş	\N	\N	\N	\N	\N	\N	\N	f7eb8335-f881-4bdc-9d84-97df0ab20aec	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Adet	\N	\N	\N	e3e502ca-61d7-4885-8776-6a90d8b7b2b2	\N	\N	10.00	20.00	20.00	\N	\N	IQD	650.00	400.00	37.00	10.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
1ea8c2df-9ea0-42f0-8ab1-5c800a21e9d4	001	\N	10013	10013	ÖZBEK BAKLAVA	\N								\N	TATLILAR	\N	\N	GRP-04	\N	\N		\N	\N						commercial_goods	\N	\N	PRS			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	9000.00	4500.00	0.00	20.00	100.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:25.01531+03	2026-05-24 14:54:25.01531+03
43ae2ed7-6083-4630-9894-a559765c923b	001	\N	10014	10014	HAVUÇ SALATASI	\N								\N	SALATALAR	\N	\N	GRP-05	\N	\N		\N	\N						commercial_goods	\N	\N	PRS			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	3000.00	1200.00	0.00	10.00	10.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:25.068949+03	2026-05-24 14:54:25.068949+03
a750fb1a-1859-4d7b-a5f6-4320a139c289	001	\N	10015	10015	DOMATES SALATASI )DOMATES SOĞAN MAYDANOZ)	\N								\N	SALATALAR	\N	\N	GRP-05	\N	\N		\N	\N						commercial_goods	\N	\N	PRS			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	3750.00	1500.00	0.00	10.00	10.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:25.119078+03	2026-05-24 14:54:25.119078+03
928c2ae5-39d1-4d78-8451-1ce406e6465a	001	\N	10016	10016	LAHANA SALATASI	\N								\N	SALATALAR	\N	\N	GRP-05	\N	\N		\N	\N						commercial_goods	\N	\N	PRS			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	3500.00	1250.00	0.00	10.00	10.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:25.163583+03	2026-05-24 14:54:25.163583+03
5440758d-a1f4-4555-bd13-eeade9dfb89c	001	\N	PHONE-VAR	\N	Akıllı Telefon X12	Çift SIM 5G	\N	\N	\N	\N	\N	\N	\N	1eb458d5-8307-444c-85fe-b4da7898a934	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Adet	\N	\N	\N	e3e502ca-61d7-4885-8776-6a90d8b7b2b2	\N	\N	20.00	20.00	20.00	\N	\N	IQD	18000.00	13500.00	0.00	2.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	t	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
3a28e755-8755-4c5a-88ee-283b4aaa6dd4	001	\N	SNACK-001	8680000000020	Çikolata Bar	Sütlü 80g	\N	\N	\N	\N	\N	\N	\N	432eaefc-f2ef-4df3-abd7-c6d50d646813	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Adet	\N	\N	\N	52d0858a-01fd-4b65-800a-2b65b9b60a57	\N	\N	10.00	20.00	20.00	\N	\N	IQD	15.00	10.00	502.00	50.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
af831dbf-90ef-47e0-9e9a-d9d41470355e	001	\N	PHONE-001	8680000000001	iPhone 15 Pro	256GB Titanyum	\N	\N	\N	\N	\N	\N	\N	1eb458d5-8307-444c-85fe-b4da7898a934	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Adet	\N	\N	\N	\N	\N	\N	20.00	20.00	20.00	\N	\N	IQD	45000.00	35000.00	17.00	3.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
8cc29e25-143b-40ec-a37f-45c0a0291b92	001	\N	PC-001	8680000000010	MacBook Pro 16"	M3 Max 64GB	\N	\N	\N	\N	\N	\N	\N	ee4d6cda-6564-422d-b551-a85fd40db97f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Adet	\N	\N	\N	\N	\N	\N	20.00	20.00	20.00	\N	\N	IQD	95000.00	75000.00	7.00	2.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
3e22d00f-cdc8-4a35-b524-38f4f5987eae	001	\N	TSHIRT-VAR	\N	Unisex T-Shirt	Pamuk %100	\N	\N	\N	\N	\N	\N	\N	f7eb8335-f881-4bdc-9d84-97df0ab20aec	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Adet	\N	\N	\N	e3e502ca-61d7-4885-8776-6a90d8b7b2b2	\N	\N	10.00	20.00	20.00	\N	\N	IQD	250.00	140.00	0.00	10.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	t	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
e357f3d5-44fe-4523-b614-3ac5098a3a39	001	\N	PHONE-003	8680000000003	Xiaomi 14 Pro	256GB Beyaz	\N	\N	\N	\N	\N	\N	\N	1eb458d5-8307-444c-85fe-b4da7898a934	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Adet	\N	\N	\N	\N	\N	\N	20.00	20.00	20.00	\N	\N	IQD	25000.00	19000.00	29.00	5.00	0.00	0.00	none	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	f	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
f99e364d-f6f9-48aa-b360-91903d95ee3c	001	\N	10001	10001	ÖZBEK PİLAVI	\N			Kuzu eti 250gr, bitkisel ve zeytin yağı, pirinç, havuş soğan, sarımsak, baharatlar					\N	ANA YEMEKLER	\N	\N	GRP-01	\N	\N		\N	\N						commercial_goods	\N	\N	PRS			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	21750.00	15320.00	0.00	5.00	200.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:24.28614+03	2026-05-24 14:54:24.28614+03
09ae7aca-b96f-426c-ac82-ce13fa35b70a	001	\N	10002	10002	KIYMALI ŞİŞ KEBAP	\N								\N	ANA YEMEKLER	\N	\N	GRP-01	\N	\N		\N	\N						commercial_goods	\N	\N	PRS			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	12750.00	11580.00	0.00	5.00	50.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:24.359462+03	2026-05-24 14:54:24.359462+03
46e792bb-1fa6-4e6c-b088-e21ef0d60a2b	001	\N	10003	10003	KUZU ŞİŞ KEBAP	\N								\N	ANA YEMEKLER	\N	\N	GRP-01	\N	\N		\N	\N						commercial_goods	\N	\N	PRS			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	12500.00	7500.00	0.00	5.00	50.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:24.414748+03	2026-05-24 14:54:24.414748+03
85b37927-e719-43af-b0b2-117bdf7e84d3	001	\N	10004	10004	ÖZBEK MANTI BUHARDA	\N								\N	ANA YEMEKLER	\N	\N	GRP-01	\N	\N		\N	\N						commercial_goods	\N	\N	PRS			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	13500.00	8000.00	0.00	50.00	200.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:24.468294+03	2026-05-24 14:54:24.468294+03
ac28849b-cb73-4acf-a2e9-dacfabc5cca2	001	\N	10005	10005	ÖZBEK MANTI HAŞLAMA	\N								\N	ANA YEMEKLER	\N	\N	GRP-01	\N	\N		\N	\N						commercial_goods	\N	\N	PRS			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	13500.00	8000.00	0.00	50.00	200.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:24.531084+03	2026-05-24 14:54:24.531084+03
62e97a61-8d31-47f1-833c-28ca73136f52	001	\N	10006	10006	ÇİG BOREK KIYMALI	\N								\N	ATIŞTIRMALIK	\N	\N	GRP-02	\N	\N		\N	\N						commercial_goods	\N	\N	PRS			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	3750.00	2000.00	0.00	20.00	100.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:24.594533+03	2026-05-24 14:54:24.594533+03
71f14427-2a09-490f-8570-0a35e1b70d70	001	\N	10007	10007	ÇIG BOREK PEYNIRLI	\N								\N	ATIŞTIRMALIK	\N	\N	GRP-02	\N	\N		\N	\N						commercial_goods	\N	\N	PRS			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	3000.00	1200.00	0.00	20.00	100.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:24.650628+03	2026-05-24 14:54:24.650628+03
6cf645c9-4d56-40c1-ba3f-0d0446a70f29	001	\N	10008	10008	SAMSA	\N								\N	ATIŞTIRMALIK	\N	\N	GRP-02	\N	\N		\N	\N						commercial_goods	\N	\N	PRS			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	5750.00	4000.00	0.00	20.00	100.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:24.69964+03	2026-05-24 14:54:24.69964+03
4adb6a25-1f98-40b2-9a63-931b5fce3fed	001	\N	10009	10009	ÖZBEK ÇORBA	\N								\N	ÇORBALAR	\N	\N	GRP-03	\N	\N		\N	\N						commercial_goods	\N	\N	PRS			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	7000.00	5000.00	0.00	20.00	100.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:24.761552+03	2026-05-24 14:54:24.761552+03
b3b213bd-6bec-40a0-a878-fcabab723613	001	\N	10010	10010	KEK MEDOVİK	\N								\N	TATLILAR	\N	\N	GRP-04	\N	\N		\N	\N						commercial_goods	\N	\N	PRS			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	6500.00	4000.00	0.00	20.00	100.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:24.846819+03	2026-05-24 14:54:24.846819+03
d24a1aae-6aec-4b44-abe8-8905d21e82c2	001	\N	10011	10011	NAPOLEON	\N								\N	TATLILAR	\N	\N	GRP-04	\N	\N		\N	\N						commercial_goods	\N	\N	PRS			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	5000.00	2400.00	0.00	20.00	100.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:24.901322+03	2026-05-24 14:54:24.901322+03
d51d18ef-2fd5-4ade-87b8-6a7eeed132b0	001	\N	10012	10012	CHEESE CAKE	\N								\N	TATLILAR	\N	\N	GRP-04	\N	\N		\N	\N						commercial_goods	\N	\N	PRS			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	5750.00	2800.00	0.00	20.00	100.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:24.948927+03	2026-05-24 14:54:24.948927+03
dbb3d194-dc5a-44e6-91e1-2f019e7f1456	001	\N	10018	10018	PEPSI COLA	\N								\N	İÇECEKLER	\N	\N	GRP-06	\N	\N		\N	\N						commercial_goods	\N	\N	ADET			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	2500.00	2000.00	0.00	0.00	0.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:25.280115+03	2026-05-24 14:54:25.280115+03
715466c5-b115-45b3-b721-0637b0046a89	001	\N	10019	10019	PEPSI COLA ZERO	\N								\N	İÇECEKLER	\N	\N	GRP-06	\N	\N		\N	\N						commercial_goods	\N	\N	ADET			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	2500.00	2000.00	0.00	0.00	0.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:25.333099+03	2026-05-24 14:54:25.333099+03
54f5a0c9-4af3-4268-bb51-c4c7fc8c546d	001	\N	10020	10020	MIRANDA	\N								\N	İÇECEKLER	\N	\N	GRP-06	\N	\N		\N	\N						commercial_goods	\N	\N	ADET			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	2500.00	2000.00	0.00	0.00	0.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:25.379773+03	2026-05-24 14:54:25.379773+03
caa15694-d8fc-48d4-9e91-bcf31bd5cba1	001	\N	10023	10023	SU	\N								\N	İÇECEKLER	\N	\N	GRP-06	\N	\N		\N	\N						commercial_goods	\N	\N	ADET			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	0.00	250.00	0.00	0.00	0.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:25.540005+03	2026-05-24 14:54:25.540005+03
2db1e771-61d8-46af-a6b9-5b23fe9a0ea5	001	\N	10021	10021	7UP TENEKE	\N								\N	İÇECEKLER	\N	\N	GRP-06	\N	\N		\N	\N						commercial_goods	\N	\N	ADET			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	2500.00	2000.00	-1.00	0.00	0.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:25.433906+03	2026-05-24 14:54:25.433906+03
0230b49e-da04-4c01-8376-dcf39efcc266	001	\N	10022	10022	AYRAN BARDAK	\N								\N	İÇECEKLER	\N	\N	GRP-06	\N	\N		\N	\N						commercial_goods	\N	\N	ADET			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	1500.00	1000.00	-1.00	0.00	0.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:25.487107+03	2026-05-24 14:54:25.487107+03
6d2ba86e-cd03-436b-863d-791de70a281f	001	\N	10024	10024	ÇAY	\N								\N	İÇECEKLER	\N	\N	GRP-06	\N	\N		\N	\N						commercial_goods	\N	\N	ADET			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	0.00	250.00	-1.00	0.00	0.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:25.591681+03	2026-05-24 14:54:25.591681+03
102e4899-2368-4831-88ff-519515314eb1	001	\N	10017	10017	KARIŞIK SALATA (DOMATES SALATALIK)	\N								\N	SALATALAR	\N	\N	GRP-05	\N	\N		\N	\N						commercial_goods	\N	\N	PRS			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	3750.00	1500.00	-1.00	10.00	10.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:25.222159+03	2026-05-24 14:54:25.222159+03
a012f83b-d3f3-4435-8f40-46f9ea7541a7	001	\N	10025	10025	KAHVE	\N								\N	İÇECEKLER	\N	\N	GRP-06	\N	\N		\N	\N						commercial_goods	\N	\N	ADET			\N	\N	\N	\N	18.00	20.00	20.00	\N	\N	IQD	0.00	250.00	-1.00	0.00	0.00	0.00	none	\N	\N							\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	0.00	0.00	\N	\N	\N	\N	\N	\N	0.0000	0.00	0.00	0.00	0.00	0	f	5	\N	f	f	f	t	2026-05-24 14:54:25.644576+03	2026-05-24 14:54:25.644576+03
\.


--
-- Data for Name: rex_001_sales_reps; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_sales_reps (id, firm_nr, code, name, phone, email, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rex_001_services; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_services (id, firm_nr, code, name, description, description_tr, description_en, description_ar, description_ku, category, category_id, category_code, brand, model, manufacturer, supplier, origin, group_code, sub_group_code, special_code_1, special_code_2, special_code_3, special_code_4, special_code_5, special_code_6, unit, unit_price, unit_price_usd, unit_price_eur, purchase_price, purchase_price_usd, purchase_price_eur, tax_rate, tax_type, withholding_rate, discount1, discount2, discount3, image_url, price_list_1, price_list_2, price_list_3, price_list_4, price_list_5, price_list_6, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rex_001_special_codes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_special_codes (id, code, name, description, module_type, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_suppliers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_suppliers (id, firm_nr, code, name, phone, email, tax_nr, tax_office, address, city, neighborhood, district, contact_person, contact_person_phone, payment_terms, credit_limit, notes, balance, is_active, created_at) FROM stdin;
0811050d-d8a2-487a-a2b4-c9aea21d656d	001	SUP-001	Teknoloji Dağıtım A.Ş.	+964 750 111 0001	info@tekdag.iq	1111111111	\N	\N	Bağdat	\N	\N	Tarık Al-Mazidi	\N	Net 30	0.00	\N	0.00	t	2026-05-24 12:50:36.457566+03
104a593e-9ea7-4f47-a587-aad1268958f6	001	SUP-002	Gıda Tedarik Ltd.	+964 750 111 0002	info@gidated.iq	2222222222	\N	\N	Erbil	\N	\N	Soran Mustafa	\N	Net 15	0.00	\N	0.00	t	2026-05-24 12:50:36.457566+03
1481acd1-b545-4d76-ba3d-efde68b3c959	001	SUP-003	İçecek Distribütör	+964 750 111 0003	info@icecekd.iq	3333333333	\N	\N	Süleymaniye	\N	\N	Rizgar Karim	\N	Peşin	0.00	\N	0.00	t	2026-05-24 12:50:36.457566+03
dbfeda93-327c-46e7-8ce9-bcfef3ac627c	001	SUP-004	Güzellik Ürünleri AŞ	+964 750 111 0004	info@guzellik.iq	4444444444	\N	\N	Bağdat	\N	\N	Nour Al-Hassan	\N	Net 45	0.00	\N	0.00	t	2026-05-24 12:50:36.457566+03
482fe6e3-51d1-4863-ac89-4bca251eda18	001	SUP-005	Tekstil Toptan A.Ş.	+964 750 111 0005	info@tekstil.iq	5555555555	\N	\N	Basra	\N	\N	Ali Jabbar	\N	Net 30	0.00	\N	0.00	t	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: rex_001_tax_rates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_tax_rates (id, rate, description, is_active, created_at) FROM stdin;
09e011ad-d188-492f-97cc-ba02c45b60a0	0.00	Vergisiz	t	2026-05-24 12:50:05.210334+03
d6276179-fc6a-43e0-8061-a437b583189e	1.00	%1 KDV	t	2026-05-24 12:50:05.210334+03
58f2b96c-c466-464e-85da-57c978bdbfaf	8.00	%8 KDV	t	2026-05-24 12:50:05.210334+03
9026e0b2-c360-4692-8a31-07bec73bf512	10.00	%10 KDV	t	2026-05-24 12:50:05.210334+03
b4da2d52-5a54-4d14-b2ca-b9f8e8f1a0bd	18.00	%18 KDV	t	2026-05-24 12:50:05.210334+03
51b1f0a6-94d7-4d9f-a6fa-58b7e670e19d	20.00	%20 KDV	t	2026-05-24 12:50:05.210334+03
07e71644-275b-4230-b7f7-e9f50e645eba	0.00	Vergisiz	t	2026-05-24 12:50:37.037061+03
73fc8257-b17a-4346-b60b-27dfee2fc26c	1.00	%1 KDV	t	2026-05-24 12:50:37.037061+03
8ea1d758-770a-48d5-ba3a-dce168571789	8.00	%8 KDV	t	2026-05-24 12:50:37.037061+03
ca4fe41b-f11a-455f-95f7-cbba08754663	10.00	%10 KDV	t	2026-05-24 12:50:37.037061+03
98d257ff-ffdf-408a-919b-a8988050e7a0	18.00	%18 KDV	t	2026-05-24 12:50:37.037061+03
beb18927-372d-44a2-ab1b-dc59103f8e8c	20.00	%20 KDV	t	2026-05-24 12:50:37.037061+03
\.


--
-- Data for Name: rex_001_units; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_units (id, code, name, description, is_active, created_at) FROM stdin;
20bd8d27-746b-4460-aa40-657049d5f133	ADET	Adet	\N	t	2026-05-24 12:50:05.210334+03
29026b51-7c97-4f0c-ba8e-c9c855e5c889	KG	Kilogram	\N	t	2026-05-24 12:50:05.210334+03
57f7cef5-4afc-4ebc-8937-bb7210dd5e1e	GRAM	Gram	\N	t	2026-05-24 12:50:05.210334+03
d789ec40-8501-42fb-b542-728c0e45900d	TON	Ton	\N	t	2026-05-24 12:50:05.210334+03
dfe350c4-0727-4695-b756-09f1305d5b4f	METRE	Metre	\N	t	2026-05-24 12:50:05.210334+03
79a0d69a-9a43-49c1-a888-2ec12dd07325	TOP	Top	\N	t	2026-05-24 12:50:05.210334+03
8173c9d5-ea94-45e3-b785-0dac950cb9d4	LITRE	Litre	\N	t	2026-05-24 12:50:05.210334+03
3ee86cce-6479-4655-a82f-03ca174e6629	ML	Mililitre	\N	t	2026-05-24 12:50:05.210334+03
366546f5-01cc-4a6e-b840-78bc534346fa	PAKET	Paket	\N	t	2026-05-24 12:50:05.210334+03
3aec719a-4265-4fc4-b07e-4f6ec18bfba7	KOLI	Koli	\N	t	2026-05-24 12:50:05.210334+03
53264623-b8bc-453d-92aa-ebefef156e36	PALET	Palet	\N	t	2026-05-24 12:50:05.210334+03
430e2813-9441-4fff-8388-9694e2b2b2f0	DUZINE	Düzine	\N	t	2026-05-24 12:50:05.210334+03
f821ac8a-debb-4d9e-b791-d4da7800a102	M2	Metrekare	\N	t	2026-05-24 12:50:05.210334+03
b5674e34-9e72-45cd-acd0-1f3c4d4563b9	SAAT	Saat	\N	t	2026-05-24 12:50:05.210334+03
e5b1d577-6044-46c4-a9d1-e9864232c5cd	DAK	Dakika	\N	t	2026-05-24 12:50:05.210334+03
899c701e-4f73-429b-a31b-8481ce4c4204	KUTU	Kutu	\N	t	2026-05-24 12:50:05.210334+03
a44043eb-2900-4dd6-9851-7923fe4c1153	SET	Set	\N	t	2026-05-24 12:50:05.210334+03
edd3dab2-5757-4c41-9b63-ae1179e292e5	PARCA	Parca	\N	t	2026-05-24 12:50:05.210334+03
2c229e10-c60d-4ad2-b8e1-cb38ed047771	SISE	Sise	\N	t	2026-05-24 12:50:05.210334+03
d5ce530f-1886-4627-b2bb-b235d1c48745	KASA	Kasa	\N	t	2026-05-24 12:50:05.210334+03
\.


--
-- Data for Name: rex_001_unitsetl; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_unitsetl (id, unitset_id, item_code, code, name, main_unit, multiplier1, multiplier2, conv_fact1, conv_fact2) FROM stdin;
93e6c7ae-adaf-4b4a-9f93-5deb26a290b3	e3e502ca-61d7-4885-8776-6a90d8b7b2b2	ADET	ADET	Adet	t	1.00	1.00	1.000000	1.000000
23e66e3e-7d6b-4de9-957b-480cc6d91b2f	23bd4bc5-3f4f-4224-8c12-236d99729fda	KG	KG	Kilogram	t	1.00	1.00	1.000000	1.000000
060ec197-b5c8-48f9-8147-a8e45b7c6723	23bd4bc5-3f4f-4224-8c12-236d99729fda	GRAM	GRAM	Gram	f	1.00	1.00	1000.000000	1.000000
6df005f6-3ab1-4ae7-8002-84e3df470124	bba214df-f0fb-484d-a335-d68625be2517	LT	LT	Litre	t	1.00	1.00	1.000000	1.000000
0d76253b-0348-4f37-b776-0feeeedddb7e	bba214df-f0fb-484d-a335-d68625be2517	ML	ML	Mililitre	f	1.00	1.00	1000.000000	1.000000
85ebf6d8-95bf-4494-b29a-cf7fd090f695	a4b6b4cb-d045-4481-b5bc-21353a7226d6	ADET	ADET	Adet	t	1.00	1.00	1.000000	1.000000
c49e3674-a701-4676-a587-721a6009a2c4	a4b6b4cb-d045-4481-b5bc-21353a7226d6	KOLI	KOLI	Koli	f	1.00	1.00	6.000000	1.000000
cee34fe2-fca4-47bc-bca5-6917a1926e0c	6080a752-8446-4a77-918b-b2076c80faf0	ADET	ADET	Adet	t	1.00	1.00	1.000000	1.000000
854b33f8-c7a6-49be-895e-d9810cab4b04	6080a752-8446-4a77-918b-b2076c80faf0	KOLI	KOLI	Koli	f	1.00	1.00	12.000000	1.000000
21d5fa91-5864-4b79-bc2d-69d2d908354a	52d0858a-01fd-4b65-800a-2b65b9b60a57	ADET	ADET	Adet	t	1.00	1.00	1.000000	1.000000
419b3fff-9a88-40ba-94bb-d528e6f0af42	52d0858a-01fd-4b65-800a-2b65b9b60a57	KOLI	KOLI	Koli	f	1.00	1.00	24.000000	1.000000
a7c8ada4-48fe-419a-880d-9d541e9c3e5f	8aaf89e4-3924-47c0-aa11-f24218d1f619	ADET	ADET	Adet	t	1.00	1.00	1.000000	1.000000
961b8340-6404-4aa2-b27a-f66222a97583	8aaf89e4-3924-47c0-aa11-f24218d1f619	KOLI	KOLI	Koli	f	1.00	1.00	48.000000	1.000000
546af684-af68-4223-848d-7a216a84b289	5c276006-0271-4d6f-95f9-848bcc366f3d	ADET	ADET	Adet	t	1.00	1.00	1.000000	1.000000
86d8254c-dfd7-4f9d-a7ae-6a3d9e50df88	5c276006-0271-4d6f-95f9-848bcc366f3d	KOLI	KOLI	Koli	f	1.00	1.00	12.000000	1.000000
86c071ef-f011-4695-a97f-da41272fe0ff	5c276006-0271-4d6f-95f9-848bcc366f3d	PALET	PALET	Palet	f	1.00	1.00	144.000000	1.000000
eaef20bc-2030-4f44-bf87-315c2bda66e3	d2087639-67a4-4335-83cc-e83c4207cc46	ADET	ADET	Adet	t	1.00	1.00	1.000000	1.000000
e3ec4b4c-a0be-4f2b-b7c8-66409004d3bd	d2087639-67a4-4335-83cc-e83c4207cc46	DUZINE	DUZINE	Düzine	f	1.00	1.00	12.000000	1.000000
809053a9-1ede-4507-82d5-0d32f3a7a60c	f348bd14-8a59-46e4-a583-e46b2a105568	ADET	ADET	Adet	t	1.00	1.00	1.000000	1.000000
50c280a0-e92b-4d2f-8224-722540d370e4	f348bd14-8a59-46e4-a583-e46b2a105568	PAKET	PAKET	Paket	f	1.00	1.00	10.000000	1.000000
7ce61f8e-cdc7-4ada-8835-ae81efdfeb7f	1bca9214-33b8-4e31-8428-0aaa07d7e4ad	ADET	ADET	Adet	t	1.00	1.00	1.000000	1.000000
ed91c5d5-8cc8-43a3-8e47-f948ef917ff7	1bca9214-33b8-4e31-8428-0aaa07d7e4ad	PAKET	PAKET	Paket	f	1.00	1.00	5.000000	1.000000
9527c446-3ce2-4c00-8c11-ee0a1dc0f603	16700f79-83c4-45a8-a1ea-77a349f12d8f	METRE	METRE	Metre	t	1.00	1.00	1.000000	1.000000
713084fc-57a3-4816-9e92-9a6e4483c369	16700f79-83c4-45a8-a1ea-77a349f12d8f	TOP	TOP	Top	f	1.00	1.00	50.000000	1.000000
31a8c4c8-f170-4181-9569-820912233239	66fd4427-8815-459a-82b5-9f931025a93b	METRE	METRE	Metre	t	1.00	1.00	1.000000	1.000000
f9e3d614-0dd7-49c2-951c-83c0149bc5ba	66fd4427-8815-459a-82b5-9f931025a93b	TOP	TOP	Top	f	1.00	1.00	100.000000	1.000000
54b2577c-79c2-4401-8357-26ac3ff56b0b	a02f5304-bc95-4601-92a5-e16909977915	KG	KG	Kilogram	t	1.00	1.00	1.000000	1.000000
33d37a5f-00dd-4793-93ee-a08389d21197	a02f5304-bc95-4601-92a5-e16909977915	TON	TON	Ton	f	1.00	1.00	1000.000000	1.000000
0262446c-c623-47b2-b62b-2d4ff70440d0	e838b119-4382-4386-b602-f635be73b45a	M2	M2	Metrekare	t	1.00	1.00	1.000000	1.000000
9831b686-b6e2-4ac6-8aff-4046baf5a929	e051709d-ab4d-4ddb-af15-c0d98a440d1e	SAAT	SAAT	Saat	t	1.00	1.00	1.000000	1.000000
d0fb954e-cf12-4646-98ec-55d58ab45b9d	e051709d-ab4d-4ddb-af15-c0d98a440d1e	DAK	DAK	Dakika	f	1.00	1.00	60.000000	1.000000
96164009-a547-42e0-b6bf-3a05877c2076	7d6c23cf-18db-4cc3-9e9f-cee2edd1e576	ADET	ADET	Adet	t	1.00	1.00	1.000000	1.000000
0e06b3fe-196b-4109-b75f-74007b3509d7	7d6c23cf-18db-4cc3-9e9f-cee2edd1e576	KUTU	KUTU	Kutu	f	1.00	1.00	10.000000	1.000000
8e207d0c-9f38-4824-9330-5eea0807114d	3c3b07a0-764f-4266-90cf-e4d9e87129a2	SET	SET	Set	t	1.00	1.00	1.000000	1.000000
ad8b2131-f5cb-4a49-aea7-b9c82800dfdb	3c3b07a0-764f-4266-90cf-e4d9e87129a2	PARCA	PARCA	Parca	f	1.00	1.00	1.000000	1.000000
6e8ba572-9b1e-4a75-b992-7a6bf5a21386	8b81c546-7e3c-4a58-a156-ff30f4b82b50	KASA	KASA	Kasa	t	1.00	1.00	1.000000	1.000000
4422bf1f-3e52-4cc3-80f9-2507745090b3	8b81c546-7e3c-4a58-a156-ff30f4b82b50	SISE	SISE	Şişe	f	1.00	1.00	24.000000	1.000000
\.


--
-- Data for Name: rex_001_unitsets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rex_001_unitsets (id, code, name, is_active) FROM stdin;
e3e502ca-61d7-4885-8776-6a90d8b7b2b2	01-ADET	Tekil (Adet)	t
23bd4bc5-3f4f-4224-8c12-236d99729fda	02-KG	Kilogram / Gram	t
bba214df-f0fb-484d-a335-d68625be2517	03-LT	Litre / Mililitre	t
a4b6b4cb-d045-4481-b5bc-21353a7226d6	04-KOLI6	Koli (6 Adet)	t
6080a752-8446-4a77-918b-b2076c80faf0	05-KOLI12	Koli (12 Adet)	t
52d0858a-01fd-4b65-800a-2b65b9b60a57	06-KOLI24	Koli (24 Adet)	t
8aaf89e4-3924-47c0-aa11-f24218d1f619	07-KOLI48	Koli (48 Adet)	t
5c276006-0271-4d6f-95f9-848bcc366f3d	08-PALET	Adet / Koli(12) / Palet(144)	t
d2087639-67a4-4335-83cc-e83c4207cc46	09-DUZINE	Düzine (12 Adet)	t
f348bd14-8a59-46e4-a583-e46b2a105568	10-PKT10	Paket (10 Adet)	t
1bca9214-33b8-4e31-8428-0aaa07d7e4ad	11-PKT5	Paket (5 Adet)	t
16700f79-83c4-45a8-a1ea-77a349f12d8f	12-METRE-TOP50	Metre / Top (50m)	t
66fd4427-8815-459a-82b5-9f931025a93b	13-METRE-TOP100	Metre / Top (100m)	t
a02f5304-bc95-4601-92a5-e16909977915	14-KG-TON	Kilogram / Ton	t
e838b119-4382-4386-b602-f635be73b45a	15-M2	Metrekare (M²)	t
e051709d-ab4d-4ddb-af15-c0d98a440d1e	16-SAAT	Saat / Dakika	t
7d6c23cf-18db-4cc3-9e9f-cee2edd1e576	17-KUTU	Kutu / Adet	t
3c3b07a0-764f-4266-90cf-e4d9e87129a2	18-SET	Set / Parca	t
8b81c546-7e3c-4a58-a156-ff30f4b82b50	05-SISE24	Şişe (24li Kasa)	t
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.roles (id, name, description, permissions, is_system_role, color, landing_route, created_at, updated_at) FROM stdin;
00000000-0000-0000-0000-000000000001	admin	Tam yetkili sistem yöneticisi	["*"]	t	#9333ea	\N	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
00000000-0000-0000-0000-000000000002	manager	Mağaza Müdürü	["pos.*", "management.*", "reports.*"]	t	#3B82F6	\N	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
00000000-0000-0000-0000-000000000003	cashier	Kasiyer — Satış Yetkisi	["pos.view", "pos.sell"]	t	#10B981	pos	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
00000000-0000-0000-0000-000000000004	stock	Stok ve Depo Sorumlusu	["management.products", "reports.inventory"]	t	#F59E0B	\N	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
00000000-0000-0000-0000-000000000005	garson	Garson — Restoran masa servisi	["restaurant.pos", "restaurant.kds"]	t	#F97316	restaurant	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
\.


--
-- Data for Name: service_health; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.service_health (service_id, service_name, last_heartbeat, status, version, metadata, updated_at) FROM stdin;
ddf8b519-546e-478b-a6ee-43fb4a62c6f1	RetailEX-Sync-Service	2026-05-24 12:50:05.210334+03	OFFLINE	2.0.0	{"description": "Core sync engine"}	2026-05-24 12:50:05.210334+03
b4ca7518-0d00-45bf-a167-8c96c3c3e6dc	RetailEX-Logo-Connector	2026-05-24 12:50:05.210334+03	OFFLINE	1.0.0	{"description": "Logo ERP bridge"}	2026-05-24 12:50:05.210334+03
\.


--
-- Data for Name: service_transactions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.service_transactions (id, firm_nr, store_id, transaction_type, provider, target_number, package_name, amount, cost, currency, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: stores; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.stores (id, code, name, type, city, region, address, phone, email, tax_office, tax_number, firm_nr, manager_name, is_main, is_active, "default", logo_warehouse_id, logo_division_id, logo_firm_id, created_at, updated_at) FROM stdin;
ec676656-87f6-4170-ad61-9e8cf60fab05	ST_01	Merkez Depo	\N	\N	\N	\N	\N	\N	\N	\N	001	\N	t	t	t	\N	\N	\N	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
\.


--
-- Data for Name: sync_queue; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sync_queue (id, table_name, record_id, action, firm_nr, data, status, target_store_id, source_system, synced_at, retry_count, error_message, created_at) FROM stdin;
2acf14ab-7460-4591-85c0-30d9fa6246f8	rex_001_categories	9bf0d905-7740-42bd-b875-60215cfd6eda	INSERT	001	{"id": "9bf0d905-7740-42bd-b875-60215cfd6eda", "code": "ELEC", "icon": null, "name": "Elektronik", "is_active": true, "parent_id": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "description": null, "is_restaurant": false}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
60e689d3-2beb-46cd-b47c-8e848f34b637	rex_001_categories	1eb458d5-8307-444c-85fe-b4da7898a934	INSERT	001	{"id": "1eb458d5-8307-444c-85fe-b4da7898a934", "code": "ELEC-PHONE", "icon": null, "name": "Telefonlar", "is_active": true, "parent_id": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "description": null, "is_restaurant": false}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
acec66b2-dfd0-430b-9e77-02a53d33fb2a	rex_001_categories	ee4d6cda-6564-422d-b551-a85fd40db97f	INSERT	001	{"id": "ee4d6cda-6564-422d-b551-a85fd40db97f", "code": "ELEC-PC", "icon": null, "name": "Bilgisayarlar", "is_active": true, "parent_id": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "description": null, "is_restaurant": false}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
fa03c091-5445-4504-ad8f-578bfc8be1b6	rex_001_categories	c12f15f6-2583-4f54-8d54-886c43485983	INSERT	001	{"id": "c12f15f6-2583-4f54-8d54-886c43485983", "code": "FOOD", "icon": null, "name": "Gıda", "is_active": true, "parent_id": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "description": null, "is_restaurant": false}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
fbd2cd4d-b7e2-4861-a7a8-da82a62fb63f	rex_001_categories	432eaefc-f2ef-4df3-abd7-c6d50d646813	INSERT	001	{"id": "432eaefc-f2ef-4df3-abd7-c6d50d646813", "code": "FOOD-SNACK", "icon": null, "name": "Atıştırmalık", "is_active": true, "parent_id": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "description": null, "is_restaurant": false}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
f7c40619-e37a-4af0-9340-c5c80ae0894d	rex_001_categories	7bb67d97-2dbd-4301-9b86-e0373026e436	INSERT	001	{"id": "7bb67d97-2dbd-4301-9b86-e0373026e436", "code": "FOOD-DRINK", "icon": null, "name": "İçecekler", "is_active": true, "parent_id": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "description": null, "is_restaurant": false}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
dd2be65e-4822-4142-bf7e-03f7a31fb0c0	rex_001_categories	7cdc0ede-2c44-4ba6-bfb1-ecfea07406cc	INSERT	001	{"id": "7cdc0ede-2c44-4ba6-bfb1-ecfea07406cc", "code": "BEAUTY-P", "icon": null, "name": "Güzellik Ürünleri", "is_active": true, "parent_id": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "description": null, "is_restaurant": false}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
f2c797f4-fe00-4b43-9eaa-331566bf6107	rex_001_categories	f7eb8335-f881-4bdc-9d84-97df0ab20aec	INSERT	001	{"id": "f7eb8335-f881-4bdc-9d84-97df0ab20aec", "code": "CLOTH", "icon": null, "name": "Giyim", "is_active": true, "parent_id": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "description": null, "is_restaurant": false}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
cea49485-3b8e-4a14-bfc7-afb0725ec525	rex_001_categories	5b385721-22fc-4f66-8453-a5739c16975f	INSERT	001	{"id": "5b385721-22fc-4f66-8453-a5739c16975f", "code": "REST-ANA", "icon": null, "name": "Ana Yemekler", "is_active": true, "parent_id": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "description": null, "is_restaurant": true}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
32dd42ba-2771-4d40-8667-ef6780d0a861	rex_001_categories	a4c099bc-7e84-4970-a6aa-1e696ec50b07	INSERT	001	{"id": "a4c099bc-7e84-4970-a6aa-1e696ec50b07", "code": "REST-ICECEK", "icon": null, "name": "İçecekler", "is_active": true, "parent_id": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "description": null, "is_restaurant": true}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
14887a38-7ab1-4a82-a168-c7e319d2d6a2	rex_001_categories	907976d3-cec5-49da-b715-c19250d618f3	INSERT	001	{"id": "907976d3-cec5-49da-b715-c19250d618f3", "code": "REST-TATLI", "icon": null, "name": "Tatlılar", "is_active": true, "parent_id": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "description": null, "is_restaurant": true}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
77ccdb8b-aaa7-4bd6-8c87-65f8425248e5	rex_001_products	b3932d01-23c2-433b-bd6e-d24bb8073dfd	UPDATE	001	{"id": "b3932d01-23c2-433b-bd6e-d24bb8073dfd", "code": "PHONE-002", "cost": 29000.00, "name": "Samsung Galaxy S24", "unit": "Adet", "brand": null, "model": null, "name2": "512GB Siyah", "price": 38000.00, "stock": 22.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": "8680000000002", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 20.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 3.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "1eb458d5-8307-444c-85fe-b4da7898a934", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:26.34772+03
d1865954-0d17-4cf9-bf4e-1282318b5206	rex_001_cash_registers	00000000-0000-0000-0000-000000000001	UPDATE	001	{"id": "00000000-0000-0000-0000-000000000001", "code": "KASA.001", "name": "MERKEZ KASA", "balance": 8630.00, "firm_nr": "001", "is_active": true, "created_at": "2026-05-24T12:50:05.210334+03:00", "updated_at": "2026-05-24T12:50:05.210334+03:00", "currency_code": "IQD"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 16:25:59.345127+03
c6003778-4845-4a90-9a20-23d8a943148d	rex_001_customers	4539a45d-229b-403a-bb72-8676047cf222	INSERT	001	{"id": "4539a45d-229b-403a-bb72-8676047cf222", "age": null, "city": "Erbil", "code": "CUST-002", "name": "Sara Mahmoud", "email": "sara@mail.com", "notes": null, "phone": "+964 770 100 0002", "gender": null, "phone2": null, "points": 0.00, "tax_nr": "9002002002", "address": "Havalar Mh. No:45", "balance": 0.00, "file_id": null, "firm_nr": "001", "taxi_nr": null, "district": null, "is_active": true, "created_at": "2026-05-24T12:50:36.457566+03:00", "heard_from": null, "occupation": null, "tax_office": null, "total_spent": 0.00, "neighborhood": null, "customer_tier": "normal"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
b117144b-acd0-425a-9053-2041d181ec4a	rex_001_products	d1ee26fe-19e1-4b87-8059-bbda4697648c	UPDATE	001	{"id": "d1ee26fe-19e1-4b87-8059-bbda4697648c", "code": "PC-002", "cost": 43000.00, "name": "Dell XPS 15", "unit": "Adet", "brand": null, "model": null, "name2": "i9 32GB RTX4060", "price": 55000.00, "stock": 12.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": "8680000000011", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 20.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 2.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "ee4d6cda-6564-422d-b551-a85fd40db97f", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:25.713778+03
bd90f7c6-1646-4d89-b3cc-24966824013d	rex_001_customers	3dee3608-a4b1-4b27-b569-e94f56dcb6ad	INSERT	001	{"id": "3dee3608-a4b1-4b27-b569-e94f56dcb6ad", "age": null, "city": "Süleymaniye", "code": "CUST-003", "name": "Karim Hassan", "email": "karim@mail.com", "notes": null, "phone": "+964 770 100 0003", "gender": null, "phone2": null, "points": 0.00, "tax_nr": "9003003003", "address": "Salahaddin Blv. No:78", "balance": 0.00, "file_id": null, "firm_nr": "001", "taxi_nr": null, "district": null, "is_active": true, "created_at": "2026-05-24T12:50:36.457566+03:00", "heard_from": null, "occupation": null, "tax_office": null, "total_spent": 0.00, "neighborhood": null, "customer_tier": "normal"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
8f3f8ae8-6787-45df-a574-7774fac4c977	rex_001_products	9c615850-4150-4b1e-92bb-05b374408c47	UPDATE	001	{"id": "9c615850-4150-4b1e-92bb-05b374408c47", "code": "BEAUTY-002", "cost": 60.00, "name": "Saç Bakım Kremi", "unit": "Adet", "brand": null, "model": null, "name2": "250ml", "price": 95.00, "stock": 180.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": "8680000000041", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 10.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 20.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "7cdc0ede-2c44-4ba6-bfb1-ecfea07406cc", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:26.246963+03
51c1ee97-2435-405e-b02b-21a56656dd39	rex_001_products	a60b4e43-28a1-4cc1-9267-f6d682cdbf34	UPDATE	001	{"id": "a60b4e43-28a1-4cc1-9267-f6d682cdbf34", "code": "BEAUTY-001", "cost": 75.00, "name": "Şampuan 400ml", "unit": "Adet", "brand": null, "model": null, "name2": "Bakım Serisi", "price": 120.00, "stock": 200.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": "8680000000040", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 10.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 20.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "7cdc0ede-2c44-4ba6-bfb1-ecfea07406cc", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:26.298494+03
ccee8c1c-3c4f-4117-ac74-7a229495f072	rex_001_customers	44c4f595-0989-45f8-8951-3f586eb4a9a8	INSERT	001	{"id": "44c4f595-0989-45f8-8951-3f586eb4a9a8", "age": null, "city": "Musul", "code": "CUST-004", "name": "Lara Aziz", "email": "lara@mail.com", "notes": null, "phone": "+964 770 100 0004", "gender": null, "phone2": null, "points": 0.00, "tax_nr": "9004004004", "address": "Yarmouk Mh. No:23", "balance": 0.00, "file_id": null, "firm_nr": "001", "taxi_nr": null, "district": null, "is_active": true, "created_at": "2026-05-24T12:50:36.457566+03:00", "heard_from": null, "occupation": null, "tax_office": null, "total_spent": 0.00, "neighborhood": null, "customer_tier": "normal"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
b6c4073d-507a-4460-ad6e-773d10083633	rex_001_products	e9af8bb5-8242-462c-b87c-0e4a57f0fc6b	UPDATE	001	{"id": "e9af8bb5-8242-462c-b87c-0e4a57f0fc6b", "code": "MENU-004", "cost": 4.00, "name": "Çay", "unit": "Bardak", "brand": null, "model": null, "name2": "Demlik", "price": 20.00, "stock": 999.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": null, "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 0.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 1.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "a4c099bc-7e84-4970-a6aa-1e696ec50b07", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:25.549023+03
a7aebc70-ff09-4b4c-a6e5-040cfbc2ccd9	rex_001_products	548baacc-2176-4a2f-b567-dd9e9cc72c42	UPDATE	001	{"id": "548baacc-2176-4a2f-b567-dd9e9cc72c42", "code": "MENU-001", "cost": 80.00, "name": "Izgara Köfte", "unit": "Porsiyon", "brand": null, "model": null, "name2": "200g, Salata ile", "price": 250.00, "stock": 999.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": null, "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 10.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 1.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "5b385721-22fc-4f66-8453-a5739c16975f", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:25.995051+03
02ae1abb-3d1c-4bea-9f9e-3d595a9ece39	rex_001_products	cbde588d-e929-4924-9943-734518ea0dd0	UPDATE	001	{"id": "cbde588d-e929-4924-9943-734518ea0dd0", "code": "MENU-003", "cost": 20.00, "name": "Mercimek Çorbası", "unit": "Porsiyon", "brand": null, "model": null, "name2": "Kase", "price": 80.00, "stock": 999.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": null, "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 10.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 1.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "5b385721-22fc-4f66-8453-a5739c16975f", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:26.196019+03
688da1ca-c080-4c97-9218-66c461de2bd9	rex_001_products	bef201e4-a721-4b6b-9c82-87b37d5b2c73	UPDATE	001	{"id": "bef201e4-a721-4b6b-9c82-87b37d5b2c73", "code": "MENU-002", "cost": 65.00, "name": "Tavuk Şiş", "unit": "Porsiyon", "brand": null, "model": null, "name2": "3'lü, Pilav ile", "price": 220.00, "stock": 999.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": null, "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 10.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 1.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "5b385721-22fc-4f66-8453-a5739c16975f", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:26.518819+03
05a602b2-84b1-4959-b493-47bb88f09ebd	rex_001_customers	08aece31-ba6e-4dee-a8c8-fc8ec0438378	INSERT	001	{"id": "08aece31-ba6e-4dee-a8c8-fc8ec0438378", "age": null, "city": "Basra", "code": "CUST-005", "name": "Omar Khalil", "email": "omar@mail.com", "notes": null, "phone": "+964 770 100 0005", "gender": null, "phone2": null, "points": 0.00, "tax_nr": "9005005005", "address": "Corniche Cad. No:5", "balance": 0.00, "file_id": null, "firm_nr": "001", "taxi_nr": null, "district": null, "is_active": true, "created_at": "2026-05-24T12:50:36.457566+03:00", "heard_from": null, "occupation": null, "tax_office": null, "total_spent": 0.00, "neighborhood": null, "customer_tier": "normal"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
e1804630-3b7d-45f4-8b03-6c54aabf83d1	rex_001_products	f483a7c5-d84f-4ca3-b7ae-e2363c887ae2	UPDATE	001	{"id": "f483a7c5-d84f-4ca3-b7ae-e2363c887ae2", "code": "SNACK-003", "cost": 17.00, "name": "Bisküvi Paketi", "unit": "Adet", "brand": null, "model": null, "name2": "Çikolatalı 200g", "price": 25.00, "stock": 279.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": "8680000000022", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 10.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 30.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": "52d0858a-01fd-4b65-800a-2b65b9b60a57", "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "432eaefc-f2ef-4df3-abd7-c6d50d646813", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:25.479441+03
4c0cbe6c-2760-40b8-89b5-f47da5955078	rex_001_products	6aa4a637-9b1c-4ffb-a2af-0387cf2ef110	UPDATE	001	{"id": "6aa4a637-9b1c-4ffb-a2af-0387cf2ef110", "code": "SNACK-002", "cost": 8.00, "name": "Cips", "unit": "Adet", "brand": null, "model": null, "name2": "Klasik Tuzlu 150g", "price": 12.50, "stock": 350.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": "8680000000021", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 10.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 50.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": "52d0858a-01fd-4b65-800a-2b65b9b60a57", "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "432eaefc-f2ef-4df3-abd7-c6d50d646813", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:25.666557+03
f73289fc-b19f-4b9e-aa95-13ecdd9534e8	rex_001_products	80720be4-a213-4dc4-afd1-58d3d4ad6a07	UPDATE	001	{"id": "80720be4-a213-4dc4-afd1-58d3d4ad6a07", "code": "MENU-005", "cost": 6.00, "name": "Ayran", "unit": "Bardak", "brand": null, "model": null, "name2": "300ml", "price": 25.00, "stock": 998.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": null, "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 10.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 1.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "a4c099bc-7e84-4970-a6aa-1e696ec50b07", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:25.425329+03
1206543f-508a-4a4c-b9b2-dcb6c4547eee	rex_001_products	11ba96b7-b0f5-4aa5-8a28-494079223b1b	UPDATE	001	{"id": "11ba96b7-b0f5-4aa5-8a28-494079223b1b", "code": "MENU-006", "cost": 25.00, "name": "Sütlaç", "unit": "Porsiyon", "brand": null, "model": null, "name2": "Fırın", "price": 85.00, "stock": 999.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": null, "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 10.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 1.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "907976d3-cec5-49da-b715-c19250d618f3", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:26.474936+03
e97806f6-f45c-49db-9654-46e49c1494af	rex_001_products	3162b084-ea83-41c4-8c67-e1f5263dd740	UPDATE	001	{"id": "3162b084-ea83-41c4-8c67-e1f5263dd740", "code": "MENU-007", "cost": 55.00, "name": "Hamburger Menü", "unit": "Porsiyon", "brand": null, "model": null, "name2": "Patates + İçecek", "price": 180.00, "stock": 998.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": null, "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 10.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 1.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": null, "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 16:25:58.925595+03
585281b8-821c-4161-a70c-c2656a2f308d	rex_001_products	a0fb4938-b6db-41a5-bd8d-e7f5a2fed940	UPDATE	001	{"id": "a0fb4938-b6db-41a5-bd8d-e7f5a2fed940", "code": "CLOTH-001", "cost": 280.00, "name": "Erkek Gömlek", "unit": "Adet", "brand": null, "model": null, "name2": "Beyaz Klasik", "price": 450.00, "stock": 45.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": "8680000000050", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 10.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 10.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": "e3e502ca-61d7-4885-8776-6a90d8b7b2b2", "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "f7eb8335-f881-4bdc-9d84-97df0ab20aec", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:25.765888+03
816d24d5-4139-46a7-8e05-0f011834fed5	rex_001_products	b5fc427f-7e17-43c7-b18c-972009e4a080	UPDATE	001	{"id": "b5fc427f-7e17-43c7-b18c-972009e4a080", "code": "CLOTH-003", "cost": 230.00, "name": "Kadın Bluz", "unit": "Adet", "brand": null, "model": null, "name2": "Pembe Şifon", "price": 380.00, "stock": 52.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": "8680000000052", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 10.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 10.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": "e3e502ca-61d7-4885-8776-6a90d8b7b2b2", "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "f7eb8335-f881-4bdc-9d84-97df0ab20aec", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:26.047791+03
305adbac-dfe6-4685-8012-0716d76e2b38	rex_001_products	07138e50-60dd-4669-a979-8816864f6f12	UPDATE	001	{"id": "07138e50-60dd-4669-a979-8816864f6f12", "code": "DRINK-001", "cost": 5.50, "name": "Kola 500ml", "unit": "Adet", "brand": null, "model": null, "name2": "Şişe", "price": 8.50, "stock": 600.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": "8680000000030", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 10.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 100.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": "52d0858a-01fd-4b65-800a-2b65b9b60a57", "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "7bb67d97-2dbd-4301-9b86-e0373026e436", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:26.096995+03
0453b4f6-0dcf-4020-a8f4-ee46fa4825fa	rex_001_products	31a9ff19-31e3-49f8-a2f2-9381644cfc62	UPDATE	001	{"id": "31a9ff19-31e3-49f8-a2f2-9381644cfc62", "code": "DRINK-002", "cost": 2.50, "name": "Su 1.5L", "unit": "Adet", "brand": null, "model": null, "name2": "Büyük Şişe", "price": 4.00, "stock": 800.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": "8680000000031", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 10.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 100.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": "52d0858a-01fd-4b65-800a-2b65b9b60a57", "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "7bb67d97-2dbd-4301-9b86-e0373026e436", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:26.399548+03
a1f1566b-1c9c-4636-810f-55ad4093a70d	rex_001_products	9a8f7096-e89c-43c4-9d50-c8b40fcc043a	UPDATE	001	{"id": "9a8f7096-e89c-43c4-9d50-c8b40fcc043a", "code": "CLOTH-002", "cost": 400.00, "name": "Erkek Pantolon", "unit": "Adet", "brand": null, "model": null, "name2": "Lacivert Kumaş", "price": 650.00, "stock": 37.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": "8680000000051", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 10.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 10.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": "e3e502ca-61d7-4885-8776-6a90d8b7b2b2", "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "f7eb8335-f881-4bdc-9d84-97df0ab20aec", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 16:25:58.947358+03
2043a590-4dd3-434c-b39f-78a6b95304c8	rex_001_products	3e22d00f-cdc8-4a35-b524-38f4f5987eae	UPDATE	001	{"id": "3e22d00f-cdc8-4a35-b524-38f4f5987eae", "code": "TSHIRT-VAR", "cost": 140.00, "name": "Unisex T-Shirt", "unit": "Adet", "brand": null, "model": null, "name2": "Pamuk %100", "price": 250.00, "stock": 0.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": null, "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 10.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 10.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": "e3e502ca-61d7-4885-8776-6a90d8b7b2b2", "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "f7eb8335-f881-4bdc-9d84-97df0ab20aec", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": true, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:26.562448+03
1f39c744-4ce1-4c26-b928-d1d1aa995211	rex_001_suppliers	0811050d-d8a2-487a-a2b4-c9aea21d656d	INSERT	001	{"id": "0811050d-d8a2-487a-a2b4-c9aea21d656d", "city": "Bağdat", "code": "SUP-001", "name": "Teknoloji Dağıtım A.Ş.", "email": "info@tekdag.iq", "notes": null, "phone": "+964 750 111 0001", "tax_nr": "1111111111", "address": null, "balance": 0.00, "firm_nr": "001", "district": null, "is_active": true, "created_at": "2026-05-24T12:50:36.457566+03:00", "tax_office": null, "credit_limit": 0.00, "neighborhood": null, "payment_terms": "Net 30", "contact_person": "Tarık Al-Mazidi", "contact_person_phone": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
291800ef-b8a1-4304-bb45-f8255b275f90	rex_001_suppliers	104a593e-9ea7-4f47-a587-aad1268958f6	INSERT	001	{"id": "104a593e-9ea7-4f47-a587-aad1268958f6", "city": "Erbil", "code": "SUP-002", "name": "Gıda Tedarik Ltd.", "email": "info@gidated.iq", "notes": null, "phone": "+964 750 111 0002", "tax_nr": "2222222222", "address": null, "balance": 0.00, "firm_nr": "001", "district": null, "is_active": true, "created_at": "2026-05-24T12:50:36.457566+03:00", "tax_office": null, "credit_limit": 0.00, "neighborhood": null, "payment_terms": "Net 15", "contact_person": "Soran Mustafa", "contact_person_phone": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
2d8230fa-02ca-4f12-9cfa-5051353fcbbc	rex_001_suppliers	1481acd1-b545-4d76-ba3d-efde68b3c959	INSERT	001	{"id": "1481acd1-b545-4d76-ba3d-efde68b3c959", "city": "Süleymaniye", "code": "SUP-003", "name": "İçecek Distribütör", "email": "info@icecekd.iq", "notes": null, "phone": "+964 750 111 0003", "tax_nr": "3333333333", "address": null, "balance": 0.00, "firm_nr": "001", "district": null, "is_active": true, "created_at": "2026-05-24T12:50:36.457566+03:00", "tax_office": null, "credit_limit": 0.00, "neighborhood": null, "payment_terms": "Peşin", "contact_person": "Rizgar Karim", "contact_person_phone": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
62cff297-510f-4e46-8ef1-07eff41d5312	rex_001_suppliers	dbfeda93-327c-46e7-8ce9-bcfef3ac627c	INSERT	001	{"id": "dbfeda93-327c-46e7-8ce9-bcfef3ac627c", "city": "Bağdat", "code": "SUP-004", "name": "Güzellik Ürünleri AŞ", "email": "info@guzellik.iq", "notes": null, "phone": "+964 750 111 0004", "tax_nr": "4444444444", "address": null, "balance": 0.00, "firm_nr": "001", "district": null, "is_active": true, "created_at": "2026-05-24T12:50:36.457566+03:00", "tax_office": null, "credit_limit": 0.00, "neighborhood": null, "payment_terms": "Net 45", "contact_person": "Nour Al-Hassan", "contact_person_phone": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
e6e4fc58-3b35-4d83-802d-34d04d937555	rex_001_suppliers	482fe6e3-51d1-4863-ac89-4bca251eda18	INSERT	001	{"id": "482fe6e3-51d1-4863-ac89-4bca251eda18", "city": "Basra", "code": "SUP-005", "name": "Tekstil Toptan A.Ş.", "email": "info@tekstil.iq", "notes": null, "phone": "+964 750 111 0005", "tax_nr": "5555555555", "address": null, "balance": 0.00, "firm_nr": "001", "district": null, "is_active": true, "created_at": "2026-05-24T12:50:36.457566+03:00", "tax_office": null, "credit_limit": 0.00, "neighborhood": null, "payment_terms": "Net 30", "contact_person": "Ali Jabbar", "contact_person_phone": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
1d8e22ac-53f5-4092-a58c-6bc20d9c7dd7	rex_001_customers	6134d937-b8ed-404f-806c-16e851c71de3	INSERT	001	{"id": "6134d937-b8ed-404f-806c-16e851c71de3", "age": null, "city": "Bağdat", "code": "CUST-001", "name": "Ahmed Al-Rashidi", "email": "ahmed@mail.com", "notes": null, "phone": "+964 770 100 0001", "gender": null, "phone2": null, "points": 0.00, "tax_nr": "9001001001", "address": "Kerkük Cad. No:12", "balance": 0.00, "file_id": null, "firm_nr": "001", "taxi_nr": null, "district": null, "is_active": true, "created_at": "2026-05-24T12:50:36.457566+03:00", "heard_from": null, "occupation": null, "tax_office": null, "total_spent": 0.00, "neighborhood": null, "customer_tier": "normal"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
e737753f-5437-4d9d-ab2b-7e3224402c3c	rex_001_products	5440758d-a1f4-4555-bd13-eeade9dfb89c	UPDATE	001	{"id": "5440758d-a1f4-4555-bd13-eeade9dfb89c", "code": "PHONE-VAR", "cost": 13500.00, "name": "Akıllı Telefon X12", "unit": "Adet", "brand": null, "model": null, "name2": "Çift SIM 5G", "price": 18000.00, "stock": 0.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": null, "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 20.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 2.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": "e3e502ca-61d7-4885-8776-6a90d8b7b2b2", "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "1eb458d5-8307-444c-85fe-b4da7898a934", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": true, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:25.36156+03
d94d52ef-3a6c-4d99-bf78-fc874c84ceec	rex_001_customers	c62753d1-0015-43b9-995a-84c663daa020	INSERT	001	{"id": "c62753d1-0015-43b9-995a-84c663daa020", "age": null, "city": "Bağdat", "code": "CORP-001", "name": "Al-Noor Teknoloji", "email": "info@alnoor.iq", "notes": null, "phone": "+964 770 200 0001", "gender": null, "phone2": null, "points": 0.00, "tax_nr": "8001001001", "address": "Mansour Mh. No:100", "balance": 0.00, "file_id": null, "firm_nr": "001", "taxi_nr": null, "district": null, "is_active": true, "created_at": "2026-05-24T12:50:36.457566+03:00", "heard_from": null, "occupation": null, "tax_office": null, "total_spent": 0.00, "neighborhood": null, "customer_tier": "normal"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
357a894d-b590-4931-bb2a-4ed0aadd948a	rex_001_customers	8b69acbf-75a8-4c07-98ea-1abd9dffbdff	INSERT	001	{"id": "8b69acbf-75a8-4c07-98ea-1abd9dffbdff", "age": null, "city": "Erbil", "code": "CORP-002", "name": "Kurdistan Market", "email": "info@kurdmkt.iq", "notes": null, "phone": "+964 750 200 0002", "gender": null, "phone2": null, "points": 0.00, "tax_nr": "8002002002", "address": "Ankawa Cad. No:55", "balance": 0.00, "file_id": null, "firm_nr": "001", "taxi_nr": null, "district": null, "is_active": true, "created_at": "2026-05-24T12:50:36.457566+03:00", "heard_from": null, "occupation": null, "tax_office": null, "total_spent": 0.00, "neighborhood": null, "customer_tier": "normal"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
eeec37d6-873a-485e-9180-0babf0daa624	rex_001_customers	93198df4-6949-48d0-b29b-34eeb8bb0931	INSERT	001	{"id": "93198df4-6949-48d0-b29b-34eeb8bb0931", "age": null, "city": "Basra", "code": "CORP-003", "name": "Basra Trade Co.", "email": "info@basratrade.iq", "notes": null, "phone": "+964 780 200 0003", "gender": null, "phone2": null, "points": 0.00, "tax_nr": "8003003003", "address": "Port Mh. No:7", "balance": 0.00, "file_id": null, "firm_nr": "001", "taxi_nr": null, "district": null, "is_active": true, "created_at": "2026-05-24T12:50:36.457566+03:00", "heard_from": null, "occupation": null, "tax_office": null, "total_spent": 0.00, "neighborhood": null, "customer_tier": "normal"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
6484dbd3-b9cf-4b8c-a579-f1277929d0b6	rex_001_01_sales	40a8cda1-7e72-4080-b12f-84109cb4915b	INSERT	001	{"id": "40a8cda1-7e72-4080-b12f-84109cb4915b", "date": "2026-01-05T10:30:00+03:00", "notes": null, "status": "completed", "trcode": null, "cashier": null, "firm_nr": "001", "currency": "IQD", "fiche_no": "SAT-2026-0001", "store_id": null, "period_nr": "01", "total_net": 45000.00, "total_vat": 9000.00, "created_at": "2026-05-24T12:50:36.457566+03:00", "fiche_type": "S", "net_amount": 0.00, "total_cost": 0.00, "updated_at": "2026-05-24T12:50:36.457566+03:00", "customer_id": "6134d937-b8ed-404f-806c-16e851c71de3", "document_no": null, "total_gross": 54000.00, "gross_profit": 0.00, "is_cancelled": false, "credit_amount": 0.00, "currency_rate": 1.000000, "customer_name": null, "profit_margin": 0.00, "payment_method": "cash", "total_discount": 0.00, "logo_sync_status": "pending"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
ec40fd26-ef95-4cab-a837-97bb6c7990b5	rex_001_01_sales	14fe0e2e-6bbc-41e9-b9b3-d1daee90591b	INSERT	001	{"id": "14fe0e2e-6bbc-41e9-b9b3-d1daee90591b", "date": "2026-01-07T14:15:00+03:00", "notes": null, "status": "completed", "trcode": null, "cashier": null, "firm_nr": "001", "currency": "IQD", "fiche_no": "SAT-2026-0002", "store_id": null, "period_nr": "01", "total_net": 95000.00, "total_vat": 19000.00, "created_at": "2026-05-24T12:50:36.457566+03:00", "fiche_type": "S", "net_amount": 0.00, "total_cost": 0.00, "updated_at": "2026-05-24T12:50:36.457566+03:00", "customer_id": "c62753d1-0015-43b9-995a-84c663daa020", "document_no": null, "total_gross": 114000.00, "gross_profit": 0.00, "is_cancelled": false, "credit_amount": 0.00, "currency_rate": 1.000000, "customer_name": null, "profit_margin": 0.00, "payment_method": "credit", "total_discount": 0.00, "logo_sync_status": "pending"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
eebada33-c2ff-417d-a7a7-0f787acc6410	rex_001_01_sales	698366f8-30d9-4bed-a4d7-bc142d07a1ba	INSERT	001	{"id": "698366f8-30d9-4bed-a4d7-bc142d07a1ba", "date": "2026-01-10T09:20:00+03:00", "notes": null, "status": "completed", "trcode": null, "cashier": null, "firm_nr": "001", "currency": "IQD", "fiche_no": "SAT-2026-0003", "store_id": null, "period_nr": "01", "total_net": 25000.00, "total_vat": 5000.00, "created_at": "2026-05-24T12:50:36.457566+03:00", "fiche_type": "S", "net_amount": 0.00, "total_cost": 0.00, "updated_at": "2026-05-24T12:50:36.457566+03:00", "customer_id": "4539a45d-229b-403a-bb72-8676047cf222", "document_no": null, "total_gross": 30000.00, "gross_profit": 0.00, "is_cancelled": false, "credit_amount": 0.00, "currency_rate": 1.000000, "customer_name": null, "profit_margin": 0.00, "payment_method": "cash", "total_discount": 0.00, "logo_sync_status": "pending"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
57c42e95-b39c-481d-95b3-369084eb9e7f	rex_001_01_sales	9de41dd8-1b48-4bc0-906b-63e5347c4f80	INSERT	001	{"id": "9de41dd8-1b48-4bc0-906b-63e5347c4f80", "date": "2026-01-12T16:00:00+03:00", "notes": null, "status": "completed", "trcode": null, "cashier": null, "firm_nr": "001", "currency": "IQD", "fiche_no": "SAT-2026-0004", "store_id": null, "period_nr": "01", "total_net": 1500.00, "total_vat": 150.00, "created_at": "2026-05-24T12:50:36.457566+03:00", "fiche_type": "S", "net_amount": 0.00, "total_cost": 0.00, "updated_at": "2026-05-24T12:50:36.457566+03:00", "customer_id": "8b69acbf-75a8-4c07-98ea-1abd9dffbdff", "document_no": null, "total_gross": 1650.00, "gross_profit": 0.00, "is_cancelled": false, "credit_amount": 0.00, "currency_rate": 1.000000, "customer_name": null, "profit_margin": 0.00, "payment_method": "cash", "total_discount": 0.00, "logo_sync_status": "pending"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
520242bb-2a89-47a2-b70e-90cd4674b324	rex_001_01_sales	bce41a6f-5ba4-4d9c-a168-9d6770ac0534	INSERT	001	{"id": "bce41a6f-5ba4-4d9c-a168-9d6770ac0534", "date": "2026-01-15T11:45:00+03:00", "notes": null, "status": "completed", "trcode": null, "cashier": null, "firm_nr": "001", "currency": "IQD", "fiche_no": "SAT-2026-0005", "store_id": null, "period_nr": "01", "total_net": 38000.00, "total_vat": 7600.00, "created_at": "2026-05-24T12:50:36.457566+03:00", "fiche_type": "S", "net_amount": 0.00, "total_cost": 0.00, "updated_at": "2026-05-24T12:50:36.457566+03:00", "customer_id": "3dee3608-a4b1-4b27-b569-e94f56dcb6ad", "document_no": null, "total_gross": 45600.00, "gross_profit": 0.00, "is_cancelled": false, "credit_amount": 0.00, "currency_rate": 1.000000, "customer_name": null, "profit_margin": 0.00, "payment_method": "credit", "total_discount": 0.00, "logo_sync_status": "pending"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
56f5fee4-3581-4c2f-b6d7-0a28237808bc	rex_001_01_sales	8ca7d561-d8c1-4176-bf77-2bf1468f012c	INSERT	001	{"id": "8ca7d561-d8c1-4176-bf77-2bf1468f012c", "date": "2026-01-18T13:30:00+03:00", "notes": null, "status": "completed", "trcode": null, "cashier": null, "firm_nr": "001", "currency": "USD", "fiche_no": "SAT-2026-0006", "store_id": null, "period_nr": "01", "total_net": 250.00, "total_vat": 50.00, "created_at": "2026-05-24T12:50:36.457566+03:00", "fiche_type": "S", "net_amount": 0.00, "total_cost": 0.00, "updated_at": "2026-05-24T12:50:36.457566+03:00", "customer_id": "93198df4-6949-48d0-b29b-34eeb8bb0931", "document_no": null, "total_gross": 300.00, "gross_profit": 0.00, "is_cancelled": false, "credit_amount": 0.00, "currency_rate": 1300.000000, "customer_name": null, "profit_margin": 0.00, "payment_method": "cash", "total_discount": 0.00, "logo_sync_status": "pending"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
0340894b-e14c-4d2b-99b6-ea2f308ae2cf	rex_001_01_sales	84f7c61b-562c-4b4f-b804-a85db9af44e8	INSERT	001	{"id": "84f7c61b-562c-4b4f-b804-a85db9af44e8", "date": "2026-01-03T09:00:00+03:00", "notes": "Telefon stoğu alımı", "status": "completed", "trcode": null, "cashier": null, "firm_nr": "001", "currency": "IQD", "fiche_no": "ALI-2026-0001", "store_id": null, "period_nr": "01", "total_net": 120000.00, "total_vat": 24000.00, "created_at": "2026-05-24T12:50:36.457566+03:00", "fiche_type": "A", "net_amount": 0.00, "total_cost": 0.00, "updated_at": "2026-05-24T12:50:36.457566+03:00", "customer_id": "0811050d-d8a2-487a-a2b4-c9aea21d656d", "document_no": null, "total_gross": 144000.00, "gross_profit": 0.00, "is_cancelled": false, "credit_amount": 0.00, "currency_rate": 1.000000, "customer_name": null, "profit_margin": 0.00, "payment_method": "credit", "total_discount": 0.00, "logo_sync_status": "pending"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
656cdfc9-9f2c-443e-b770-f1510a4b3c75	rex_001_01_sales	184909b0-b2d4-4eea-8b22-40d624e797bc	INSERT	001	{"id": "184909b0-b2d4-4eea-8b22-40d624e797bc", "date": "2026-01-06T11:00:00+03:00", "notes": "Atıştırmalık stoğu", "status": "completed", "trcode": null, "cashier": null, "firm_nr": "001", "currency": "IQD", "fiche_no": "ALI-2026-0002", "store_id": null, "period_nr": "01", "total_net": 8000.00, "total_vat": 800.00, "created_at": "2026-05-24T12:50:36.457566+03:00", "fiche_type": "A", "net_amount": 0.00, "total_cost": 0.00, "updated_at": "2026-05-24T12:50:36.457566+03:00", "customer_id": "104a593e-9ea7-4f47-a587-aad1268958f6", "document_no": null, "total_gross": 8800.00, "gross_profit": 0.00, "is_cancelled": false, "credit_amount": 0.00, "currency_rate": 1.000000, "customer_name": null, "profit_margin": 0.00, "payment_method": "cash", "total_discount": 0.00, "logo_sync_status": "pending"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
5d05b7a9-d492-4ae5-b125-049763985ea5	rex_001_01_sales	dde6a074-6a49-4f7a-b8f2-b2044f2e6c58	INSERT	001	{"id": "dde6a074-6a49-4f7a-b8f2-b2044f2e6c58", "date": "2026-01-08T10:30:00+03:00", "notes": "İçecek stoğu USD", "status": "completed", "trcode": null, "cashier": null, "firm_nr": "001", "currency": "USD", "fiche_no": "ALI-2026-0003", "store_id": null, "period_nr": "01", "total_net": 4000.00, "total_vat": 400.00, "created_at": "2026-05-24T12:50:36.457566+03:00", "fiche_type": "A", "net_amount": 0.00, "total_cost": 0.00, "updated_at": "2026-05-24T12:50:36.457566+03:00", "customer_id": "1481acd1-b545-4d76-ba3d-efde68b3c959", "document_no": null, "total_gross": 4400.00, "gross_profit": 0.00, "is_cancelled": false, "credit_amount": 0.00, "currency_rate": 1300.000000, "customer_name": null, "profit_margin": 0.00, "payment_method": "credit", "total_discount": 0.00, "logo_sync_status": "pending"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
52e42f50-6f39-430e-95dd-752677e6c1aa	rex_001_01_cash_lines	7b4c4b72-eaa9-4a01-b73c-91cbe3e832dc	INSERT	001	{"id": "7b4c4b72-eaa9-4a01-b73c-91cbe3e832dc", "date": "2026-01-05T11:00:00+03:00", "sign": 1, "amount": 54000.00, "trcode": 11, "bank_id": null, "firm_nr": "001", "f_amount": 0.00, "fiche_no": "KAS-2026-0001", "tax_rate": 0.00, "period_nr": "01", "created_at": "2026-05-24T12:50:36.457566+03:00", "definition": "iPhone 15 Pro Satış Tahsilatı", "customer_id": null, "register_id": null, "special_code": null, "currency_code": "IQD", "exchange_rate": 1.000000, "bank_account_id": null, "expense_card_id": null, "transfer_status": 0, "transaction_type": "sales_payment", "target_register_id": null, "withholding_tax_rate": 0.00}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
a0e24bd7-7e7d-4e0a-9e87-67deedf924fe	rex_001_01_cash_lines	f5beec03-f4a6-4142-b48a-2e5275cf5eca	INSERT	001	{"id": "f5beec03-f4a6-4142-b48a-2e5275cf5eca", "date": "2026-01-07T15:00:00+03:00", "sign": 1, "amount": 114000.00, "trcode": 11, "bank_id": null, "firm_nr": "001", "f_amount": 0.00, "fiche_no": "KAS-2026-0002", "tax_rate": 0.00, "period_nr": "01", "created_at": "2026-05-24T12:50:36.457566+03:00", "definition": "MacBook Pro Satış Tahsilatı", "customer_id": null, "register_id": null, "special_code": null, "currency_code": "IQD", "exchange_rate": 1.000000, "bank_account_id": null, "expense_card_id": null, "transfer_status": 0, "transaction_type": "sales_payment", "target_register_id": null, "withholding_tax_rate": 0.00}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
a77708b6-3bf3-49a1-8e95-fe82eb0654ba	rex_001_01_cash_lines	45564c38-3adb-4810-bd5c-af1ce492110c	INSERT	001	{"id": "45564c38-3adb-4810-bd5c-af1ce492110c", "date": "2026-01-10T10:00:00+03:00", "sign": 1, "amount": 30000.00, "trcode": 11, "bank_id": null, "firm_nr": "001", "f_amount": 0.00, "fiche_no": "KAS-2026-0003", "tax_rate": 0.00, "period_nr": "01", "created_at": "2026-05-24T12:50:36.457566+03:00", "definition": "Telefon Satış Tahsilatı", "customer_id": null, "register_id": null, "special_code": null, "currency_code": "IQD", "exchange_rate": 1.000000, "bank_account_id": null, "expense_card_id": null, "transfer_status": 0, "transaction_type": "sales_payment", "target_register_id": null, "withholding_tax_rate": 0.00}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
ba4766af-93b7-4dfc-a828-676ef757a5c6	rex_001_01_cash_lines	46077eb4-7ee1-4c10-8f5d-e1537795d57d	INSERT	001	{"id": "46077eb4-7ee1-4c10-8f5d-e1537795d57d", "date": "2026-01-12T09:00:00+03:00", "sign": -1, "amount": -8800.00, "trcode": 12, "bank_id": null, "firm_nr": "001", "f_amount": 0.00, "fiche_no": "KAS-2026-0004", "tax_rate": 0.00, "period_nr": "01", "created_at": "2026-05-24T12:50:36.457566+03:00", "definition": "Gıda Tedarik Ödemesi", "customer_id": null, "register_id": null, "special_code": null, "currency_code": "IQD", "exchange_rate": 1.000000, "bank_account_id": null, "expense_card_id": null, "transfer_status": 0, "transaction_type": "purchase_payment", "target_register_id": null, "withholding_tax_rate": 0.00}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
ffe04d2c-aec4-43db-887f-8c560993a775	rex_001_01_cash_lines	f466f04f-195c-4744-afcc-fac01ad64997	INSERT	001	{"id": "f466f04f-195c-4744-afcc-fac01ad64997", "date": "2026-01-15T09:30:00+03:00", "sign": -1, "amount": -5000.00, "trcode": 12, "bank_id": null, "firm_nr": "001", "f_amount": 0.00, "fiche_no": "KAS-2026-0005", "tax_rate": 0.00, "period_nr": "01", "created_at": "2026-05-24T12:50:36.457566+03:00", "definition": "Kira Ödemesi — Ocak", "customer_id": null, "register_id": null, "special_code": null, "currency_code": "IQD", "exchange_rate": 1.000000, "bank_account_id": null, "expense_card_id": null, "transfer_status": 0, "transaction_type": "expense", "target_register_id": null, "withholding_tax_rate": 0.00}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
d9330312-a750-44c0-bee3-ba617340106d	rex_001_01_cash_lines	2d8250fd-83d6-4fcf-9012-af9f1321d5e4	INSERT	001	{"id": "2d8250fd-83d6-4fcf-9012-af9f1321d5e4", "date": "2026-01-20T10:00:00+03:00", "sign": -1, "amount": -2500.00, "trcode": 12, "bank_id": null, "firm_nr": "001", "f_amount": 0.00, "fiche_no": "KAS-2026-0006", "tax_rate": 0.00, "period_nr": "01", "created_at": "2026-05-24T12:50:36.457566+03:00", "definition": "Elektrik Faturası", "customer_id": null, "register_id": null, "special_code": null, "currency_code": "IQD", "exchange_rate": 1.000000, "bank_account_id": null, "expense_card_id": null, "transfer_status": 0, "transaction_type": "expense", "target_register_id": null, "withholding_tax_rate": 0.00}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
16cf8814-3869-4c0a-b41b-453c35b7ec5d	rex_001_01_cash_lines	db1a4278-60fe-4f41-9522-67d0eb0d45f0	INSERT	001	{"id": "db1a4278-60fe-4f41-9522-67d0eb0d45f0", "date": "2026-02-01T09:00:00+03:00", "sign": 1, "amount": 45600.00, "trcode": 11, "bank_id": null, "firm_nr": "001", "f_amount": 0.00, "fiche_no": "KAS-2026-0007", "tax_rate": 0.00, "period_nr": "01", "created_at": "2026-05-24T12:50:36.457566+03:00", "definition": "Samsung Galaxy Satış Tahsilatı", "customer_id": null, "register_id": null, "special_code": null, "currency_code": "IQD", "exchange_rate": 1.000000, "bank_account_id": null, "expense_card_id": null, "transfer_status": 0, "transaction_type": "sales_payment", "target_register_id": null, "withholding_tax_rate": 0.00}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
30196a66-18c4-4553-84b5-89a9362f4cbb	rex_001_01_cash_lines	fd6080aa-12d2-4167-a294-5cf94e3ba67f	INSERT	001	{"id": "fd6080aa-12d2-4167-a294-5cf94e3ba67f", "date": "2026-02-05T14:00:00+03:00", "sign": 1, "amount": 390000.00, "trcode": 11, "bank_id": null, "firm_nr": "001", "f_amount": 0.00, "fiche_no": "KAS-2026-0008", "tax_rate": 0.00, "period_nr": "01", "created_at": "2026-05-24T12:50:36.457566+03:00", "definition": "USD Fatura Tahsilatı (IQD)", "customer_id": null, "register_id": null, "special_code": null, "currency_code": "IQD", "exchange_rate": 1.000000, "bank_account_id": null, "expense_card_id": null, "transfer_status": 0, "transaction_type": "sales_payment", "target_register_id": null, "withholding_tax_rate": 0.00}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
ef511ba4-67a5-4550-abde-e752d187c988	rex_001_products	e357f3d5-44fe-4523-b614-3ac5098a3a39	UPDATE	001	{"id": "e357f3d5-44fe-4523-b614-3ac5098a3a39", "code": "PHONE-003", "cost": 19000.00, "name": "Xiaomi 14 Pro", "unit": "Adet", "brand": null, "model": null, "name2": "256GB Beyaz", "price": 25000.00, "stock": 29.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": "8680000000003", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 20.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 5.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "1eb458d5-8307-444c-85fe-b4da7898a934", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:26.615621+03
4a93aea2-93e8-4fbd-8328-dac03568a927	rex_001_products	af831dbf-90ef-47e0-9e9a-d9d41470355e	UPDATE	001	{"id": "af831dbf-90ef-47e0-9e9a-d9d41470355e", "code": "PHONE-001", "cost": 35000.00, "name": "iPhone 15 Pro", "unit": "Adet", "brand": null, "model": null, "name2": "256GB Titanyum", "price": 45000.00, "stock": 17.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": "8680000000001", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 20.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 3.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "1eb458d5-8307-444c-85fe-b4da7898a934", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:25.937818+03
9cb0ebb6-6137-4a7e-b564-bb79d75418e7	rex_001_products	8cc29e25-143b-40ec-a37f-45c0a0291b92	UPDATE	001	{"id": "8cc29e25-143b-40ec-a37f-45c0a0291b92", "code": "PC-001", "cost": 75000.00, "name": "MacBook Pro 16\\"", "unit": "Adet", "brand": null, "model": null, "name2": "M3 Max 64GB", "price": 95000.00, "stock": 7.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": "8680000000010", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 20.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 2.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "ee4d6cda-6564-422d-b551-a85fd40db97f", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:26.142239+03
b6eaa459-8deb-46a3-9500-f350bcebf985	rex_001_customers	2dc07a6f-0f2b-420b-8837-5a7e65acdba7	INSERT	001	{"id": "2dc07a6f-0f2b-420b-8837-5a7e65acdba7", "age": null, "city": null, "code": "BCust-001", "name": "Lena Al-Rashidi", "email": "lena@mail.com", "notes": null, "phone": "+964 770 400 0001", "gender": null, "phone2": null, "points": 0.00, "tax_nr": null, "address": null, "balance": 0.00, "file_id": null, "firm_nr": "001", "taxi_nr": null, "district": null, "is_active": true, "created_at": "2026-05-24T12:50:36.457566+03:00", "heard_from": null, "occupation": null, "tax_office": null, "total_spent": 0.00, "neighborhood": null, "customer_tier": "normal"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
10910beb-3d57-4c89-ab0d-2c1cc8ffe848	rex_001_customers	a273f014-47b6-4a4a-82f4-e38bb02b7353	INSERT	001	{"id": "a273f014-47b6-4a4a-82f4-e38bb02b7353", "age": null, "city": null, "code": "BCust-002", "name": "Maya Hassan", "email": "maya@mail.com", "notes": null, "phone": "+964 770 400 0002", "gender": null, "phone2": null, "points": 0.00, "tax_nr": null, "address": null, "balance": 0.00, "file_id": null, "firm_nr": "001", "taxi_nr": null, "district": null, "is_active": true, "created_at": "2026-05-24T12:50:36.457566+03:00", "heard_from": null, "occupation": null, "tax_office": null, "total_spent": 0.00, "neighborhood": null, "customer_tier": "normal"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
72e693cb-8156-4bce-8e50-0b20ab3c6083	rex_001_customers	d00bc030-5e82-4004-91fc-134ee5da1c1c	INSERT	001	{"id": "d00bc030-5e82-4004-91fc-134ee5da1c1c", "age": null, "city": null, "code": "BCust-003", "name": "Sara Karim", "email": "sara.k@mail.com", "notes": null, "phone": "+964 770 400 0003", "gender": null, "phone2": null, "points": 0.00, "tax_nr": null, "address": null, "balance": 0.00, "file_id": null, "firm_nr": "001", "taxi_nr": null, "district": null, "is_active": true, "created_at": "2026-05-24T12:50:36.457566+03:00", "heard_from": null, "occupation": null, "tax_office": null, "total_spent": 0.00, "neighborhood": null, "customer_tier": "normal"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:36.457566+03
4a5bad68-f9f9-482a-b129-697b26fbad4d	rex_001_tax_rates	07e71644-275b-4230-b7f7-e9f50e645eba	INSERT	001	{"id": "07e71644-275b-4230-b7f7-e9f50e645eba", "rate": 0.00, "is_active": true, "created_at": "2026-05-24T12:50:37.037061+03:00", "description": "Vergisiz"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:37.037061+03
7b02fb9c-bb06-43b4-96e5-405eb07113ca	rex_001_tax_rates	73fc8257-b17a-4346-b60b-27dfee2fc26c	INSERT	001	{"id": "73fc8257-b17a-4346-b60b-27dfee2fc26c", "rate": 1.00, "is_active": true, "created_at": "2026-05-24T12:50:37.037061+03:00", "description": "%1 KDV"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:37.037061+03
1af47328-94fe-4065-9e62-ed3d1a86b68e	rex_001_tax_rates	8ea1d758-770a-48d5-ba3a-dce168571789	INSERT	001	{"id": "8ea1d758-770a-48d5-ba3a-dce168571789", "rate": 8.00, "is_active": true, "created_at": "2026-05-24T12:50:37.037061+03:00", "description": "%8 KDV"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:37.037061+03
81dd4158-ab1c-4779-a35d-9c48c9a8857b	rex_001_tax_rates	ca4fe41b-f11a-455f-95f7-cbba08754663	INSERT	001	{"id": "ca4fe41b-f11a-455f-95f7-cbba08754663", "rate": 10.00, "is_active": true, "created_at": "2026-05-24T12:50:37.037061+03:00", "description": "%10 KDV"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:37.037061+03
2d2ddae7-c285-4942-8da3-effa30a00652	rex_001_tax_rates	98d257ff-ffdf-408a-919b-a8988050e7a0	INSERT	001	{"id": "98d257ff-ffdf-408a-919b-a8988050e7a0", "rate": 18.00, "is_active": true, "created_at": "2026-05-24T12:50:37.037061+03:00", "description": "%18 KDV"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:37.037061+03
8afb6da0-502e-4fef-86ce-7ee9464cc91a	rex_001_tax_rates	beb18927-372d-44a2-ab1b-dc59103f8e8c	INSERT	001	{"id": "beb18927-372d-44a2-ab1b-dc59103f8e8c", "rate": 20.00, "is_active": true, "created_at": "2026-05-24T12:50:37.037061+03:00", "description": "%20 KDV"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:50:37.037061+03
1b450bc5-180f-4bac-b1ec-0bb9fb09207b	rex_001_01_sales	9e141119-822f-447c-a6e7-72a3f67362b9	INSERT	001	{"id": "9e141119-822f-447c-a6e7-72a3f67362b9", "date": "2026-05-24T12:52:01.198+03:00", "notes": "RestoranPOS|rest_order_id:44e147d8-1025-4599-8266-b2935b22af64", "status": "approved", "trcode": 7, "cashier": "admin", "firm_nr": "001", "currency": "IQD", "fiche_no": "REST-1-1779616320536", "store_id": null, "period_nr": "01", "total_net": 50.00, "total_vat": 0.00, "created_at": "2026-05-24T12:52:01.215573+03:00", "fiche_type": "sales_invoice", "net_amount": 50.00, "total_cost": 0.00, "updated_at": "2026-05-24T12:52:01.215573+03:00", "customer_id": null, "document_no": "REST-1-1779616320536", "total_gross": 0.00, "gross_profit": 50.00, "is_cancelled": false, "credit_amount": 0.00, "currency_rate": 1.000000, "customer_name": "Peşin Müşteri", "profit_margin": 100.00, "payment_method": "cash", "total_discount": 0.00, "logo_sync_status": "pending"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:52:01.215573+03
c1cd872e-7972-4b2c-ae75-2be9f8f3df46	rex_001_01_cash_lines	b10ac7c5-e715-49d9-928e-01a94539c493	INSERT	001	{"id": "b10ac7c5-e715-49d9-928e-01a94539c493", "date": "2026-05-24T00:00:00+03:00", "sign": 1, "amount": 50.00, "trcode": null, "bank_id": null, "firm_nr": "001", "f_amount": 0.00, "fiche_no": "REST-1-1779616320536", "tax_rate": 0.00, "period_nr": "01", "created_at": "2026-05-24T12:52:01.480696+03:00", "definition": "Market Satışı - REST-1-1779616320536", "customer_id": null, "register_id": "00000000-0000-0000-0000-000000000001", "special_code": "", "currency_code": "YEREL", "exchange_rate": 1.000000, "bank_account_id": null, "expense_card_id": null, "transfer_status": 0, "transaction_type": "KASA_GIRIS", "target_register_id": null, "withholding_tax_rate": 0.00}	pending	\N	RetailEX	\N	0	\N	2026-05-24 12:52:01.480696+03
ce7f40ad-c079-4b5e-be2d-c624265b96ff	rex_001_products	caa15694-d8fc-48d4-9e91-bcf31bd5cba1	INSERT	001	{"id": "caa15694-d8fc-48d4-9e91-bcf31bd5cba1", "code": "10023", "cost": 250.00, "name": "SU", "unit": "ADET", "brand": "", "model": "", "name2": null, "price": 0.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10023", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 0.00, "min_stock": 0.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:25.540005+03:00", "group_code": "GRP-06", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:25.540005+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "İÇECEKLER", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:25.540005+03
a7829625-6a4d-4dee-bde7-be81088a2728	rex_001_products	3a28e755-8755-4c5a-88ee-283b4aaa6dd4	UPDATE	001	{"id": "3a28e755-8755-4c5a-88ee-283b4aaa6dd4", "code": "SNACK-001", "cost": 10.00, "name": "Çikolata Bar", "unit": "Adet", "brand": null, "model": null, "name2": "Sütlü 80g", "price": 15.00, "stock": 502.00, "unit2": null, "unit3": null, "origin": null, "ref_id": null, "barcode": "8680000000020", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": null, "tax_type": null, "vat_rate": 10.00, "groupCode": null, "groupcode": null, "image_url": null, "is_active": false, "max_stock": 0.00, "min_stock": 50.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T12:50:36.457566+03:00", "group_code": null, "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": "52d0858a-01fd-4b65-800a-2b65b9b60a57", "updated_at": "2026-05-24T12:50:36.457566+03:00", "category_id": "432eaefc-f2ef-4df3-abd7-c6d50d646813", "description": null, "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": null, "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": null, "image_url_cdn": null, "material_type": null, "tracking_type": "none", "critical_stock": 0.00, "description_ar": null, "description_en": null, "description_ku": null, "description_tr": null, "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": null, "special_code_2": null, "special_code_3": null, "special_code_4": null, "special_code_5": null, "special_code_6": null, "sub_group_code": null, "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:51:25.611186+03
0c381508-303a-487f-9574-8ed25fe3010b	rex_001_categories	a709336b-b4bb-4b5d-bd7f-c77e79f62423	INSERT	001	{"id": "a709336b-b4bb-4b5d-bd7f-c77e79f62423", "code": "ATIŞTIRMALIK", "icon": null, "name": "ATIŞTIRMALIK", "is_active": true, "parent_id": null, "created_at": "2026-05-24T14:54:24.126078+03:00", "description": "", "is_restaurant": false}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:24.126078+03
96e40128-92cd-42c7-ad96-a7c97c513e69	rex_001_categories	c3f2b98a-d6d3-4e2e-98fb-a47ff487c674	INSERT	001	{"id": "c3f2b98a-d6d3-4e2e-98fb-a47ff487c674", "code": "ÇORBALAR", "icon": null, "name": "ÇORBALAR", "is_active": true, "parent_id": null, "created_at": "2026-05-24T14:54:24.147571+03:00", "description": "", "is_restaurant": false}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:24.147571+03
1db7c33e-bfdb-4f5f-bf4d-148000a730da	rex_001_categories	c12dbd8c-34a0-4dbd-8c8c-a3ae3473d505	INSERT	001	{"id": "c12dbd8c-34a0-4dbd-8c8c-a3ae3473d505", "code": "TATLILAR", "icon": null, "name": "TATLILAR", "is_active": true, "parent_id": null, "created_at": "2026-05-24T14:54:24.160708+03:00", "description": "", "is_restaurant": false}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:24.160708+03
df77f38e-a102-4864-b69a-4eafa3e33988	rex_001_categories	fda65768-47c0-46c2-b513-f9ac226eff7e	INSERT	001	{"id": "fda65768-47c0-46c2-b513-f9ac226eff7e", "code": "SALATALAR", "icon": null, "name": "SALATALAR", "is_active": true, "parent_id": null, "created_at": "2026-05-24T14:54:24.171843+03:00", "description": "", "is_restaurant": false}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:24.171843+03
90416c8f-0f79-4766-bf3b-673193fa0960	rex_001_products	f99e364d-f6f9-48aa-b360-91903d95ee3c	INSERT	001	{"id": "f99e364d-f6f9-48aa-b360-91903d95ee3c", "code": "10001", "cost": 15320.00, "name": "ÖZBEK PİLAVI", "unit": "PRS", "brand": "", "model": "", "name2": null, "price": 21750.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10001", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 200.00, "min_stock": 5.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:24.28614+03:00", "group_code": "GRP-01", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:24.28614+03:00", "category_id": null, "description": "Kuzu eti 250gr, bitkisel ve zeytin yağı, pirinç, havuş soğan, sarımsak, baharatlar", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "ANA YEMEKLER", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:24.28614+03
0167a2a1-ae5b-4251-84a2-e4f53dfd3b23	rex_001_products	09ae7aca-b96f-426c-ac82-ce13fa35b70a	INSERT	001	{"id": "09ae7aca-b96f-426c-ac82-ce13fa35b70a", "code": "10002", "cost": 11580.00, "name": "KIYMALI ŞİŞ KEBAP", "unit": "PRS", "brand": "", "model": "", "name2": null, "price": 12750.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10002", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 50.00, "min_stock": 5.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:24.359462+03:00", "group_code": "GRP-01", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:24.359462+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "ANA YEMEKLER", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:24.359462+03
17c466d5-ebbb-4229-b1b0-47da725ab2a5	rex_001_products	46e792bb-1fa6-4e6c-b088-e21ef0d60a2b	INSERT	001	{"id": "46e792bb-1fa6-4e6c-b088-e21ef0d60a2b", "code": "10003", "cost": 7500.00, "name": "KUZU ŞİŞ KEBAP", "unit": "PRS", "brand": "", "model": "", "name2": null, "price": 12500.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10003", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 50.00, "min_stock": 5.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:24.414748+03:00", "group_code": "GRP-01", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:24.414748+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "ANA YEMEKLER", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:24.414748+03
96436482-3bd6-42bf-aa1e-5a43dd27ab1e	rex_001_products	85b37927-e719-43af-b0b2-117bdf7e84d3	INSERT	001	{"id": "85b37927-e719-43af-b0b2-117bdf7e84d3", "code": "10004", "cost": 8000.00, "name": "ÖZBEK MANTI BUHARDA", "unit": "PRS", "brand": "", "model": "", "name2": null, "price": 13500.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10004", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 200.00, "min_stock": 50.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:24.468294+03:00", "group_code": "GRP-01", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:24.468294+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "ANA YEMEKLER", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:24.468294+03
6f2d5f1a-0a4c-4f21-b031-da7b3e58ba9b	rex_001_products	ac28849b-cb73-4acf-a2e9-dacfabc5cca2	INSERT	001	{"id": "ac28849b-cb73-4acf-a2e9-dacfabc5cca2", "code": "10005", "cost": 8000.00, "name": "ÖZBEK MANTI HAŞLAMA", "unit": "PRS", "brand": "", "model": "", "name2": null, "price": 13500.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10005", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 200.00, "min_stock": 50.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:24.531084+03:00", "group_code": "GRP-01", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:24.531084+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "ANA YEMEKLER", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:24.531084+03
2fbbc28b-94a0-4d09-8651-be88dca06252	rex_001_products	62e97a61-8d31-47f1-833c-28ca73136f52	INSERT	001	{"id": "62e97a61-8d31-47f1-833c-28ca73136f52", "code": "10006", "cost": 2000.00, "name": "ÇİG BOREK KIYMALI", "unit": "PRS", "brand": "", "model": "", "name2": null, "price": 3750.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10006", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 100.00, "min_stock": 20.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:24.594533+03:00", "group_code": "GRP-02", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:24.594533+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "ATIŞTIRMALIK", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:24.594533+03
891bd4d0-7472-4d7c-8541-d0c1d0c48947	rex_001_products	71f14427-2a09-490f-8570-0a35e1b70d70	INSERT	001	{"id": "71f14427-2a09-490f-8570-0a35e1b70d70", "code": "10007", "cost": 1200.00, "name": "ÇIG BOREK PEYNIRLI", "unit": "PRS", "brand": "", "model": "", "name2": null, "price": 3000.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10007", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 100.00, "min_stock": 20.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:24.650628+03:00", "group_code": "GRP-02", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:24.650628+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "ATIŞTIRMALIK", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:24.650628+03
8e987b6a-c9d6-4736-937f-e6afb14723d7	rex_001_products	6cf645c9-4d56-40c1-ba3f-0d0446a70f29	INSERT	001	{"id": "6cf645c9-4d56-40c1-ba3f-0d0446a70f29", "code": "10008", "cost": 4000.00, "name": "SAMSA", "unit": "PRS", "brand": "", "model": "", "name2": null, "price": 5750.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10008", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 100.00, "min_stock": 20.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:24.69964+03:00", "group_code": "GRP-02", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:24.69964+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "ATIŞTIRMALIK", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:24.69964+03
02bfb318-a237-479b-b392-e214d84b32ba	rex_001_products	4adb6a25-1f98-40b2-9a63-931b5fce3fed	INSERT	001	{"id": "4adb6a25-1f98-40b2-9a63-931b5fce3fed", "code": "10009", "cost": 5000.00, "name": "ÖZBEK ÇORBA", "unit": "PRS", "brand": "", "model": "", "name2": null, "price": 7000.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10009", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 100.00, "min_stock": 20.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:24.761552+03:00", "group_code": "GRP-03", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:24.761552+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "ÇORBALAR", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:24.761552+03
ef5ebd5a-c2fb-42b8-8433-085f11972d24	rex_001_products	b3b213bd-6bec-40a0-a878-fcabab723613	INSERT	001	{"id": "b3b213bd-6bec-40a0-a878-fcabab723613", "code": "10010", "cost": 4000.00, "name": "KEK MEDOVİK", "unit": "PRS", "brand": "", "model": "", "name2": null, "price": 6500.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10010", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 100.00, "min_stock": 20.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:24.846819+03:00", "group_code": "GRP-04", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:24.846819+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "TATLILAR", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:24.846819+03
ac0856bd-7feb-4e04-95ad-dcefcf6849da	rex_001_products	d24a1aae-6aec-4b44-abe8-8905d21e82c2	INSERT	001	{"id": "d24a1aae-6aec-4b44-abe8-8905d21e82c2", "code": "10011", "cost": 2400.00, "name": "NAPOLEON", "unit": "PRS", "brand": "", "model": "", "name2": null, "price": 5000.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10011", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 100.00, "min_stock": 20.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:24.901322+03:00", "group_code": "GRP-04", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:24.901322+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "TATLILAR", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:24.901322+03
8e13bf49-b1fb-4e53-b122-ffee52668d5f	rex_001_products	d51d18ef-2fd5-4ade-87b8-6a7eeed132b0	INSERT	001	{"id": "d51d18ef-2fd5-4ade-87b8-6a7eeed132b0", "code": "10012", "cost": 2800.00, "name": "CHEESE CAKE", "unit": "PRS", "brand": "", "model": "", "name2": null, "price": 5750.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10012", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 100.00, "min_stock": 20.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:24.948927+03:00", "group_code": "GRP-04", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:24.948927+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "TATLILAR", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:24.948927+03
ae6a90b1-9737-4626-894a-57acd65e4271	rex_001_products	1ea8c2df-9ea0-42f0-8ab1-5c800a21e9d4	INSERT	001	{"id": "1ea8c2df-9ea0-42f0-8ab1-5c800a21e9d4", "code": "10013", "cost": 4500.00, "name": "ÖZBEK BAKLAVA", "unit": "PRS", "brand": "", "model": "", "name2": null, "price": 9000.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10013", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 100.00, "min_stock": 20.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:25.01531+03:00", "group_code": "GRP-04", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:25.01531+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "TATLILAR", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:25.01531+03
4ea6b185-7e14-407c-b971-be8e94db5ded	rex_001_products	43ae2ed7-6083-4630-9894-a559765c923b	INSERT	001	{"id": "43ae2ed7-6083-4630-9894-a559765c923b", "code": "10014", "cost": 1200.00, "name": "HAVUÇ SALATASI", "unit": "PRS", "brand": "", "model": "", "name2": null, "price": 3000.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10014", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 10.00, "min_stock": 10.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:25.068949+03:00", "group_code": "GRP-05", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:25.068949+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "SALATALAR", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:25.068949+03
8943a96c-5565-49a9-b8f6-c66d3473bb1c	rex_001_products	a750fb1a-1859-4d7b-a5f6-4320a139c289	INSERT	001	{"id": "a750fb1a-1859-4d7b-a5f6-4320a139c289", "code": "10015", "cost": 1500.00, "name": "DOMATES SALATASI )DOMATES SOĞAN MAYDANOZ)", "unit": "PRS", "brand": "", "model": "", "name2": null, "price": 3750.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10015", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 10.00, "min_stock": 10.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:25.119078+03:00", "group_code": "GRP-05", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:25.119078+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "SALATALAR", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:25.119078+03
25f27dd0-2923-4a90-8ce1-a1ca9e64db49	rex_001_products	928c2ae5-39d1-4d78-8451-1ce406e6465a	INSERT	001	{"id": "928c2ae5-39d1-4d78-8451-1ce406e6465a", "code": "10016", "cost": 1250.00, "name": "LAHANA SALATASI", "unit": "PRS", "brand": "", "model": "", "name2": null, "price": 3500.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10016", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 10.00, "min_stock": 10.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:25.163583+03:00", "group_code": "GRP-05", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:25.163583+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "SALATALAR", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:25.163583+03
011be55c-8d7a-4c5d-95da-9060d7f99e21	rex_001_products	dbb3d194-dc5a-44e6-91e1-2f019e7f1456	INSERT	001	{"id": "dbb3d194-dc5a-44e6-91e1-2f019e7f1456", "code": "10018", "cost": 2000.00, "name": "PEPSI COLA", "unit": "ADET", "brand": "", "model": "", "name2": null, "price": 2500.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10018", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 0.00, "min_stock": 0.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:25.280115+03:00", "group_code": "GRP-06", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:25.280115+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "İÇECEKLER", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:25.280115+03
273be74f-be32-452a-9687-34e8f8788255	rex_001_products	715466c5-b115-45b3-b721-0637b0046a89	INSERT	001	{"id": "715466c5-b115-45b3-b721-0637b0046a89", "code": "10019", "cost": 2000.00, "name": "PEPSI COLA ZERO", "unit": "ADET", "brand": "", "model": "", "name2": null, "price": 2500.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10019", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 0.00, "min_stock": 0.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:25.333099+03:00", "group_code": "GRP-06", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:25.333099+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "İÇECEKLER", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:25.333099+03
283287dd-eaf4-4d16-9be5-b7cbb8a6f1f0	rex_001_products	54f5a0c9-4af3-4268-bb51-c4c7fc8c546d	INSERT	001	{"id": "54f5a0c9-4af3-4268-bb51-c4c7fc8c546d", "code": "10020", "cost": 2000.00, "name": "MIRANDA", "unit": "ADET", "brand": "", "model": "", "name2": null, "price": 2500.00, "stock": 0.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10020", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 0.00, "min_stock": 0.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:25.379773+03:00", "group_code": "GRP-06", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:25.379773+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "İÇECEKLER", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 14:54:25.379773+03
5a989235-83ff-48ec-bf0d-7b211ed3fac3	rex_001_products	2db1e771-61d8-46af-a6b9-5b23fe9a0ea5	UPDATE	001	{"id": "2db1e771-61d8-46af-a6b9-5b23fe9a0ea5", "code": "10021", "cost": 2000.00, "name": "7UP TENEKE", "unit": "ADET", "brand": "", "model": "", "name2": null, "price": 2500.00, "stock": -1.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10021", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 0.00, "min_stock": 0.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:25.433906+03:00", "group_code": "GRP-06", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:25.433906+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "İÇECEKLER", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 16:25:59.041424+03
c2b46c08-9eee-4dd1-981d-177c3d77c1c6	rex_001_01_sales	72989e74-0d4c-4719-9f26-f354232eb5ad	INSERT	001	{"id": "72989e74-0d4c-4719-9f26-f354232eb5ad", "date": "2026-05-24T16:25:58.805+03:00", "notes": "RestoranPOS|rest_order_id:01dec24f-ad0b-475d-98ea-42788f9e6727", "status": "approved", "trcode": 7, "cashier": "admin", "firm_nr": "001", "currency": "IQD", "fiche_no": "REST-1-1779629158255", "store_id": null, "period_nr": "01", "total_net": 8580.00, "total_vat": 0.00, "created_at": "2026-05-24T16:25:58.813159+03:00", "fiche_type": "sales_invoice", "net_amount": 8580.00, "total_cost": 0.00, "updated_at": "2026-05-24T16:25:58.813159+03:00", "customer_id": null, "document_no": "REST-1-1779629158255", "total_gross": 0.00, "gross_profit": 8580.00, "is_cancelled": false, "credit_amount": 0.00, "currency_rate": 1.000000, "customer_name": "Peşin Müşteri", "profit_margin": 100.00, "payment_method": "cash", "total_discount": 0.00, "logo_sync_status": "pending"}	pending	\N	RetailEX	\N	0	\N	2026-05-24 16:25:58.813159+03
f4fd3475-d30e-4c76-bf34-50f75318fc5c	rex_001_products	102e4899-2368-4831-88ff-519515314eb1	UPDATE	001	{"id": "102e4899-2368-4831-88ff-519515314eb1", "code": "10017", "cost": 1500.00, "name": "KARIŞIK SALATA (DOMATES SALATALIK)", "unit": "PRS", "brand": "", "model": "", "name2": null, "price": 3750.00, "stock": -1.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10017", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 10.00, "min_stock": 10.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:25.222159+03:00", "group_code": "GRP-05", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:25.222159+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "SALATALAR", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 16:25:58.961654+03
630568f2-d616-4f42-ae9d-46b07e20eccf	rex_001_products	a012f83b-d3f3-4435-8f40-46f9ea7541a7	UPDATE	001	{"id": "a012f83b-d3f3-4435-8f40-46f9ea7541a7", "code": "10025", "cost": 250.00, "name": "KAHVE", "unit": "ADET", "brand": "", "model": "", "name2": null, "price": 0.00, "stock": -1.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10025", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 0.00, "min_stock": 0.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:25.644576+03:00", "group_code": "GRP-06", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:25.644576+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "İÇECEKLER", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 16:25:59.029849+03
fa0bac2e-521a-408b-b97e-ab1275f3ce0a	rex_001_products	0230b49e-da04-4c01-8376-dcf39efcc266	UPDATE	001	{"id": "0230b49e-da04-4c01-8376-dcf39efcc266", "code": "10022", "cost": 1000.00, "name": "AYRAN BARDAK", "unit": "ADET", "brand": "", "model": "", "name2": null, "price": 1500.00, "stock": -1.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10022", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 0.00, "min_stock": 0.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:25.487107+03:00", "group_code": "GRP-06", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:25.487107+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "İÇECEKLER", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 16:25:59.047563+03
62aa9863-8f32-4313-b0ae-f099932ec42e	rex_001_products	6d2ba86e-cd03-436b-863d-791de70a281f	UPDATE	001	{"id": "6d2ba86e-cd03-436b-863d-791de70a281f", "code": "10024", "cost": 250.00, "name": "ÇAY", "unit": "ADET", "brand": "", "model": "", "name2": null, "price": 0.00, "stock": -1.00, "unit2": "", "unit3": "", "origin": "", "ref_id": null, "barcode": "10024", "firm_nr": "001", "unit_id": null, "vatRate": 20.00, "vatrate": 20.00, "currency": "IQD", "supplier": "", "tax_type": null, "vat_rate": 18.00, "groupCode": null, "groupcode": null, "image_url": "", "is_active": true, "max_stock": 0.00, "min_stock": 0.00, "unitsetId": null, "unitsetid": null, "created_at": "2026-05-24T14:54:25.591681+03:00", "group_code": "GRP-06", "pricelist1": null, "pricelist2": null, "pricelist3": null, "pricelist4": null, "pricelist5": null, "pricelist6": null, "unitset_id": null, "updated_at": "2026-05-24T14:54:25.591681+03:00", "category_id": null, "description": "", "hasVariants": false, "hasvariants": false, "categoryCode": null, "categorycode": null, "has_variants": false, "manufacturer": "", "materialType": null, "materialtype": null, "price_list_1": 0.00, "price_list_2": 0.00, "price_list_3": 0.00, "price_list_4": 0.00, "price_list_5": 0.00, "price_list_6": 0.00, "specialcode1": null, "specialcode2": null, "specialcode3": null, "specialcode4": null, "specialcode5": null, "specialcode6": null, "subGroupCode": null, "subgroupcode": null, "category_code": "İÇECEKLER", "image_url_cdn": "", "material_type": "commercial_goods", "tracking_type": "none", "critical_stock": 0.00, "description_ar": "", "description_en": "", "description_ku": "", "description_tr": "", "purchase_price": 0.0000, "sale_price_eur": 0.00, "sale_price_usd": 0.00, "shelf_location": null, "special_code_1": "", "special_code_2": "", "special_code_3": "", "special_code_4": "", "special_code_5": "", "special_code_6": "", "sub_group_code": "", "warehouse_code": null, "preparation_time": 5, "withholding_rate": null, "auto_calculate_usd": false, "purchase_price_eur": 0.00, "purchase_price_usd": 0.00, "custom_exchange_rate": 0, "follow_up_reminder_days": null}	pending	\N	RetailEX	\N	0	\N	2026-05-24 16:25:59.062755+03
0aa5276d-98e4-4fe3-9237-bd28731cee5f	rex_001_01_cash_lines	635e7c35-f047-4c0c-854d-e1b174793bba	INSERT	001	{"id": "635e7c35-f047-4c0c-854d-e1b174793bba", "date": "2026-05-24T00:00:00+03:00", "sign": 1, "amount": 8580.00, "trcode": null, "bank_id": null, "firm_nr": "001", "f_amount": 0.00, "fiche_no": "REST-1-1779629158255", "tax_rate": 0.00, "period_nr": "01", "created_at": "2026-05-24T16:25:59.345127+03:00", "definition": "Market Satışı - REST-1-1779629158255", "customer_id": null, "register_id": "00000000-0000-0000-0000-000000000001", "special_code": "", "currency_code": "YEREL", "exchange_rate": 1.000000, "bank_account_id": null, "expense_card_id": null, "transfer_status": 0, "transaction_type": "KASA_GIRIS", "target_register_id": null, "withholding_tax_rate": 0.00}	pending	\N	RetailEX	\N	0	\N	2026-05-24 16:25:59.345127+03
\.


--
-- Data for Name: sys_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_migrations (id, version, name, applied_at, app_version) FROM stdin;
1	000	000_master_schema.sql	2026-05-24 12:50:06.785848+03	0.1.77
2	001	001_demo_data.sql	2026-05-24 12:50:36.68047+03	0.1.77
\.


--
-- Data for Name: system_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.system_settings (id, default_currency, primary_firm_nr, primary_period_nr, updated_at) FROM stdin;
1	IQD	001	01	2026-05-24 12:50:05.210334+03
\.


--
-- Data for Name: units; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.units (id, code, name, description, is_active) FROM stdin;
375294bc-2f38-47a2-9b4b-8c69d09aa971	ADET	Adet	\N	t
0be15dd9-9764-44b9-8446-23c70b0a283b	KG	Kilogram	\N	t
8b7f0fb4-4d59-4552-b27e-bb0f64957891	GRAM	Gram	\N	t
99dfea13-7e9d-4d4b-89ba-ce984f5d79a9	LT	Litre	\N	t
46c66e53-8975-450e-bcc8-59085b0354a5	ML	Militre	\N	t
ec775fe0-e297-4311-ba2f-6fbfd464b967	KOLI	Koli	\N	t
69dd2daf-a019-4127-aa98-a372f9c22476	PKT	Paket	\N	t
b05a49cc-05e3-4cfe-bca2-d1d2bbdeea3e	MT	Metre	\N	t
8301059e-231d-46a3-adc1-7b0975fdaffd	M2	Metrekare	\N	t
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, firm_nr, username, password_hash, full_name, email, phone, role, role_id, store_id, is_active, last_login_at, allowed_firm_nrs, allowed_periods, allowed_store_ids, created_at, updated_at) FROM stdin;
10000000-0000-4000-a000-000000000001	001	admin	$2a$06$8Yb9Ai.0FjwmNTYhwTjlXeNWsczXFbjgXOz0xh2.33UgAEFsUFJaC	System Administrator	admin@retailex.com	\N	admin	00000000-0000-0000-0000-000000000001	\N	t	\N	[]	[]	[]	2026-05-24 12:50:05.210334+03	2026-05-24 12:50:05.210334+03
\.


--
-- Data for Name: floors; Type: TABLE DATA; Schema: rest; Owner: -
--

COPY rest.floors (id, store_id, name, color, display_order, created_at) FROM stdin;
f0bfebd8-dbd5-45cc-bdc4-5f0a0c2d918d	ec676656-87f6-4170-ad61-9e8cf60fab05	Zemin Kat	#3B82F6	1	2026-05-24 12:50:36.457566+03
a71e2fc3-97df-49bf-8355-2a9ba58726d5	ec676656-87f6-4170-ad61-9e8cf60fab05	Teras	#10B981	2	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: kroki_layouts; Type: TABLE DATA; Schema: rest; Owner: -
--

COPY rest.kroki_layouts (id, store_id, floor_name, layout_data) FROM stdin;
\.


--
-- Data for Name: printer_profiles; Type: TABLE DATA; Schema: rest; Owner: -
--

COPY rest.printer_profiles (id, store_id, name, type, address, created_at) FROM stdin;
\.


--
-- Data for Name: return_log; Type: TABLE DATA; Schema: rest; Owner: -
--

COPY rest.return_log (id, return_number, original_receipt, product_id, product_name, quantity, unit_price, total_amount, return_reason, staff_name, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_01_rest_kitchen_items; Type: TABLE DATA; Schema: rest; Owner: -
--

COPY rest.rex_001_01_rest_kitchen_items (id, kitchen_order_id, order_item_id, product_name, quantity, course, note, status, preparation_time, start_at, estimated_ready_at, served_at) FROM stdin;
88e8821e-342f-4ef4-ad62-d3191d7452e6	4a241c3c-7250-4fa4-8abe-7ea421e3b449	03d72b66-cc1e-4cb2-ae17-99f47856d972	Hamburger Menü	1.000	\N	\N	new	5	2026-05-24 14:46:45.165+03	2026-05-24 14:51:45.165+03	\N
2ace963f-afd2-4b80-8002-d90d1840682d	4a241c3c-7250-4fa4-8abe-7ea421e3b449	8328d1dc-715c-45dc-aa59-b4df51cf2735	Erkek Pantolon	1.000	\N	\N	new	5	2026-05-24 14:46:45.165+03	2026-05-24 14:51:45.165+03	\N
a578dc16-478b-4176-b007-4422f423eef2	258219fe-8c82-4da9-8658-d876874873bf	c4fe70d1-8644-4284-904e-1e7719b201fb	KARIŞIK SALATA (DOMATES SALATALIK)	1.000	\N	\N	new	6	2026-05-24 15:04:52.326+03	2026-05-24 15:10:22.326+03	\N
a0c8e7f3-fb26-4ba6-9096-dc8f6ca37bc2	258219fe-8c82-4da9-8658-d876874873bf	f2072e51-f8aa-49cf-b2d3-91e24070dfa8	KAHVE	1.000	\N	\N	new	6	2026-05-24 15:04:52.326+03	2026-05-24 15:10:22.326+03	\N
4eed189e-c611-49c6-a548-7ca65ac48440	634fb158-7cd3-4a23-bf68-0238a7e9d9a4	ceba16b9-ea83-4b9c-8075-7a88762cd8f9	7UP TENEKE	1.000	\N	\N	new	6	2026-05-24 15:22:32.806+03	2026-05-24 15:28:32.806+03	\N
a41a4b9c-e74d-4f23-9687-6204bf21dc9d	634fb158-7cd3-4a23-bf68-0238a7e9d9a4	e03ab2bc-ce55-4f4b-bac9-97d1b6e2224e	AYRAN BARDAK	1.000	\N	\N	new	6	2026-05-24 15:22:32.806+03	2026-05-24 15:28:32.806+03	\N
4461035e-d439-4329-91d7-cf71a36b12a2	634fb158-7cd3-4a23-bf68-0238a7e9d9a4	7a4aca41-7dad-4b9a-83f7-f09b96274712	ÇAY	1.000	\N	\N	new	6	2026-05-24 15:22:32.806+03	2026-05-24 15:28:32.806+03	\N
\.


--
-- Data for Name: rex_001_01_rest_kitchen_orders; Type: TABLE DATA; Schema: rest; Owner: -
--

COPY rest.rex_001_01_rest_kitchen_orders (id, order_id, table_number, floor_name, waiter, staff_id, status, note, estimated_ready_at, sent_at) FROM stdin;
4a241c3c-7250-4fa4-8abe-7ea421e3b449	01dec24f-ad0b-475d-98ea-42788f9e6727	1	\N	admin	\N	new	\N	2026-05-24 14:51:45.165+03	2026-05-24 14:46:45.173053+03
258219fe-8c82-4da9-8658-d876874873bf	01dec24f-ad0b-475d-98ea-42788f9e6727	1	\N	admin	\N	new	\N	2026-05-24 15:10:22.326+03	2026-05-24 15:04:52.330955+03
634fb158-7cd3-4a23-bf68-0238a7e9d9a4	01dec24f-ad0b-475d-98ea-42788f9e6727	1	\N	admin	\N	new	\N	2026-05-24 15:28:32.806+03	2026-05-24 15:22:32.813823+03
\.


--
-- Data for Name: rex_001_01_rest_order_items; Type: TABLE DATA; Schema: rest; Owner: -
--

COPY rest.rex_001_01_rest_order_items (id, order_id, product_id, product_name, quantity, unit_price, discount_pct, subtotal, status, course, note, options, is_void, void_reason, is_complimentary, preparation_time, sent_to_kitchen_at, served_at, created_at) FROM stdin;
f6c6bde1-b5d2-4d57-8d51-bda0c8b47b05	44e147d8-1025-4599-8266-b2935b22af64	80720be4-a213-4dc4-afd1-58d3d4ad6a07	Ayran	1.000	25.00	0.00	25.00	pending	\N	\N	\N	f	\N	f	\N	\N	\N	2026-05-24 12:51:33.515893+03
fa6a5481-1fbc-47be-9f3f-40dea7c70182	44e147d8-1025-4599-8266-b2935b22af64	f483a7c5-d84f-4ca3-b7ae-e2363c887ae2	Bisküvi Paketi	1.000	25.00	0.00	25.00	pending	\N	\N	\N	f	\N	f	\N	\N	\N	2026-05-24 12:51:34.400971+03
03d72b66-cc1e-4cb2-ae17-99f47856d972	01dec24f-ad0b-475d-98ea-42788f9e6727	3162b084-ea83-41c4-8c67-e1f5263dd740	Hamburger Menü	1.000	180.00	0.00	180.00	cooking	\N	\N	\N	f	\N	f	\N	2026-05-24 14:46:45.206499+03	\N	2026-05-24 14:46:20.527997+03
8328d1dc-715c-45dc-aa59-b4df51cf2735	01dec24f-ad0b-475d-98ea-42788f9e6727	9a8f7096-e89c-43c4-9d50-c8b40fcc043a	Erkek Pantolon	1.000	650.00	0.00	650.00	cooking	\N	\N	\N	f	\N	f	\N	2026-05-24 14:46:45.232016+03	\N	2026-05-24 14:46:20.883734+03
c4fe70d1-8644-4284-904e-1e7719b201fb	01dec24f-ad0b-475d-98ea-42788f9e6727	102e4899-2368-4831-88ff-519515314eb1	KARIŞIK SALATA (DOMATES SALATALIK)	1.000	3750.00	0.00	3750.00	cooking	\N	\N	\N	f	\N	f	\N	2026-05-24 15:04:52.390176+03	\N	2026-05-24 15:04:21.400168+03
f2072e51-f8aa-49cf-b2d3-91e24070dfa8	01dec24f-ad0b-475d-98ea-42788f9e6727	a012f83b-d3f3-4435-8f40-46f9ea7541a7	KAHVE	1.000	0.00	0.00	0.00	cooking	\N	\N	\N	f	\N	f	\N	2026-05-24 15:04:52.430537+03	\N	2026-05-24 15:04:21.733205+03
ceba16b9-ea83-4b9c-8075-7a88762cd8f9	01dec24f-ad0b-475d-98ea-42788f9e6727	2db1e771-61d8-46af-a6b9-5b23fe9a0ea5	7UP TENEKE	1.000	2500.00	0.00	2500.00	cooking	\N	\N	\N	f	\N	f	\N	2026-05-24 15:22:32.882001+03	\N	2026-05-24 15:22:24.601474+03
e03ab2bc-ce55-4f4b-bac9-97d1b6e2224e	01dec24f-ad0b-475d-98ea-42788f9e6727	0230b49e-da04-4c01-8376-dcf39efcc266	AYRAN BARDAK	1.000	1500.00	0.00	1500.00	cooking	\N	\N	\N	f	\N	f	\N	2026-05-24 15:22:32.912556+03	\N	2026-05-24 15:22:25.211277+03
7a4aca41-7dad-4b9a-83f7-f09b96274712	01dec24f-ad0b-475d-98ea-42788f9e6727	6d2ba86e-cd03-436b-863d-791de70a281f	ÇAY	1.000	0.00	0.00	0.00	cooking	\N	\N	\N	f	\N	f	\N	2026-05-24 15:22:32.947518+03	\N	2026-05-24 15:22:25.524265+03
d6a285c0-1444-41c4-adb9-29a03baa0209	92059fcc-0d88-4d8b-a670-edaa7b0ce5f9	2db1e771-61d8-46af-a6b9-5b23fe9a0ea5	7UP TENEKE	1.000	2500.00	0.00	2500.00	pending	\N	\N	\N	f	\N	f	\N	\N	\N	2026-05-24 16:26:35.653562+03
acc6a261-274c-4bb7-9a8c-e92b8c2ae938	92059fcc-0d88-4d8b-a670-edaa7b0ce5f9	62e97a61-8d31-47f1-833c-28ca73136f52	ÇİG BOREK KIYMALI	1.000	3750.00	0.00	3750.00	pending	\N	\N	\N	f	\N	f	\N	\N	\N	2026-05-24 16:26:36.697036+03
\.


--
-- Data for Name: rex_001_01_rest_orders; Type: TABLE DATA; Schema: rest; Owner: -
--

COPY rest.rex_001_01_rest_orders (id, order_no, table_id, floor_id, waiter, staff_id, customer_id, status, total_amount, discount_amount, order_discount_pct, tax_amount, note, parent_order_id, kitchen_note, estimated_ready_at, opened_at, billed_at, closed_at, payment_method, created_at, updated_at) FROM stdin;
44e147d8-1025-4599-8266-b2935b22af64	RES-2026-00001	cd9d840d-97a9-4e06-841f-a2cafd2fb3f5	f0bfebd8-dbd5-45cc-bdc4-5f0a0c2d918d	admin	\N	\N	closed	50.00	0.00	0.00	0.00	\N	\N	\N	\N	2026-05-24 12:51:28.992352+03	2026-05-24 12:52:00.447309+03	2026-05-24 12:52:00.447309+03	cash	2026-05-24 12:51:28.992352+03	2026-05-24 12:52:00.447309+03
01dec24f-ad0b-475d-98ea-42788f9e6727	RES-2026-00002	cd9d840d-97a9-4e06-841f-a2cafd2fb3f5	f0bfebd8-dbd5-45cc-bdc4-5f0a0c2d918d	admin	\N	\N	closed	8580.00	0.00	0.00	0.00	\N	\N	\N	\N	2026-05-24 14:46:17.756465+03	2026-05-24 16:25:58.105995+03	2026-05-24 16:25:58.105995+03	cash	2026-05-24 14:46:17.756465+03	2026-05-24 16:25:58.105995+03
92059fcc-0d88-4d8b-a670-edaa7b0ce5f9	RES-2026-00003	22d4e614-0086-4a66-b1ae-f4f5ff8c82ce	f0bfebd8-dbd5-45cc-bdc4-5f0a0c2d918d	admin	\N	\N	open	6250.00	0.00	0.00	0.00	\N	\N	\N	\N	2026-05-24 16:26:31.250115+03	\N	\N	\N	2026-05-24 16:26:31.250115+03	2026-05-24 16:26:39.056964+03
\.


--
-- Data for Name: rex_001_01_rest_reservations; Type: TABLE DATA; Schema: rest; Owner: -
--

COPY rest.rex_001_01_rest_reservations (id, customer_id, customer_name, phone, reservation_date, reservation_time, guest_count, table_id, table_number, status, note, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rex_001_rest_recipe_ingredients; Type: TABLE DATA; Schema: rest; Owner: -
--

COPY rest.rex_001_rest_recipe_ingredients (id, recipe_id, material_id, quantity, unit, cost) FROM stdin;
\.


--
-- Data for Name: rex_001_rest_recipes; Type: TABLE DATA; Schema: rest; Owner: -
--

COPY rest.rex_001_rest_recipes (id, menu_item_id, product_id, total_cost, wastage_percent, is_active, updated_at) FROM stdin;
\.


--
-- Data for Name: rex_001_rest_staff; Type: TABLE DATA; Schema: rest; Owner: -
--

COPY rest.rex_001_rest_staff (id, name, role, pin, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: rex_001_rest_tables; Type: TABLE DATA; Schema: rest; Owner: -
--

COPY rest.rex_001_rest_tables (id, floor_id, number, seats, status, total, pos_x, pos_y, is_large, waiter, staff_id, start_time, locked_by_staff_id, locked_by_staff_name, locked_at, linked_order_ids, color, updated_at) FROM stdin;
48f0f9f6-d607-47c1-be08-45d8cee90509	f0bfebd8-dbd5-45cc-bdc4-5f0a0c2d918d	3	2	empty	0.00	250	50	f	\N	\N	\N	\N	\N	\N	{}	\N	2026-05-24 12:50:36.457566+03
9d6aafdd-a4cf-4027-8248-6d600a943c19	f0bfebd8-dbd5-45cc-bdc4-5f0a0c2d918d	4	4	empty	0.00	50	150	f	\N	\N	\N	\N	\N	\N	{}	\N	2026-05-24 12:50:36.457566+03
64695cdc-7199-4df0-a160-139296c9a4c1	f0bfebd8-dbd5-45cc-bdc4-5f0a0c2d918d	5	6	empty	0.00	150	150	f	\N	\N	\N	\N	\N	\N	{}	\N	2026-05-24 12:50:36.457566+03
3ba5d1ba-d3ad-4353-8dee-375255bd516d	f0bfebd8-dbd5-45cc-bdc4-5f0a0c2d918d	6	4	empty	0.00	350	50	f	\N	\N	\N	\N	\N	\N	{}	\N	2026-05-24 12:50:36.457566+03
cd9d840d-97a9-4e06-841f-a2cafd2fb3f5	f0bfebd8-dbd5-45cc-bdc4-5f0a0c2d918d	1	4	empty	0.00	50	50	f	\N	\N	\N	\N	\N	\N	{}	\N	2026-05-24 16:25:58.178504+03
22d4e614-0086-4a66-b1ae-f4f5ff8c82ce	f0bfebd8-dbd5-45cc-bdc4-5f0a0c2d918d	2	4	billing	6250.00	150	50	f	admin	aee369ed-a268-42ca-8818-e55553378477	\N	\N	\N	\N	{}	\N	2026-05-24 16:26:39.105466+03
\.


--
-- Data for Name: staff_roles; Type: TABLE DATA; Schema: rest; Owner: -
--

COPY rest.staff_roles (id, name, permissions) FROM stdin;
aea1024b-15f3-4fa2-bb62-16530405ed13	Manager	{}
beb29e44-e533-446e-b07b-c44a7ef04df4	Waiter	{}
4eaf186c-ff49-41a1-ae17-04564c552fd9	Chef	{}
f18085b3-388a-4b7a-88a3-966e1d5f2d4b	Cashier	{}
\.


--
-- Data for Name: bins; Type: TABLE DATA; Schema: wms; Owner: -
--

COPY wms.bins (id, store_id, code, zone, aisle, shelf, bin, capacity_m3, max_weight, is_active) FROM stdin;
\.


--
-- Data for Name: counting_lines; Type: TABLE DATA; Schema: wms; Owner: -
--

COPY wms.counting_lines (id, slip_id, firm_nr, product_id, product_ref, barcode, product_name, bin_id, location_code, expected_qty, counted_qty, variance, counted_by, counted_at, notes, created_at, updated_at) FROM stdin;
7c72d00d-54f3-412a-9fc4-c169f19e152c	2defc003-a258-43dc-8771-eb428482229b	001	b3932d01-23c2-433b-bd6e-d24bb8073dfd	\N	8680000000002	Samsung Galaxy S24	\N	\N	23.00	22.00	-1.00	admin	2026-01-20 12:00:00+03	\N	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
6922d7c1-b4bc-4ba3-b1e0-408e340c020d	2defc003-a258-43dc-8771-eb428482229b	001	8cc29e25-143b-40ec-a37f-45c0a0291b92	\N	8680000000010	MacBook Pro 16"	\N	\N	8.00	7.00	-1.00	admin	2026-01-20 12:00:00+03	\N	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
de1ff019-c531-4209-8f72-a17d16b4d5f2	2defc003-a258-43dc-8771-eb428482229b	001	af831dbf-90ef-47e0-9e9a-d9d41470355e	\N	8680000000001	iPhone 15 Pro	\N	\N	18.00	17.00	-1.00	admin	2026-01-20 12:00:00+03	\N	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: counting_slips; Type: TABLE DATA; Schema: wms; Owner: -
--

COPY wms.counting_slips (id, firm_nr, store_id, fiche_no, date, status, count_type, location_code, description, created_by, started_at, completed_at, created_at, updated_at) FROM stdin;
2defc003-a258-43dc-8771-eb428482229b	001	ec676656-87f6-4170-ad61-9e8cf60fab05	SAY-2026-0001	2026-01-20 08:00:00+03	completed	full	\N	Ocak Ayı Tam Sayım	10000000-0000-4000-a000-000000000001	\N	\N	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
c3f65b99-773c-4441-946f-6b7df34651ca	001	ec676656-87f6-4170-ad61-9e8cf60fab05	SAY-2026-0002	2026-02-10 09:00:00+03	active	cycle	\N	Elektronik Bölüm Döngüsel Sayım	\N	\N	\N	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: dispatch_lines; Type: TABLE DATA; Schema: wms; Owner: -
--

COPY wms.dispatch_lines (id, slip_id, product_id, product_code, product_name, barcode, requested_qty, picked_qty, unit, notes, created_at) FROM stdin;
0a6c02de-85a7-4376-8044-67e1ba9a5324	e5c24c6b-3ac0-48d1-a6af-ecb364a2c298	b3932d01-23c2-433b-bd6e-d24bb8073dfd	PHONE-002	Samsung Galaxy S24	\N	2.000	2.000	Adet	\N	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: dispatch_slips; Type: TABLE DATA; Schema: wms; Owner: -
--

COPY wms.dispatch_slips (id, firm_nr, store_id, slip_no, customer_name, priority, notes, status, created_by, created_at, updated_at) FROM stdin;
e5c24c6b-3ac0-48d1-a6af-ecb364a2c298	001	ec676656-87f6-4170-ad61-9e8cf60fab05	SEV-2026-0001	Al-Noor Teknoloji	high	Acil sipariş — öncelikli	completed	\N	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: dock_doors; Type: TABLE DATA; Schema: wms; Owner: -
--

COPY wms.dock_doors (id, firm_nr, code, name, type, warehouse_id, status, vehicle_plate, carrier_name, assigned_at, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: labor_productivity; Type: TABLE DATA; Schema: wms; Owner: -
--

COPY wms.labor_productivity (id, firm_nr, user_id, username, task_type, reference_id, start_time, end_time, items_processed, lines_processed, efficiency_rate, warehouse_id, notes, created_at) FROM stdin;
\.


--
-- Data for Name: personnel; Type: TABLE DATA; Schema: wms; Owner: -
--

COPY wms.personnel (id, user_id, store_id, role, is_active) FROM stdin;
\.


--
-- Data for Name: pick_waves; Type: TABLE DATA; Schema: wms; Owner: -
--

COPY wms.pick_waves (id, wave_no, firm_nr, warehouse_id, status, priority, wave_type, total_lines, picked_lines, total_qty, picked_qty, assigned_to, released_at, started_at, completed_at, due_date, notes, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: receiving_lines; Type: TABLE DATA; Schema: wms; Owner: -
--

COPY wms.receiving_lines (id, slip_id, product_id, product_code, product_name, barcode, ordered_qty, received_qty, unit, notes, created_at) FROM stdin;
481ce8b2-69de-4bb6-9c36-5ec47a640d19	f177a9e0-42e4-4b38-b861-04fb9958b3a6	af831dbf-90ef-47e0-9e9a-d9d41470355e	PHONE-001	iPhone 15 Pro	8680000000001	5.000	5.000	Adet	\N	2026-05-24 12:50:36.457566+03
66eff130-1b31-4d98-ad21-e21339585657	f177a9e0-42e4-4b38-b861-04fb9958b3a6	8cc29e25-143b-40ec-a37f-45c0a0291b92	PC-001	MacBook Pro 16"	8680000000010	3.000	3.000	Adet	\N	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: receiving_slips; Type: TABLE DATA; Schema: wms; Owner: -
--

COPY wms.receiving_slips (id, firm_nr, store_id, slip_no, supplier_name, notes, status, created_by, created_at, updated_at) FROM stdin;
f177a9e0-42e4-4b38-b861-04fb9958b3a6	001	ec676656-87f6-4170-ad61-9e8cf60fab05	MAL-2026-0001	Teknoloji Dağıtım A.Ş.	iPhone ve MacBook stoğu	completed	admin	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
b37a825a-7309-404e-a09c-26e8f1fda0c1	001	ec676656-87f6-4170-ad61-9e8cf60fab05	MAL-2026-0002	Gıda Tedarik Ltd.	Atıştırmalık stoğu — bekleniyor	pending	\N	2026-05-24 12:50:36.457566+03	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: slotting_recommendations; Type: TABLE DATA; Schema: wms; Owner: -
--

COPY wms.slotting_recommendations (id, firm_nr, product_id, product_code, product_name, current_location, recommended_location, reason, velocity_class, daily_picks, distance_saved_m, is_applied, applied_at, applied_by, created_at) FROM stdin;
\.


--
-- Data for Name: task_queue; Type: TABLE DATA; Schema: wms; Owner: -
--

COPY wms.task_queue (id, firm_nr, task_type, reference_id, reference_no, priority, status, assigned_to, assigned_at, started_at, completed_at, warehouse_id, bin_location, product_code, quantity, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: transfer_items; Type: TABLE DATA; Schema: wms; Owner: -
--

COPY wms.transfer_items (id, transfer_id, product_id, quantity, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: transfers; Type: TABLE DATA; Schema: wms; Owner: -
--

COPY wms.transfers (id, firm_nr, fiche_no, source_store_id, target_store_id, date, status, created_at) FROM stdin;
c46a929a-2433-402b-9599-1d60c4cd0990	001	TRF-2026-0001	ec676656-87f6-4170-ad61-9e8cf60fab05	ec676656-87f6-4170-ad61-9e8cf60fab05	2026-01-25 10:00:00+03	completed	2026-05-24 12:50:36.457566+03
\.


--
-- Data for Name: yard_locations; Type: TABLE DATA; Schema: wms; Owner: -
--

COPY wms.yard_locations (id, firm_nr, code, type, status, vehicle_plate, driver_name, entry_time, exit_time, warehouse_id, notes, created_at, updated_at) FROM stdin;
\.


--
-- Name: menu_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.menu_items_id_seq', 1, false);


--
-- Name: sys_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sys_migrations_id_seq', 2, true);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: body_regions body_regions_name_key; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.body_regions
    ADD CONSTRAINT body_regions_name_key UNIQUE (name);


--
-- Name: body_regions body_regions_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.body_regions
    ADD CONSTRAINT body_regions_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_appointments rex_001_01_beauty_appointments_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_appointments
    ADD CONSTRAINT rex_001_01_beauty_appointments_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_audit_log rex_001_01_beauty_audit_log_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_audit_log
    ADD CONSTRAINT rex_001_01_beauty_audit_log_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_booking_requests rex_001_01_beauty_booking_requests_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_booking_requests
    ADD CONSTRAINT rex_001_01_beauty_booking_requests_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_clinical_notes rex_001_01_beauty_clinical_notes_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_clinical_notes
    ADD CONSTRAINT rex_001_01_beauty_clinical_notes_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_consent_submissions rex_001_01_beauty_consent_submissions_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_consent_submissions
    ADD CONSTRAINT rex_001_01_beauty_consent_submissions_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_consumable_usage_log rex_001_01_beauty_consumable_usage_log_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_consumable_usage_log
    ADD CONSTRAINT rex_001_01_beauty_consumable_usage_log_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_customer_feedback rex_001_01_beauty_customer_feedback_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_customer_feedback
    ADD CONSTRAINT rex_001_01_beauty_customer_feedback_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_device_alerts rex_001_01_beauty_device_alerts_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_device_alerts
    ADD CONSTRAINT rex_001_01_beauty_device_alerts_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_device_usage rex_001_01_beauty_device_usage_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_device_usage
    ADD CONSTRAINT rex_001_01_beauty_device_usage_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_membership_subscriptions rex_001_01_beauty_membership_subscriptions_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_membership_subscriptions
    ADD CONSTRAINT rex_001_01_beauty_membership_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_notification_queue rex_001_01_beauty_notification_queue_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_notification_queue
    ADD CONSTRAINT rex_001_01_beauty_notification_queue_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_package_purchases rex_001_01_beauty_package_purchases_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_package_purchases
    ADD CONSTRAINT rex_001_01_beauty_package_purchases_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_package_sales rex_001_01_beauty_package_sales_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_package_sales
    ADD CONSTRAINT rex_001_01_beauty_package_sales_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_patient_photos rex_001_01_beauty_patient_photos_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_patient_photos
    ADD CONSTRAINT rex_001_01_beauty_patient_photos_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_sale_items rex_001_01_beauty_sale_items_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_sale_items
    ADD CONSTRAINT rex_001_01_beauty_sale_items_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_sales rex_001_01_beauty_sales_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_sales
    ADD CONSTRAINT rex_001_01_beauty_sales_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_session_logs rex_001_01_beauty_session_logs_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_session_logs
    ADD CONSTRAINT rex_001_01_beauty_session_logs_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_sessions rex_001_01_beauty_sessions_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_sessions
    ADD CONSTRAINT rex_001_01_beauty_sessions_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_beauty_waitlist rex_001_01_beauty_waitlist_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_01_beauty_waitlist
    ADD CONSTRAINT rex_001_01_beauty_waitlist_pkey PRIMARY KEY (id);


--
-- Name: rex_001_beauty_branches rex_001_beauty_branches_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_branches
    ADD CONSTRAINT rex_001_beauty_branches_pkey PRIMARY KEY (id);


--
-- Name: rex_001_beauty_consent_templates rex_001_beauty_consent_templates_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_consent_templates
    ADD CONSTRAINT rex_001_beauty_consent_templates_pkey PRIMARY KEY (id);


--
-- Name: rex_001_beauty_corporate_accounts rex_001_beauty_corporate_accounts_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_corporate_accounts
    ADD CONSTRAINT rex_001_beauty_corporate_accounts_pkey PRIMARY KEY (id);


--
-- Name: rex_001_beauty_customer_health rex_001_beauty_customer_health_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_customer_health
    ADD CONSTRAINT rex_001_beauty_customer_health_pkey PRIMARY KEY (customer_id);


--
-- Name: rex_001_beauty_devices rex_001_beauty_devices_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_devices
    ADD CONSTRAINT rex_001_beauty_devices_pkey PRIMARY KEY (id);


--
-- Name: rex_001_beauty_integration_settings rex_001_beauty_integration_settings_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_integration_settings
    ADD CONSTRAINT rex_001_beauty_integration_settings_pkey PRIMARY KEY (id);


--
-- Name: rex_001_beauty_leads rex_001_beauty_leads_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_leads
    ADD CONSTRAINT rex_001_beauty_leads_pkey PRIMARY KEY (id);


--
-- Name: rex_001_beauty_marketing_campaigns rex_001_beauty_marketing_campaigns_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_marketing_campaigns
    ADD CONSTRAINT rex_001_beauty_marketing_campaigns_pkey PRIMARY KEY (id);


--
-- Name: rex_001_beauty_memberships rex_001_beauty_memberships_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_memberships
    ADD CONSTRAINT rex_001_beauty_memberships_pkey PRIMARY KEY (id);


--
-- Name: rex_001_beauty_packages rex_001_beauty_packages_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_packages
    ADD CONSTRAINT rex_001_beauty_packages_pkey PRIMARY KEY (id);


--
-- Name: rex_001_beauty_portal_settings rex_001_beauty_portal_settings_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_portal_settings
    ADD CONSTRAINT rex_001_beauty_portal_settings_pkey PRIMARY KEY (id);


--
-- Name: rex_001_beauty_product_batches rex_001_beauty_product_batches_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_product_batches
    ADD CONSTRAINT rex_001_beauty_product_batches_pkey PRIMARY KEY (id);


--
-- Name: rex_001_beauty_rooms rex_001_beauty_rooms_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_rooms
    ADD CONSTRAINT rex_001_beauty_rooms_pkey PRIMARY KEY (id);


--
-- Name: rex_001_beauty_satisfaction_questions rex_001_beauty_satisfaction_questions_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_satisfaction_questions
    ADD CONSTRAINT rex_001_beauty_satisfaction_questions_pkey PRIMARY KEY (id);


--
-- Name: rex_001_beauty_satisfaction_surveys rex_001_beauty_satisfaction_surveys_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_satisfaction_surveys
    ADD CONSTRAINT rex_001_beauty_satisfaction_surveys_pkey PRIMARY KEY (id);


--
-- Name: rex_001_beauty_service_consumables rex_001_beauty_service_consumables_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_service_consumables
    ADD CONSTRAINT rex_001_beauty_service_consumables_pkey PRIMARY KEY (id);


--
-- Name: rex_001_beauty_services rex_001_beauty_services_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_services
    ADD CONSTRAINT rex_001_beauty_services_pkey PRIMARY KEY (id);


--
-- Name: rex_001_beauty_specialists rex_001_beauty_specialists_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_specialists
    ADD CONSTRAINT rex_001_beauty_specialists_pkey PRIMARY KEY (id);


--
-- Name: rex_001_follow_up_reminder_actions rex_001_follow_up_reminder_actions_pkey; Type: CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_follow_up_reminder_actions
    ADD CONSTRAINT rex_001_follow_up_reminder_actions_pkey PRIMARY KEY (id);


--
-- Name: bank_accounts bank_accounts_firm_nr_code_key; Type: CONSTRAINT; Schema: logic; Owner: -
--

ALTER TABLE ONLY logic.bank_accounts
    ADD CONSTRAINT bank_accounts_firm_nr_code_key UNIQUE (firm_nr, code);


--
-- Name: bank_accounts bank_accounts_pkey; Type: CONSTRAINT; Schema: logic; Owner: -
--

ALTER TABLE ONLY logic.bank_accounts
    ADD CONSTRAINT bank_accounts_pkey PRIMARY KEY (id);


--
-- Name: campaigns campaigns_firm_nr_code_key; Type: CONSTRAINT; Schema: logic; Owner: -
--

ALTER TABLE ONLY logic.campaigns
    ADD CONSTRAINT campaigns_firm_nr_code_key UNIQUE (firm_nr, code);


--
-- Name: campaigns campaigns_pkey; Type: CONSTRAINT; Schema: logic; Owner: -
--

ALTER TABLE ONLY logic.campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id);


--
-- Name: app_settings app_settings_key_firm_nr_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_settings
    ADD CONSTRAINT app_settings_key_firm_nr_key UNIQUE (key, firm_nr);


--
-- Name: app_settings app_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_settings
    ADD CONSTRAINT app_settings_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: barcode_templates barcode_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.barcode_templates
    ADD CONSTRAINT barcode_templates_pkey PRIMARY KEY (id);


--
-- Name: brands brands_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.brands
    ADD CONSTRAINT brands_code_key UNIQUE (code);


--
-- Name: brands brands_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.brands
    ADD CONSTRAINT brands_pkey PRIMARY KEY (id);


--
-- Name: categories categories_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_code_key UNIQUE (code);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: currencies currencies_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currencies
    ADD CONSTRAINT currencies_code_key UNIQUE (code);


--
-- Name: currencies currencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currencies
    ADD CONSTRAINT currencies_pkey PRIMARY KEY (id);


--
-- Name: exchange_rates exchange_rates_currency_code_date_source_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rates
    ADD CONSTRAINT exchange_rates_currency_code_date_source_key UNIQUE (currency_code, date, source);


--
-- Name: exchange_rates exchange_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rates
    ADD CONSTRAINT exchange_rates_pkey PRIMARY KEY (id);


--
-- Name: firms firms_firm_nr_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.firms
    ADD CONSTRAINT firms_firm_nr_key UNIQUE (firm_nr);


--
-- Name: firms firms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.firms
    ADD CONSTRAINT firms_pkey PRIMARY KEY (id);


--
-- Name: gib_edocument_queue gib_edocument_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gib_edocument_queue
    ADD CONSTRAINT gib_edocument_queue_pkey PRIMARY KEY (id);


--
-- Name: gib_edocument_queue gib_edocument_queue_unique_source; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gib_edocument_queue
    ADD CONSTRAINT gib_edocument_queue_unique_source UNIQUE (firm_nr, period_nr, source_type, source_id);


--
-- Name: menu_items menu_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_items
    ADD CONSTRAINT menu_items_pkey PRIMARY KEY (id);


--
-- Name: periods periods_firm_id_nr_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periods
    ADD CONSTRAINT periods_firm_id_nr_key UNIQUE (firm_id, nr);


--
-- Name: periods periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periods
    ADD CONSTRAINT periods_pkey PRIMARY KEY (id);


--
-- Name: product_exchange_rate_history product_exchange_rate_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_exchange_rate_history
    ADD CONSTRAINT product_exchange_rate_history_pkey PRIMARY KEY (id);


--
-- Name: product_groups product_groups_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_groups
    ADD CONSTRAINT product_groups_code_key UNIQUE (code);


--
-- Name: product_groups product_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_groups
    ADD CONSTRAINT product_groups_pkey PRIMARY KEY (id);


--
-- Name: report_templates report_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_templates
    ADD CONSTRAINT report_templates_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_bank_lines rex_001_01_bank_lines_fiche_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_bank_lines
    ADD CONSTRAINT rex_001_01_bank_lines_fiche_no_key UNIQUE (fiche_no);


--
-- Name: rex_001_01_bank_lines rex_001_01_bank_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_bank_lines
    ADD CONSTRAINT rex_001_01_bank_lines_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_cash_lines rex_001_01_cash_lines_fiche_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_cash_lines
    ADD CONSTRAINT rex_001_01_cash_lines_fiche_no_key UNIQUE (fiche_no);


--
-- Name: rex_001_01_cash_lines rex_001_01_cash_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_cash_lines
    ADD CONSTRAINT rex_001_01_cash_lines_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_sale_items rex_001_01_sale_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_sale_items
    ADD CONSTRAINT rex_001_01_sale_items_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_sales rex_001_01_sales_fiche_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_sales
    ADD CONSTRAINT rex_001_01_sales_fiche_no_key UNIQUE (fiche_no);


--
-- Name: rex_001_01_sales rex_001_01_sales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_sales
    ADD CONSTRAINT rex_001_01_sales_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_stock_movement_items rex_001_01_stock_movement_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_stock_movement_items
    ADD CONSTRAINT rex_001_01_stock_movement_items_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_stock_movements rex_001_01_stock_movements_document_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_stock_movements
    ADD CONSTRAINT rex_001_01_stock_movements_document_no_key UNIQUE (document_no);


--
-- Name: rex_001_01_stock_movements rex_001_01_stock_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_stock_movements
    ADD CONSTRAINT rex_001_01_stock_movements_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_virman_items rex_001_01_virman_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_virman_items
    ADD CONSTRAINT rex_001_01_virman_items_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_virman_operations rex_001_01_virman_operations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_virman_operations
    ADD CONSTRAINT rex_001_01_virman_operations_pkey PRIMARY KEY (id);


--
-- Name: rex_001_bank_registers rex_001_bank_registers_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_bank_registers
    ADD CONSTRAINT rex_001_bank_registers_code_key UNIQUE (code);


--
-- Name: rex_001_bank_registers rex_001_bank_registers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_bank_registers
    ADD CONSTRAINT rex_001_bank_registers_pkey PRIMARY KEY (id);


--
-- Name: rex_001_brands rex_001_brands_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_brands
    ADD CONSTRAINT rex_001_brands_code_key UNIQUE (code);


--
-- Name: rex_001_brands rex_001_brands_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_brands
    ADD CONSTRAINT rex_001_brands_pkey PRIMARY KEY (id);


--
-- Name: rex_001_campaigns rex_001_campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_campaigns
    ADD CONSTRAINT rex_001_campaigns_pkey PRIMARY KEY (id);


--
-- Name: rex_001_cash_registers rex_001_cash_registers_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_cash_registers
    ADD CONSTRAINT rex_001_cash_registers_code_key UNIQUE (code);


--
-- Name: rex_001_cash_registers rex_001_cash_registers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_cash_registers
    ADD CONSTRAINT rex_001_cash_registers_pkey PRIMARY KEY (id);


--
-- Name: rex_001_categories rex_001_categories_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_categories
    ADD CONSTRAINT rex_001_categories_code_key UNIQUE (code);


--
-- Name: rex_001_categories rex_001_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_categories
    ADD CONSTRAINT rex_001_categories_pkey PRIMARY KEY (id);


--
-- Name: rex_001_customers rex_001_customers_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_customers
    ADD CONSTRAINT rex_001_customers_code_key UNIQUE (code);


--
-- Name: rex_001_customers rex_001_customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_customers
    ADD CONSTRAINT rex_001_customers_pkey PRIMARY KEY (id);


--
-- Name: rex_001_expense_cards rex_001_expense_cards_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_expense_cards
    ADD CONSTRAINT rex_001_expense_cards_code_key UNIQUE (code);


--
-- Name: rex_001_expense_cards rex_001_expense_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_expense_cards
    ADD CONSTRAINT rex_001_expense_cards_pkey PRIMARY KEY (id);


--
-- Name: rex_001_product_barcodes rex_001_product_barcodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_product_barcodes
    ADD CONSTRAINT rex_001_product_barcodes_pkey PRIMARY KEY (id);


--
-- Name: rex_001_product_unit_conversions rex_001_product_unit_conversions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_product_unit_conversions
    ADD CONSTRAINT rex_001_product_unit_conversions_pkey PRIMARY KEY (id);


--
-- Name: rex_001_product_variants rex_001_product_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_product_variants
    ADD CONSTRAINT rex_001_product_variants_pkey PRIMARY KEY (id);


--
-- Name: rex_001_product_variants rex_001_product_variants_sku_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_product_variants
    ADD CONSTRAINT rex_001_product_variants_sku_key UNIQUE (sku);


--
-- Name: rex_001_products rex_001_products_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_products
    ADD CONSTRAINT rex_001_products_code_key UNIQUE (code);


--
-- Name: rex_001_products rex_001_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_products
    ADD CONSTRAINT rex_001_products_pkey PRIMARY KEY (id);


--
-- Name: rex_001_products rex_001_products_ref_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_products
    ADD CONSTRAINT rex_001_products_ref_id_key UNIQUE (ref_id);


--
-- Name: rex_001_sales_reps rex_001_sales_reps_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_sales_reps
    ADD CONSTRAINT rex_001_sales_reps_code_key UNIQUE (code);


--
-- Name: rex_001_sales_reps rex_001_sales_reps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_sales_reps
    ADD CONSTRAINT rex_001_sales_reps_pkey PRIMARY KEY (id);


--
-- Name: rex_001_services rex_001_services_firm_code_uq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_services
    ADD CONSTRAINT rex_001_services_firm_code_uq UNIQUE (firm_nr, code);


--
-- Name: rex_001_services rex_001_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_services
    ADD CONSTRAINT rex_001_services_pkey PRIMARY KEY (id);


--
-- Name: rex_001_special_codes rex_001_special_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_special_codes
    ADD CONSTRAINT rex_001_special_codes_pkey PRIMARY KEY (id);


--
-- Name: rex_001_suppliers rex_001_suppliers_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_suppliers
    ADD CONSTRAINT rex_001_suppliers_code_key UNIQUE (code);


--
-- Name: rex_001_suppliers rex_001_suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_suppliers
    ADD CONSTRAINT rex_001_suppliers_pkey PRIMARY KEY (id);


--
-- Name: rex_001_tax_rates rex_001_tax_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_tax_rates
    ADD CONSTRAINT rex_001_tax_rates_pkey PRIMARY KEY (id);


--
-- Name: rex_001_units rex_001_units_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_units
    ADD CONSTRAINT rex_001_units_code_key UNIQUE (code);


--
-- Name: rex_001_units rex_001_units_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_units
    ADD CONSTRAINT rex_001_units_pkey PRIMARY KEY (id);


--
-- Name: rex_001_unitsetl rex_001_unitsetl_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_unitsetl
    ADD CONSTRAINT rex_001_unitsetl_pkey PRIMARY KEY (id);


--
-- Name: rex_001_unitsetl rex_001_unitsetl_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_unitsetl
    ADD CONSTRAINT rex_001_unitsetl_unique UNIQUE (unitset_id, item_code);


--
-- Name: rex_001_unitsets rex_001_unitsets_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_unitsets
    ADD CONSTRAINT rex_001_unitsets_code_key UNIQUE (code);


--
-- Name: rex_001_unitsets rex_001_unitsets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_unitsets
    ADD CONSTRAINT rex_001_unitsets_pkey PRIMARY KEY (id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: service_health service_health_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_health
    ADD CONSTRAINT service_health_pkey PRIMARY KEY (service_id);


--
-- Name: service_health service_health_service_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_health
    ADD CONSTRAINT service_health_service_name_key UNIQUE (service_name);


--
-- Name: service_transactions service_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_transactions
    ADD CONSTRAINT service_transactions_pkey PRIMARY KEY (id);


--
-- Name: stores stores_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stores
    ADD CONSTRAINT stores_code_key UNIQUE (code);


--
-- Name: stores stores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stores
    ADD CONSTRAINT stores_pkey PRIMARY KEY (id);


--
-- Name: sync_queue sync_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_queue
    ADD CONSTRAINT sync_queue_pkey PRIMARY KEY (id);


--
-- Name: sys_migrations sys_migrations_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_migrations
    ADD CONSTRAINT sys_migrations_name_key UNIQUE (name);


--
-- Name: sys_migrations sys_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_migrations
    ADD CONSTRAINT sys_migrations_pkey PRIMARY KEY (id);


--
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (id);


--
-- Name: units units_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_code_key UNIQUE (code);


--
-- Name: units units_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: floors floors_pkey; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.floors
    ADD CONSTRAINT floors_pkey PRIMARY KEY (id);


--
-- Name: kroki_layouts kroki_layouts_pkey; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.kroki_layouts
    ADD CONSTRAINT kroki_layouts_pkey PRIMARY KEY (id);


--
-- Name: kroki_layouts kroki_layouts_store_id_floor_name_key; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.kroki_layouts
    ADD CONSTRAINT kroki_layouts_store_id_floor_name_key UNIQUE (store_id, floor_name);


--
-- Name: printer_profiles printer_profiles_pkey; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.printer_profiles
    ADD CONSTRAINT printer_profiles_pkey PRIMARY KEY (id);


--
-- Name: return_log return_log_pkey; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.return_log
    ADD CONSTRAINT return_log_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_rest_kitchen_items rex_001_01_rest_kitchen_items_pkey; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_01_rest_kitchen_items
    ADD CONSTRAINT rex_001_01_rest_kitchen_items_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_rest_kitchen_orders rex_001_01_rest_kitchen_orders_pkey; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_01_rest_kitchen_orders
    ADD CONSTRAINT rex_001_01_rest_kitchen_orders_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_rest_order_items rex_001_01_rest_order_items_pkey; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_01_rest_order_items
    ADD CONSTRAINT rex_001_01_rest_order_items_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_rest_orders rex_001_01_rest_orders_order_no_key; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_01_rest_orders
    ADD CONSTRAINT rex_001_01_rest_orders_order_no_key UNIQUE (order_no);


--
-- Name: rex_001_01_rest_orders rex_001_01_rest_orders_pkey; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_01_rest_orders
    ADD CONSTRAINT rex_001_01_rest_orders_pkey PRIMARY KEY (id);


--
-- Name: rex_001_01_rest_reservations rex_001_01_rest_reservations_pkey; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_01_rest_reservations
    ADD CONSTRAINT rex_001_01_rest_reservations_pkey PRIMARY KEY (id);


--
-- Name: rex_001_rest_recipe_ingredients rex_001_rest_recipe_ingredients_pkey; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_rest_recipe_ingredients
    ADD CONSTRAINT rex_001_rest_recipe_ingredients_pkey PRIMARY KEY (id);


--
-- Name: rex_001_rest_recipes rex_001_rest_recipes_pkey; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_rest_recipes
    ADD CONSTRAINT rex_001_rest_recipes_pkey PRIMARY KEY (id);


--
-- Name: rex_001_rest_staff rex_001_rest_staff_pin_key; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_rest_staff
    ADD CONSTRAINT rex_001_rest_staff_pin_key UNIQUE (pin);


--
-- Name: rex_001_rest_staff rex_001_rest_staff_pkey; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_rest_staff
    ADD CONSTRAINT rex_001_rest_staff_pkey PRIMARY KEY (id);


--
-- Name: rex_001_rest_tables rex_001_rest_tables_pkey; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_rest_tables
    ADD CONSTRAINT rex_001_rest_tables_pkey PRIMARY KEY (id);


--
-- Name: staff_roles staff_roles_name_key; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.staff_roles
    ADD CONSTRAINT staff_roles_name_key UNIQUE (name);


--
-- Name: staff_roles staff_roles_pkey; Type: CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.staff_roles
    ADD CONSTRAINT staff_roles_pkey PRIMARY KEY (id);


--
-- Name: bins bins_pkey; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.bins
    ADD CONSTRAINT bins_pkey PRIMARY KEY (id);


--
-- Name: bins bins_store_id_code_key; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.bins
    ADD CONSTRAINT bins_store_id_code_key UNIQUE (store_id, code);


--
-- Name: counting_lines counting_lines_pkey; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.counting_lines
    ADD CONSTRAINT counting_lines_pkey PRIMARY KEY (id);


--
-- Name: counting_slips counting_slips_firm_nr_fiche_no_key; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.counting_slips
    ADD CONSTRAINT counting_slips_firm_nr_fiche_no_key UNIQUE (firm_nr, fiche_no);


--
-- Name: counting_slips counting_slips_pkey; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.counting_slips
    ADD CONSTRAINT counting_slips_pkey PRIMARY KEY (id);


--
-- Name: dispatch_lines dispatch_lines_pkey; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.dispatch_lines
    ADD CONSTRAINT dispatch_lines_pkey PRIMARY KEY (id);


--
-- Name: dispatch_slips dispatch_slips_pkey; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.dispatch_slips
    ADD CONSTRAINT dispatch_slips_pkey PRIMARY KEY (id);


--
-- Name: dispatch_slips dispatch_slips_slip_no_key; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.dispatch_slips
    ADD CONSTRAINT dispatch_slips_slip_no_key UNIQUE (slip_no);


--
-- Name: dock_doors dock_doors_code_key; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.dock_doors
    ADD CONSTRAINT dock_doors_code_key UNIQUE (code);


--
-- Name: dock_doors dock_doors_pkey; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.dock_doors
    ADD CONSTRAINT dock_doors_pkey PRIMARY KEY (id);


--
-- Name: labor_productivity labor_productivity_pkey; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.labor_productivity
    ADD CONSTRAINT labor_productivity_pkey PRIMARY KEY (id);


--
-- Name: personnel personnel_pkey; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.personnel
    ADD CONSTRAINT personnel_pkey PRIMARY KEY (id);


--
-- Name: pick_waves pick_waves_pkey; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.pick_waves
    ADD CONSTRAINT pick_waves_pkey PRIMARY KEY (id);


--
-- Name: pick_waves pick_waves_wave_no_key; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.pick_waves
    ADD CONSTRAINT pick_waves_wave_no_key UNIQUE (wave_no);


--
-- Name: receiving_lines receiving_lines_pkey; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.receiving_lines
    ADD CONSTRAINT receiving_lines_pkey PRIMARY KEY (id);


--
-- Name: receiving_slips receiving_slips_pkey; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.receiving_slips
    ADD CONSTRAINT receiving_slips_pkey PRIMARY KEY (id);


--
-- Name: receiving_slips receiving_slips_slip_no_key; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.receiving_slips
    ADD CONSTRAINT receiving_slips_slip_no_key UNIQUE (slip_no);


--
-- Name: slotting_recommendations slotting_recommendations_pkey; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.slotting_recommendations
    ADD CONSTRAINT slotting_recommendations_pkey PRIMARY KEY (id);


--
-- Name: task_queue task_queue_pkey; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.task_queue
    ADD CONSTRAINT task_queue_pkey PRIMARY KEY (id);


--
-- Name: transfer_items transfer_items_pkey; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.transfer_items
    ADD CONSTRAINT transfer_items_pkey PRIMARY KEY (id);


--
-- Name: transfers transfers_firm_nr_fiche_no_key; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.transfers
    ADD CONSTRAINT transfers_firm_nr_fiche_no_key UNIQUE (firm_nr, fiche_no);


--
-- Name: transfers transfers_pkey; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.transfers
    ADD CONSTRAINT transfers_pkey PRIMARY KEY (id);


--
-- Name: yard_locations yard_locations_code_key; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.yard_locations
    ADD CONSTRAINT yard_locations_code_key UNIQUE (code);


--
-- Name: yard_locations yard_locations_pkey; Type: CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.yard_locations
    ADD CONSTRAINT yard_locations_pkey PRIMARY KEY (id);


--
-- Name: rex_001_follow_up_reminder_actions_postponed_idx; Type: INDEX; Schema: beauty; Owner: -
--

CREATE INDEX rex_001_follow_up_reminder_actions_postponed_idx ON beauty.rex_001_follow_up_reminder_actions USING btree (postponed_due_date);


--
-- Name: rex_001_follow_up_reminder_actions_uniq; Type: INDEX; Schema: beauty; Owner: -
--

CREATE UNIQUE INDEX rex_001_follow_up_reminder_actions_uniq ON beauty.rex_001_follow_up_reminder_actions USING btree (customer_id, service_id, COALESCE(product_id, '00000000-0000-0000-0000-000000000000'::uuid), last_completed_date, natural_due_date, reminder_kind);


--
-- Name: idx_gib_edoc_firm_period; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_gib_edoc_firm_period ON public.gib_edocument_queue USING btree (firm_nr, period_nr, created_at DESC);


--
-- Name: idx_prod_rate_history_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prod_rate_history_product_id ON public.product_exchange_rate_history USING btree (product_id);


--
-- Name: idx_return_log_created_at; Type: INDEX; Schema: rest; Owner: -
--

CREATE INDEX idx_return_log_created_at ON rest.return_log USING btree (created_at);


--
-- Name: idx_return_log_reason; Type: INDEX; Schema: rest; Owner: -
--

CREATE INDEX idx_return_log_reason ON rest.return_log USING btree (return_reason);


--
-- Name: idx_counting_lines_barcode; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_counting_lines_barcode ON wms.counting_lines USING btree (barcode);


--
-- Name: idx_counting_lines_product_id; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_counting_lines_product_id ON wms.counting_lines USING btree (product_id);


--
-- Name: idx_counting_lines_slip_id; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_counting_lines_slip_id ON wms.counting_lines USING btree (slip_id);


--
-- Name: idx_counting_slips_firm_nr; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_counting_slips_firm_nr ON wms.counting_slips USING btree (firm_nr);


--
-- Name: idx_counting_slips_status; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_counting_slips_status ON wms.counting_slips USING btree (status);


--
-- Name: idx_counting_slips_store_id; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_counting_slips_store_id ON wms.counting_slips USING btree (store_id);


--
-- Name: idx_dispatch_lines_slip; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_dispatch_lines_slip ON wms.dispatch_lines USING btree (slip_id);


--
-- Name: idx_dispatch_slips_firm; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_dispatch_slips_firm ON wms.dispatch_slips USING btree (firm_nr);


--
-- Name: idx_dispatch_slips_status; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_dispatch_slips_status ON wms.dispatch_slips USING btree (status);


--
-- Name: idx_receiving_lines_slip; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_receiving_lines_slip ON wms.receiving_lines USING btree (slip_id);


--
-- Name: idx_receiving_slips_firm; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_receiving_slips_firm ON wms.receiving_slips USING btree (firm_nr);


--
-- Name: idx_receiving_slips_status; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_receiving_slips_status ON wms.receiving_slips USING btree (status);


--
-- Name: idx_wms_pick_waves_firm_status; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_wms_pick_waves_firm_status ON wms.pick_waves USING btree (firm_nr, status, priority);


--
-- Name: idx_wms_pick_waves_status; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_wms_pick_waves_status ON wms.pick_waves USING btree (status, priority);


--
-- Name: idx_wms_task_queue_firm_status; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_wms_task_queue_firm_status ON wms.task_queue USING btree (firm_nr, status, priority);


--
-- Name: idx_wms_task_queue_status; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_wms_task_queue_status ON wms.task_queue USING btree (status, priority, assigned_to);


--
-- Name: idx_wms_task_queue_type; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_wms_task_queue_type ON wms.task_queue USING btree (task_type, status);


--
-- Name: idx_wms_yard_firm_status; Type: INDEX; Schema: wms; Owner: -
--

CREATE INDEX idx_wms_yard_firm_status ON wms.yard_locations USING btree (firm_nr, status);


--
-- Name: rex_001_01_bank_lines sync_trg_rex_001_01_bank_lines; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_01_bank_lines AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_01_bank_lines FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_01_cash_lines sync_trg_rex_001_01_cash_lines; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_01_cash_lines AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_01_cash_lines FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_01_sales sync_trg_rex_001_01_sales; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_01_sales AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_01_sales FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_01_stock_movement_items sync_trg_rex_001_01_stock_movement_items; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_01_stock_movement_items AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_01_stock_movement_items FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_01_stock_movements sync_trg_rex_001_01_stock_movements; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_01_stock_movements AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_01_stock_movements FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_bank_registers sync_trg_rex_001_bank_registers; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_bank_registers AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_bank_registers FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_brands sync_trg_rex_001_brands; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_brands AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_brands FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_campaigns sync_trg_rex_001_campaigns; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_campaigns AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_campaigns FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_cash_registers sync_trg_rex_001_cash_registers; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_cash_registers AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_cash_registers FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_categories sync_trg_rex_001_categories; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_categories AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_categories FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_customers sync_trg_rex_001_customers; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_customers AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_customers FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_expense_cards sync_trg_rex_001_expense_cards; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_expense_cards AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_expense_cards FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_products sync_trg_rex_001_products; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_products AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_products FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_sales_reps sync_trg_rex_001_sales_reps; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_sales_reps AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_sales_reps FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_services sync_trg_rex_001_services; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_services AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_services FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_special_codes sync_trg_rex_001_special_codes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_special_codes AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_special_codes FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_suppliers sync_trg_rex_001_suppliers; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_suppliers AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_suppliers FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_tax_rates sync_trg_rex_001_tax_rates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_tax_rates AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_tax_rates FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: rex_001_units sync_trg_rex_001_units; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_trg_rex_001_units AFTER INSERT OR DELETE OR UPDATE ON public.rex_001_units FOR EACH ROW EXECUTE FUNCTION public.enqueue_sync_event();


--
-- Name: counting_lines trg_counting_lines_updated_at; Type: TRIGGER; Schema: wms; Owner: -
--

CREATE TRIGGER trg_counting_lines_updated_at BEFORE UPDATE ON wms.counting_lines FOR EACH ROW EXECUTE FUNCTION wms.update_counting_slips_updated_at();


--
-- Name: counting_slips trg_counting_slips_updated_at; Type: TRIGGER; Schema: wms; Owner: -
--

CREATE TRIGGER trg_counting_slips_updated_at BEFORE UPDATE ON wms.counting_slips FOR EACH ROW EXECUTE FUNCTION wms.update_counting_slips_updated_at();


--
-- Name: dock_doors trg_wms_dock_updated; Type: TRIGGER; Schema: wms; Owner: -
--

CREATE TRIGGER trg_wms_dock_updated BEFORE UPDATE ON wms.dock_doors FOR EACH ROW EXECUTE FUNCTION wms.update_timestamp();


--
-- Name: pick_waves trg_wms_pick_waves_updated; Type: TRIGGER; Schema: wms; Owner: -
--

CREATE TRIGGER trg_wms_pick_waves_updated BEFORE UPDATE ON wms.pick_waves FOR EACH ROW EXECUTE FUNCTION wms.update_timestamp();


--
-- Name: task_queue trg_wms_task_queue_updated; Type: TRIGGER; Schema: wms; Owner: -
--

CREATE TRIGGER trg_wms_task_queue_updated BEFORE UPDATE ON wms.task_queue FOR EACH ROW EXECUTE FUNCTION wms.update_timestamp();


--
-- Name: yard_locations trg_wms_yard_updated; Type: TRIGGER; Schema: wms; Owner: -
--

CREATE TRIGGER trg_wms_yard_updated BEFORE UPDATE ON wms.yard_locations FOR EACH ROW EXECUTE FUNCTION wms.update_timestamp();


--
-- Name: rex_001_beauty_satisfaction_questions rex_001_beauty_satisfaction_questions_survey_id_fkey; Type: FK CONSTRAINT; Schema: beauty; Owner: -
--

ALTER TABLE ONLY beauty.rex_001_beauty_satisfaction_questions
    ADD CONSTRAINT rex_001_beauty_satisfaction_questions_survey_id_fkey FOREIGN KEY (survey_id) REFERENCES beauty.rex_001_beauty_satisfaction_surveys(id) ON DELETE CASCADE;


--
-- Name: categories categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.categories(id);


--
-- Name: periods periods_firm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periods
    ADD CONSTRAINT periods_firm_id_fkey FOREIGN KEY (firm_id) REFERENCES public.firms(id) ON DELETE CASCADE;


--
-- Name: rex_001_01_sale_items rex_001_01_sale_items_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_sale_items
    ADD CONSTRAINT rex_001_01_sale_items_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.rex_001_01_sales(id) ON DELETE CASCADE;


--
-- Name: rex_001_01_sales rex_001_01_sales_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_sales
    ADD CONSTRAINT rex_001_01_sales_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.stores(id);


--
-- Name: rex_001_01_stock_movement_items rex_001_01_stock_movement_items_movement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_stock_movement_items
    ADD CONSTRAINT rex_001_01_stock_movement_items_movement_id_fkey FOREIGN KEY (movement_id) REFERENCES public.rex_001_01_stock_movements(id) ON DELETE CASCADE;


--
-- Name: rex_001_01_stock_movements rex_001_01_stock_movements_target_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_stock_movements
    ADD CONSTRAINT rex_001_01_stock_movements_target_warehouse_id_fkey FOREIGN KEY (target_warehouse_id) REFERENCES public.stores(id);


--
-- Name: rex_001_01_stock_movements rex_001_01_stock_movements_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_stock_movements
    ADD CONSTRAINT rex_001_01_stock_movements_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.stores(id);


--
-- Name: rex_001_01_virman_items rex_001_01_virman_items_virman_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rex_001_01_virman_items
    ADD CONSTRAINT rex_001_01_virman_items_virman_id_fkey FOREIGN KEY (virman_id) REFERENCES public.rex_001_01_virman_operations(id) ON DELETE CASCADE;


--
-- Name: service_transactions service_transactions_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_transactions
    ADD CONSTRAINT service_transactions_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.stores(id);


--
-- Name: sync_queue sync_queue_target_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_queue
    ADD CONSTRAINT sync_queue_target_store_id_fkey FOREIGN KEY (target_store_id) REFERENCES public.stores(id);


--
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: users users_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.stores(id);


--
-- Name: floors floors_store_id_fkey; Type: FK CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.floors
    ADD CONSTRAINT floors_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: kroki_layouts kroki_layouts_store_id_fkey; Type: FK CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.kroki_layouts
    ADD CONSTRAINT kroki_layouts_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: printer_profiles printer_profiles_store_id_fkey; Type: FK CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.printer_profiles
    ADD CONSTRAINT printer_profiles_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: rex_001_01_rest_kitchen_items rex_001_01_rest_kitchen_items_kitchen_order_id_fkey; Type: FK CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_01_rest_kitchen_items
    ADD CONSTRAINT rex_001_01_rest_kitchen_items_kitchen_order_id_fkey FOREIGN KEY (kitchen_order_id) REFERENCES rest.rex_001_01_rest_kitchen_orders(id) ON DELETE CASCADE;


--
-- Name: rex_001_01_rest_kitchen_items rex_001_01_rest_kitchen_items_order_item_id_fkey; Type: FK CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_01_rest_kitchen_items
    ADD CONSTRAINT rex_001_01_rest_kitchen_items_order_item_id_fkey FOREIGN KEY (order_item_id) REFERENCES rest.rex_001_01_rest_order_items(id) ON DELETE CASCADE;


--
-- Name: rex_001_01_rest_kitchen_orders rex_001_01_rest_kitchen_orders_order_id_fkey; Type: FK CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_01_rest_kitchen_orders
    ADD CONSTRAINT rex_001_01_rest_kitchen_orders_order_id_fkey FOREIGN KEY (order_id) REFERENCES rest.rex_001_01_rest_orders(id) ON DELETE CASCADE;


--
-- Name: rex_001_01_rest_order_items rex_001_01_rest_order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_01_rest_order_items
    ADD CONSTRAINT rex_001_01_rest_order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES rest.rex_001_01_rest_orders(id) ON DELETE CASCADE;


--
-- Name: rex_001_01_rest_orders rex_001_01_rest_orders_floor_id_fkey; Type: FK CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_01_rest_orders
    ADD CONSTRAINT rex_001_01_rest_orders_floor_id_fkey FOREIGN KEY (floor_id) REFERENCES rest.floors(id);


--
-- Name: rex_001_rest_recipe_ingredients rex_001_rest_recipe_ingredients_recipe_id_fkey; Type: FK CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_rest_recipe_ingredients
    ADD CONSTRAINT rex_001_rest_recipe_ingredients_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES rest.rex_001_rest_recipes(id) ON DELETE CASCADE;


--
-- Name: rex_001_rest_tables rex_001_rest_tables_floor_id_fkey; Type: FK CONSTRAINT; Schema: rest; Owner: -
--

ALTER TABLE ONLY rest.rex_001_rest_tables
    ADD CONSTRAINT rex_001_rest_tables_floor_id_fkey FOREIGN KEY (floor_id) REFERENCES rest.floors(id);


--
-- Name: bins bins_store_id_fkey; Type: FK CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.bins
    ADD CONSTRAINT bins_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.stores(id);


--
-- Name: counting_lines counting_lines_bin_id_fkey; Type: FK CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.counting_lines
    ADD CONSTRAINT counting_lines_bin_id_fkey FOREIGN KEY (bin_id) REFERENCES wms.bins(id);


--
-- Name: counting_lines counting_lines_slip_id_fkey; Type: FK CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.counting_lines
    ADD CONSTRAINT counting_lines_slip_id_fkey FOREIGN KEY (slip_id) REFERENCES wms.counting_slips(id) ON DELETE CASCADE;


--
-- Name: dispatch_lines dispatch_lines_slip_id_fkey; Type: FK CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.dispatch_lines
    ADD CONSTRAINT dispatch_lines_slip_id_fkey FOREIGN KEY (slip_id) REFERENCES wms.dispatch_slips(id) ON DELETE CASCADE;


--
-- Name: dispatch_slips dispatch_slips_store_id_fkey; Type: FK CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.dispatch_slips
    ADD CONSTRAINT dispatch_slips_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.stores(id);


--
-- Name: dock_doors dock_doors_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.dock_doors
    ADD CONSTRAINT dock_doors_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.stores(id) ON DELETE SET NULL;


--
-- Name: labor_productivity labor_productivity_user_id_fkey; Type: FK CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.labor_productivity
    ADD CONSTRAINT labor_productivity_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: personnel personnel_store_id_fkey; Type: FK CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.personnel
    ADD CONSTRAINT personnel_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.stores(id);


--
-- Name: personnel personnel_user_id_fkey; Type: FK CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.personnel
    ADD CONSTRAINT personnel_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: pick_waves pick_waves_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.pick_waves
    ADD CONSTRAINT pick_waves_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.stores(id) ON DELETE SET NULL;


--
-- Name: receiving_lines receiving_lines_slip_id_fkey; Type: FK CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.receiving_lines
    ADD CONSTRAINT receiving_lines_slip_id_fkey FOREIGN KEY (slip_id) REFERENCES wms.receiving_slips(id) ON DELETE CASCADE;


--
-- Name: receiving_slips receiving_slips_store_id_fkey; Type: FK CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.receiving_slips
    ADD CONSTRAINT receiving_slips_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.stores(id);


--
-- Name: task_queue task_queue_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.task_queue
    ADD CONSTRAINT task_queue_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.stores(id) ON DELETE SET NULL;


--
-- Name: transfer_items transfer_items_transfer_id_fkey; Type: FK CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.transfer_items
    ADD CONSTRAINT transfer_items_transfer_id_fkey FOREIGN KEY (transfer_id) REFERENCES wms.transfers(id) ON DELETE CASCADE;


--
-- Name: yard_locations yard_locations_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: wms; Owner: -
--

ALTER TABLE ONLY wms.yard_locations
    ADD CONSTRAINT yard_locations_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.stores(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict 0oC8l3COQFEqbTjRT8jl1ohTJ2JagdVK3mgjVDbdezkURkxg5aiErzRXyyBIyZk

