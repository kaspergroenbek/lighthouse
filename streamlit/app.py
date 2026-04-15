"""
Lighthouse Data Platform - Streamlit in Snowflake Application
Two tabs: (1) Customer & Contract Lookup, (2) Knowledge Base Search
Runs under a Snowflake role with access to the analytics marts.
"""

import streamlit as st
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="Lighthouse Data Platform", layout="wide")


@st.cache_resource(show_spinner=False)
def get_session():
    return get_active_session()


@st.cache_data(show_spinner=False)
def get_analytics_db() -> str:
    session = get_session()
    current_db = session.sql("SELECT CURRENT_DATABASE()").collect()[0][0]
    if current_db and current_db.upper().endswith("_SERVING"):
        return current_db.upper().replace("_SERVING", "_ANALYTICS")
    return "LIGHTHOUSE_PROD_ANALYTICS"


@st.cache_data(show_spinner=False)
def knowledge_search_available(analytics_db: str) -> bool:
    session = get_session()
    try:
        session.sql(
            f"""
            SHOW CORTEX SEARCH SERVICES IN SCHEMA {analytics_db}.MARTS
            """
        ).collect()
        rows = session.sql(
            f"""
            SHOW CORTEX SEARCH SERVICES IN SCHEMA {analytics_db}.MARTS
            """
        ).collect()
        return any(str(row[1]).upper() == "KNOWLEDGE_SEARCH_SERVICE" for row in rows)
    except Exception:
        return False


@st.cache_data(show_spinner=False)
def run_query(sql: str):
    return get_session().sql(sql).to_pandas()


try:
    ANALYTICS_DB = get_analytics_db()
    CORTEX_AVAILABLE = knowledge_search_available(ANALYTICS_DB)
except Exception as exc:
    st.error(f"Unable to initialize the Snowflake session for the app: {exc}")
    st.stop()


st.title("Lighthouse - NordHjem Energy Data Platform")
st.caption(f"Connected to analytics database: `{ANALYTICS_DB}`")

tab1, tab2 = st.tabs(["Customer & Contract Lookup", "Knowledge Base Search"])

with tab1:
    st.header("Customer & Contract Lookup")

    search_term = st.text_input(
        "Search by customer email or name",
        placeholder="e.g. lars@example.dk"
    )

    if search_term:
        safe_search = search_term.replace("'", "''")
        try:
            customers_df = run_query(f"""
                SELECT
                    customer_id, email, first_name, last_name,
                    segment, region, country, status,
                    total_contracts, active_contracts,
                    active_device_count, lifetime_invoice_total,
                    total_service_tickets
                FROM {ANALYTICS_DB}.MARTS.customer_360
                WHERE LOWER(email) LIKE LOWER('%{safe_search}%')
                   OR LOWER(first_name || ' ' || last_name) LIKE LOWER('%{safe_search}%')
                LIMIT 20
            """)
        except Exception as exc:
            st.error(f"Customer search failed: {exc}")
            customers_df = None

        if customers_df is None:
            pass
        elif customers_df.empty:
            st.info("No customers found.")
        else:
            st.dataframe(customers_df, use_container_width=True)

            selected_customer = st.selectbox(
                "Select a customer for details",
                customers_df["CUSTOMER_ID"].tolist()
            )

            if selected_customer:
                try:
                    st.subheader("Contracts")
                    contracts_df = run_query(f"""
                        SELECT
                            c.contract_id, c.contract_type, c.status,
                            c.start_date, c.end_date, c.monthly_amount
                        FROM {ANALYTICS_DB}.MARTS.dim_contract c
                        WHERE c.customer_id = '{selected_customer}'
                          AND c.is_current = TRUE
                        ORDER BY c.start_date DESC
                    """)
                    st.dataframe(contracts_df, use_container_width=True)

                    st.subheader("Recent Invoices")
                    invoices_df = run_query(f"""
                        SELECT
                            i.invoice_id, i.line_description,
                            i.quantity, i.amount, i.tax_amount, i.net_amount,
                            i.invoice_status, i.revenue_classification
                        FROM {ANALYTICS_DB}.MARTS.fct_invoices i
                        INNER JOIN {ANALYTICS_DB}.MARTS.dim_customer dc
                            ON i.customer_sk = dc.customer_sk
                        WHERE dc.customer_id = '{selected_customer}'
                          AND dc.is_current = TRUE
                        ORDER BY i.invoice_date_key DESC
                        LIMIT 25
                    """)
                    st.dataframe(invoices_df, use_container_width=True)
                except Exception as exc:
                    st.error(f"Customer detail lookup failed: {exc}")

with tab2:
    st.header("Knowledge Base Search")
    st.caption("Semantic search over product manuals, procedures, and support articles")

    if not CORTEX_AVAILABLE:
        st.info(
            "Cortex Search is not available in this Snowflake account or the knowledge search service has not been created yet. "
            "The rest of the app can still be used normally."
        )
    else:
        query = st.text_input(
            "Ask a question",
            placeholder="e.g. How do I update thermostat firmware?"
        )

        category_filter = st.selectbox(
            "Filter by category (optional)",
            ["All", "manual", "procedure", "policy", "support_article"]
        )

        if query:
            safe_query = query.replace("'", "''")
            filter_clause = ""
            if category_filter != "All":
                filter_clause = (
                    f", filter => {{'@eq': {{'document_category': '{category_filter}'}}}}"
                )

            try:
                results_df = run_query(f"""
                    SELECT *
                    FROM TABLE(
                        {ANALYTICS_DB}.MARTS.knowledge_search_service!SEARCH(
                            query => '{safe_query}',
                            columns => ['chunk_text', 'document_title', 'document_category']
                            {filter_clause},
                            limit => 5
                        )
                    )
                """)
            except Exception as exc:
                st.error(f"Knowledge search failed: {exc}")
                results_df = None

            if results_df is None:
                pass
            elif results_df.empty:
                st.info("No results found.")
            else:
                for _, row in results_df.iterrows():
                    with st.expander(
                        f"Document: {row.get('DOCUMENT_TITLE', 'Unknown')} "
                        f"({row.get('DOCUMENT_CATEGORY', '')})"
                    ):
                        st.write(row.get("CHUNK_TEXT", ""))
