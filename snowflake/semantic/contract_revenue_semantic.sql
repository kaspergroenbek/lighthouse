-- =============================================================================
-- Snowflake Semantic View: Contract & Revenue Domain
-- Enables Cortex Analyst natural-language querying over billing data
-- =============================================================================

SET LIGHTHOUSE_ENV = '{{ env }}';
SET LIGHTHOUSE_ANALYTICS_DB = 'LIGHTHOUSE_' || $LIGHTHOUSE_ENV || '_ANALYTICS';

EXECUTE IMMEDIATE 'USE DATABASE ' || $LIGHTHOUSE_ANALYTICS_DB;
USE SCHEMA SEMANTIC;

CREATE OR REPLACE SEMANTIC VIEW contract_revenue_analysis
  TABLES (
    invoices AS MARTS.fct_invoices
      PRIMARY KEY (invoice_line_sk)
      COMMENT = 'Invoice line items at invoice line grain',

    payments AS MARTS.fct_payments
      PRIMARY KEY (payment_sk)
      COMMENT = 'Payments at payment grain',

    customers AS MARTS.dim_customer
      PRIMARY KEY (customer_sk)
      COMMENT = 'Customer dimension (SCD2)',

    contracts AS MARTS.dim_contract
      PRIMARY KEY (contract_sk)
      COMMENT = 'Contract dimension (SCD2)',

    products AS MARTS.dim_product
      PRIMARY KEY (product_sk)
      COMMENT = 'Product dimension',

    dates AS MARTS.dim_date
      PRIMARY KEY (date_key)
      COMMENT = 'Calendar date dimension'
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
    invoices.revenue_amount AS invoices.amount
      WITH SYNONYMS ('revenue', 'sales amount', 'line amount')
      COMMENT = 'Invoice line amount in DKK',

    invoices.quantity AS invoices.quantity
      COMMENT = 'Quantity on the invoice line',

    invoices.tax_amount AS invoices.tax_amount
      COMMENT = 'Tax amount on the invoice line',

    invoices.net_amount AS invoices.net_amount
      WITH SYNONYMS ('net revenue', 'after tax amount')
      COMMENT = 'Net amount after tax',

    payments.payment_amount AS payments.payment_amount
      WITH SYNONYMS ('payment', 'amount paid', 'cash received')
      COMMENT = 'Payment amount received in DKK'
  )

  DIMENSIONS (
    customers.customer_id AS customers.customer_id
      COMMENT = 'Customer identifier',

    customers.email AS customers.email
      COMMENT = 'Customer email address',

    customers.segment AS customers.segment
      WITH SYNONYMS ('customer segment', 'customer type')
      COMMENT = 'Customer segment',

    customers.region AS customers.region
      WITH SYNONYMS ('area', 'geography')
      COMMENT = 'Nordic region',

    customers.country AS customers.country
      COMMENT = 'Country code',

    customers.is_current AS customers.is_current
      COMMENT = 'Whether the customer version is current',

    contracts.contract_type AS contracts.contract_type
      WITH SYNONYMS ('type of contract', 'contract category')
      COMMENT = 'Contract type',

    contracts.status AS contracts.status
      WITH SYNONYMS ('contract status', 'contract state')
      COMMENT = 'Contract status',

    products.product_name AS products.product_name
      WITH SYNONYMS ('product', 'item')
      COMMENT = 'Product or service name',

    products.category AS products.category
      COMMENT = 'Product category',

    products.pricing_tier AS products.pricing_tier
      COMMENT = 'Pricing tier classification',

    invoices.revenue_classification AS invoices.revenue_classification
      WITH SYNONYMS ('revenue type', 'revenue category')
      COMMENT = 'Revenue classification',

    invoices.invoice_status AS invoices.invoice_status
      COMMENT = 'Invoice status',

    payments.payment_method AS payments.payment_method
      WITH SYNONYMS ('how paid', 'payment type')
      COMMENT = 'Payment method',

    payments.payment_status AS payments.payment_status
      COMMENT = 'Payment status',

    payments.is_late_payment AS payments.is_late_payment
      WITH SYNONYMS ('late payment', 'overdue')
      COMMENT = 'Whether payment was late',

    dates.full_date AS dates.full_date
      WITH SYNONYMS ('date', 'day')
      COMMENT = 'Calendar date',

    dates.month_name AS dates.month_name
      WITH SYNONYMS ('month')
      COMMENT = 'Month name',

    dates.quarter AS dates.quarter
      COMMENT = 'Calendar quarter',

    dates.year AS dates.year
      WITH SYNONYMS ('yr')
      COMMENT = 'Calendar year',

    dates.fiscal_year AS dates.fiscal_year
      COMMENT = 'Fiscal year',

    dates.fiscal_quarter AS dates.fiscal_quarter
      COMMENT = 'Fiscal quarter'
  )

  METRICS (
    total_revenue AS SUM(invoices.revenue_amount)
      WITH SYNONYMS ('revenue', 'total sales', 'gross revenue')
      COMMENT = 'Total revenue',

    total_payments AS SUM(payments.payment_amount)
      WITH SYNONYMS ('cash collected', 'total collected')
      COMMENT = 'Total payments received',

    invoice_count AS COUNT(invoices.invoice_line_sk)
      WITH SYNONYMS ('number of invoices', 'invoice volume')
      COMMENT = 'Number of invoice line items',

    average_invoice_amount AS AVG(invoices.revenue_amount)
      WITH SYNONYMS ('avg invoice', 'mean invoice amount')
      COMMENT = 'Average invoice line amount',

    late_payment_count AS COUNT_IF(payments.is_late_payment = TRUE)
      WITH SYNONYMS ('overdue payments', 'late payments')
      COMMENT = 'Number of late payments'
  )
;
