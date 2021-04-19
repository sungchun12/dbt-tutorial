--Note: it only works on Snowflake, and assumes that you don’t use mutliple schemata.
-- goal: clone schema from prod to target database configured in my `profiles.yml`(get same columns and data types)

{% macro clone_prod_to_target(from) %} -- name of the macro with a variable parameter

    {% set sql -%}
        create schema if not exists {{ target.database }}.{{ target.schema }} clone {{ from }};
    {%- endset %}

    {{ dbt_utils.log_info("Cloning schema " ~ from ~ " into target schema.") }}

    {% do run_query(sql) %}

    {{ dbt_utils.log_info("Cloned schema " ~ from ~ " into target schema.") }}

{% endmacro %}

-- destroy the existing dev schemas in my target
{% macro destroy_current_env() %}

    {% set sql -%}
        drop schema if exists {{ target.database }}.{{ target.schema }} cascade;
    {%- endset %}

    {{ dbt_utils.log_info("Dropping target schema.") }}

    {% do run_query(sql) %}

    {{ dbt_utils.log_info("Dropped target schema.") }}

{% endmacro %}

-- bundles the 2 macros above together in a procedural order
{% macro reset_dev_env(from) %}
{#-
This macro destroys your current development environment, and recreates it by cloning from prod.

To run it:
    $ dbt run-operation reset_dev_env --args '{from: analytics}'

-#}
    {% if target.name == 'dev' %}

    {{ destroy_current_env() }}

    {{ clone_prod_to_target(from) }}

    {% else %}

    {{ dbt_utils.log_info("No-op: your current target is " ~ target.name ~ ". This macro only works for a dev target.", info=True) }}

    {% endif %}

{% endmacro %}