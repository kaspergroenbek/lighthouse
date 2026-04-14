"""
Lighthouse Data Platform — Streamlit in Snowflake Application
Two tabs: (1) Customer & Contract Lookup, (2) Knowledge Base Search
Runs under LIGHTHOUSE_READER role, queries MARTS and SERVING schemas only.
"""

import streamlit as st
from snowflake.snowpark.context import get_active_session

session = get_active_session()

st.set_page_config(page_title="Lighthouse Data Platform", layout="wide")
st.title("Lighthouse — NordHjem Energy Data Platform")

tab1, tab2 = st.tabs(["Customer & Contract Lookup", "Knowledge Base Search"])

# ---------------------------------------------------------------------------
# Tab 1: Structured Data Query
# ---------------------------------------------------------------------------
with tab1:
    st.header("Customer & Contract Lookup")

    search_term = st.text_input(
        "Search by customer email or name",
        placeholder="e.g. lars@example.dk"
    )

    if search_term:
        customers_df = session.sql(f"""
            SELECT
                customer_id, email, first_name, last_name,
                segment, region, country, status,
                total_contracts, active_contracts,
                active_device_count, lifetime_invoice_total,
                total_service_tickets
            FROM LIGHTHOUSE_PROD_ANALYTICS.MARTS.customer_360
            WHERE LOWER(email) LIKE LOWER('%{search_term}%')
               OR LOWER(first_name || ' ' || last_name) LIKE LOWER('%{search_term}%')
            LIMIT 20
        """).to_pandas()

        if customers_df.empty:
            st.info("No customers found.")
        else:
            st.dataframe(customers_df, use_container_width=True)

            selected_customer = st.selectbox(
                "Select a customer for details",
                customers_df["CUSTOMER_ID"].tolist()
            )

            if selected_customer:
                st.subheader("Contracts")
                contracts_df = session.sql(f"""
                    SELECT
                        c.contract_id, c.contract_type, c.status,
                        c.start_date, c.end_date, c.monthly_amount
                    FROM LIGHTHOUSE_PROD_ANALYTICS.MARTS.dim_contract c
                    WHERE c.customer_id = '{selected_customer}'
                      AND c.is_current = TRUE
                    ORDER BY c.start_date DESC
                """).to_pandas()
                st.dataframe(contracts_df, use_container_width=True)

                st.subheader("Recent Invoices")
                invoices_df = session.sql(f"""
                    SELECT
                        i.invoice_id, i.line_description,
                        i.quantity, i.amount, i.tax_amount, i.net_amount,
                        i.invoice_status, i.revenue_classification
                    FROM LIGHTHOUSE_PROD_ANALYTICS.MARTS.fct_invoices i
                    INNER JOIN LIGHTHOUSE_PROD_ANALYTICS.MARTS.dim_customer dc
                        ON i.customer_sk = dc.customer_sk
                    WHERE dc.customer_id = '{selected_customer}'
                      AND dc.is_current = TRUE
                    ORDER BY i.invoice_date_key DESC
                    LIMIT 25
                """).to_pandas()
                st.dataframe(invoices_df, use_container_width=True)

# ---------------------------------------------------------------------------
# Tab 2: Knowledge Base Search (Cortex Search)
# ---------------------------------------------------------------------------
with tab2:
    st.header("Knowledge Base Search")
    st.caption("Semantic search over product manuals, procedures, and support articles")

    query = st.text_input(
        "Ask a question",
        placeholder="e.g. How do I update thermostat firmware?"
    )

    category_filter = st.selectbox(
        "Filter by category (optional)",
        ["All", "manual", "procedure", "policy", "support_article"]
    )

    if query:
        filter_clause = ""
        if category_filter != "All":
            filter_clause = (
                f", filter => {{'@eq': {{'document_category': '{category_filter}'}}}}"
            )

        results_df = session.sql(f"""
            SELECT *
            FROM TABLE(
                LIGHTHOUSE_PROD_ANALYTICS.MARTS.knowledge_search_service!SEARCH(
                    query => '{query}',
                    columns => ['chunk_text', 'document_title', 'document_category']
                    {filter_clause},
                    limit => 5
                )
            )
        """).to_pandas()

        if results_df.empty:
            st.info("No results found.")
        else:
            for _, row in results_df.iterrows():
                with st.expander(
                    f"📄 {row.get('DOCUMENT_TITLE', 'Unknown')} "
                    f"({row.get('DOCUMENT_CATEGORY', '')})"
                ):
                    st.write(row.get("CHUNK_TEXT", ""))
