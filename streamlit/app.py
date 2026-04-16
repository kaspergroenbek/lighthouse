"""
Lighthouse Data Platform - Streamlit in Snowflake Application.
Focused on the working Version 1 customer and billing experience.
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
def run_query(sql: str):
    return get_session().sql(sql).to_pandas()


try:
    ANALYTICS_DB = get_analytics_db()
except Exception as exc:
    st.error(f"Unable to initialize the Snowflake session for the app: {exc}")
    st.stop()


st.title("Lighthouse - NordHjem Energy Data Platform")
st.caption(f"Connected to analytics database: `{ANALYTICS_DB}`")
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
