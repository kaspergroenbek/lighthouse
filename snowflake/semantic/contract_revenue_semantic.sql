-- =============================================================================
-- Snowflake Semantic View: Contract & Revenue Domain
-- Enables Cortex Analyst natural-language querying over billing data
-- =============================================================================

SET LIGHTHOUSE_ENV = 'PROD';
SET LIGHTHOUSE_ANALYTICS_DB = 'LIGHTHOUSE_' || $LIGHTHOUSE_ENV || '_ANALYTICS';

EXECUTE IMMEDIATE 'USE DATABASE ' || $LIGHTHOUSE_ANALYTICS_DB;
USE SCHEMA SEMANTIC;

CREATE OR REPLACE SEMANTIC VIEW contract_revenue_analysis

  TABLES (
    invoices AS MARTS.fct_invoices
      PRIMARY KEY (invoice_line_sk)
      COMMENT = 'Invoice line items - grain: one row per invoice line item',

    payments AS MARTS.fct_payments
      PRIMARY KEY (payment_sk)
      COMMENT = 'Individual payments - grain: one row per payment',

    customers AS MARTS.dim_customer
      PRIMARY KEY (customer_sk)
      COMMENT = 'Customer dimension (SCD2) - grain: one row per customer version',

    contracts AS MARTS.dim_contract
      PRIMARY KEY (contract_sk)
      COMMENT = 'Contract dimension (SCD2) - grain: one row per contract version',

    products AS MARTS.dim_product
      PRIMARY KEY (product_sk)
      COMMENT = 'Product/service offering dimension',

    dates AS MARTS.dim_date
      PRIMARY KEY (date_key)
      COMMENT = 'Calendar date dimension (2020-2030)'
  )

  RELATIONSHIPS (
    invoices (customer_sk) REFERENCES customers (customer_sk),
    invoices (contract_sk) REFERENCES contracts (contract_sk),
    invoices (product_sk) REFERENCES products (product_sk),
    invoices (invoice_date_key) REFERENCES dates (date_key),
    payments (customer_sk) REFERENCES customers (customer_sk),
    payments (contract_sk) REFERENCES contracts (contract_sk),
    payments (payment_date_key) REFERENCES dates (date_key)
  )

  FACTS (
    invoices.amount
      COMMENT = 'Invoice line item amount (DKK)'
      SYNONYMS = ('revenue', 'sales amount', 'line amount'),
    invoices.quantity
      COMMENT = 'Quantity of items on the invoice line',
    invoices.tax_amount
      COMMENT = 'Tax amount on the invoice line',
    invoices.net_amount
      COMMENT = 'Net amount after tax'
      SYNONYMS = ('net revenue', 'after-tax amount'),
    payments.payment_amount
      COMMENT = 'Payment amount received (DKK)'
      SYNONYMS = ('payment', 'amount paid', 'cash received')
  )

  DIMENSIONS (
    customers.full_name
      COMMENT = 'Customer full name'
      SYNONYMS = ('customer name', 'name'),
    customers.email
      COMMENT = 'Customer email address',
    customers.segment
      COMMENT = 'Customer segment (residential, commercial, premium)'
      SYNONYMS = ('customer segment', 'customer type'),
    customers.region
      COMMENT = 'Nordic region'
      SYNONYMS = ('area', 'geography'),
    customers.country
      COMMENT = 'Country code (DK, SE, NO, FI)',
    customers.is_current
      COMMENT = 'Whether this is the current customer version (TRUE/FALSE)',

    contracts.contract_type
      COMMENT = 'Contract type (residential_energy, commercial_energy)'
      SYNONYMS = ('type of contract', 'contract category'),
    contracts.status
      COMMENT = 'Contract status (active, renewed, cancelled, expired)'
      SYNONYMS = ('contract status', 'contract state'),

    products.product_name
      COMMENT = 'Product or service name'
      SYNONYMS = ('product', 'item'),
    products.category
      COMMENT = 'Product category (device, service, bundle)',
    products.pricing_tier
      COMMENT = 'Pricing tier classification',

    invoices.revenue_classification
      COMMENT = 'Revenue classification (hardware, service, bundle, other)'
      SYNONYMS = ('revenue type', 'revenue category'),
    invoices.invoice_status
      COMMENT = 'Invoice status',

    payments.payment_method
      COMMENT = 'Payment method (card, bank_transfer)'
      SYNONYMS = ('how paid', 'payment type'),
    payments.is_late_payment
      COMMENT = 'Whether payment was late (TRUE/FALSE)'
      SYNONYMS = ('late payment', 'overdue'),

    dates.full_date
      COMMENT = 'Calendar date'
      SYNONYMS = ('date', 'day'),
    dates.month_name
      COMMENT = 'Month name'
      SYNONYMS = ('month'),
    dates.quarter
      COMMENT = 'Calendar quarter (1-4)',
    dates.year
      COMMENT = 'Calendar year'
      SYNONYMS = ('yr'),
    dates.fiscal_year
      COMMENT = 'Fiscal year',
    dates.fiscal_quarter
      COMMENT = 'Fiscal quarter'
  )

  METRICS (
    total_revenue AS SUM(invoices.amount)
      COMMENT = 'Total revenue - sum of all invoice line item amounts'
      SYNONYMS = ('revenue', 'total sales', 'gross revenue'),
    total_payments AS SUM(payments.payment_amount)
      COMMENT = 'Total payments received'
      SYNONYMS = ('cash collected', 'total collected'),
    invoice_count AS COUNT(invoices.invoice_line_sk)
      COMMENT = 'Number of invoice line items'
      SYNONYMS = ('number of invoices', 'invoice volume'),
    average_invoice_amount AS AVG(invoices.amount)
      COMMENT = 'Average invoice line item amount'
      SYNONYMS = ('avg invoice', 'mean invoice amount'),
    late_payment_count AS COUNT_IF(payments.is_late_payment = TRUE)
      COMMENT = 'Number of late payments'
      SYNONYMS = ('overdue payments', 'late payments')
  )
;
