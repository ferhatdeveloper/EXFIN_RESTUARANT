-- RetailEX Raporlama Şeması (EXFIN uyarlaması)
-- Kaynak: ferhatdeveloper/RetailEX - reporting tabloları

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- REPORT BUILDER TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS report_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT CHECK (
      category IN ('sales', 'inventory', 'finance', 'hr', 'custom')
    ),
    is_system BOOLEAN DEFAULT false,
    created_by INTEGER REFERENCES users(id),

    data_source TEXT NOT NULL,
    query TEXT,
    columns JSONB NOT NULL,
    filters JSONB,
    grouping JSONB,
    sorting JSONB,
    aggregations JSONB,
    chart_config JSONB,

    is_public BOOLEAN DEFAULT false,
    shared_with INTEGER[],

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS scheduled_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID REFERENCES report_templates(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    schedule_type TEXT CHECK (
      schedule_type IN ('daily', 'weekly', 'monthly', 'custom')
    ),
    schedule_config JSONB,

    delivery_method TEXT[] DEFAULT ARRAY['email'],
    recipients TEXT[],
    export_format TEXT[] DEFAULT ARRAY['pdf'],

    is_active BOOLEAN DEFAULT true,
    last_run_at TIMESTAMPTZ,
    next_run_at TIMESTAMPTZ,

    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS report_executions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID REFERENCES report_templates(id) ON DELETE SET NULL,
    scheduled_report_id UUID REFERENCES scheduled_reports(id) ON DELETE SET NULL,
    executed_by INTEGER REFERENCES users(id),

    status TEXT DEFAULT 'running' CHECK (
      status IN ('running', 'completed', 'failed')
    ),
    execution_time_ms INTEGER,
    row_count INTEGER,
    file_url TEXT,
    file_size_bytes INTEGER,
    error_message TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_report_templates_category
  ON report_templates(category);
CREATE INDEX IF NOT EXISTS idx_report_templates_data_source
  ON report_templates(data_source);
CREATE INDEX IF NOT EXISTS idx_scheduled_reports_template
  ON scheduled_reports(template_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_reports_next_run
  ON scheduled_reports(next_run_at);
CREATE INDEX IF NOT EXISTS idx_report_executions_template
  ON report_executions(template_id);
CREATE INDEX IF NOT EXISTS idx_report_executions_created
  ON report_executions(created_at DESC);

-- =====================================================
-- RAPOR ÖZET VIEW
-- =====================================================

CREATE OR REPLACE VIEW v_report_execution_summary AS
SELECT
    rt.id AS template_id,
    rt.name AS template_name,
    rt.category,
    COUNT(re.id) AS execution_count,
    COUNT(re.id) FILTER (WHERE re.status = 'completed') AS completed_count,
    COUNT(re.id) FILTER (WHERE re.status = 'failed') AS failed_count,
    AVG(re.execution_time_ms) AS avg_execution_time_ms,
    MAX(re.created_at) AS last_execution_at
FROM report_templates rt
LEFT JOIN report_executions re ON re.template_id = rt.id
GROUP BY rt.id, rt.name, rt.category;

-- =====================================================
-- ÖRNEK ŞABLONLAR
-- =====================================================

INSERT INTO report_templates (
  name,
  description,
  category,
  is_system,
  data_source,
  columns,
  chart_config,
  is_public
)
VALUES
(
  'Günlük Satış Raporu',
  'Günlük satış özeti - mağaza/masa kırılımı',
  'sales',
  true,
  'orders',
  '[
    {"field":"created_at","label":"Tarih","type":"date"},
    {"field":"table_id","label":"Masa","type":"number"},
    {"field":"final_amount","label":"Net Tutar","type":"currency","aggregate":"sum"},
    {"field":"payment_status","label":"Ödeme Durumu","type":"text"}
  ]'::jsonb,
  '{"type":"bar","x":"created_at","y":"final_amount"}'::jsonb,
  true
),
(
  'En Çok Satan Ürünler',
  'Sipariş kalemlerine göre ürün satış analizi',
  'sales',
  true,
  'order_items',
  '[
    {"field":"product_id","label":"Ürün","type":"number"},
    {"field":"quantity","label":"Adet","type":"number","aggregate":"sum"},
    {"field":"total_price","label":"Ciro","type":"currency","aggregate":"sum"}
  ]'::jsonb,
  '{"type":"pie","labels":"product_id","values":"quantity"}'::jsonb,
  true
)
ON CONFLICT DO NOTHING;
