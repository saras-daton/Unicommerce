{% if var('uc_saleorders') %}
{{ config( enabled = True ) }}
{% else %}
{{ config( enabled = False ) }}
{% endif %}
{% if var('currency_conversion_flag') %}
--depends_on: {{ ref('ExchangeRates') }}
{% endif %}

    {% if is_incremental() %}
    {%- set max_loaded_query -%}
    SELECT coalesce(MAX(_daton_batch_runtime) - 2592000000,0) FROM {{ this }}
    {% endset %}

    {%- set max_loaded_results = run_query(max_loaded_query) -%}

    {%- if execute -%}
    {% set max_loaded = max_loaded_results.rows[0].values()[0] %}
    {% else %}
    {% set max_loaded = 0 %}
    {%- endif -%}
    {% endif %}

    {% set table_name_query %}
     {{set_table_name('%saleorder%')}}    
    {% endset %} 

    {% set results = run_query(table_name_query) %}
    
    {% if execute %}
    {# Return the first column #}
    {% set results_list = results.columns[0].values() %}
    {% set tables_lowercase_list = results.columns[1].values() %}
    {% else %}
    {% set results_list = [] %}
    {% set tables_lowercase_list = [] %}
    {% endif %}

    {% for i in results_list %}
        {% if var('get_brandname_from_tablename_flag') %}
            {% set brand =i.split('.')[2].split('_')[var('brandname_position_in_tablename')] %}
        {% else %}
            {% set brand = var('default_brandname') %}
        {% endif %}

        {% if var('get_storename_from_tablename_flag') %}
            {% set store =i.split('.')[2].split('_')[var('storename_position_in_tablename')] %}
        {% else %}
            {% set store = var('default_storename') %}
        {% endif %}

        {% if var('timezone_conversion_flag') and i.lower() in tables_lowercase_list and i in var('raw_table_timezone_offset_hours') %}
            {% set hr = var('raw_table_timezone_offset_hours')[i] %}
        {% else %}
            {% set hr = 0 %}
        {% endif %}

        SELECT * {{exclude()}} (row_num)
            FROM 
            (
            select 
            '{{brand}}' as brand,
            '{{store}}' as store,
            NotificationEmail,
            NotificationMobile ,
            SaleOrderItemCode ,
            DisplayOrderCode ,
            ReversePickupCode ,
            ReversePickupCreatedDate ,
            ReversePickupReason ,
            RequireCustomization ,
            COD ,
            ShippingAddressId ,
            Category ,
            InvoiceCode ,
            InvoiceCreated ,
            ShippingAddressState ,
            ShippingAddressCountry ,
            ShippingAddressPincode ,
            BillingAddressState ,
            BillingAddressPincode ,
            ShippingMethod ,
            ItemSKUCode ,
            ChannelProductId ,
            ItemTypeName ,
            ItemTypeColor ,
            ItemTypeSize ,
            ItemTypeBrand ,
            ChannelName ,
            SKURequireCustomization ,
            GiftWrap ,
            GiftMessage ,
            HSNCode ,
            MRP ,
            totalprice ,
            SellingPrice ,
            CostPrice ,
            PrepaidAmount ,
            Subtotal ,
            Discount ,
            GSTTaxTypeCode ,
            CGST ,
            IGST ,
            SGST ,
            UTGST ,
            CESS ,
            CGSTRate ,
            IGSTRate ,
            SGSTRate ,
            UTGSTRate ,
            CESSRate ,
            Tax_ ,
            TaxValue ,
            VoucherCode ,
            ShippingCharges ,
            ShippingMethodCharges ,
            CODServiceCharges ,
            GiftWrapCharges ,
            PacketNumber ,
            CAST({{ dbt.dateadd(datepart="hour", interval=hr, from_date_or_timestamp="cast(OrderDateasdd_mm_yyyyhh_MM_ss as timestamp)") }} as {{ dbt.type_timestamp() }}) as order_date,
            SaleOrderCode ,
            OnHold ,
            SaleOrderStatus ,
            Priority ,
            Currency ,
            CurrencyConversionRate ,
            SaleOrderItemStatus ,
            CancellationReason ,
            Shippingprovider ,
            ShippingArrangedBy,
            ShippingPackageCode,
            ShippingPackageCreationDate,
            ShippingPackageStatusCode,
            ShippingPackageType,
            Length_mm_,
            Width_mm_,
            Height_mm_,
            DeliveryTime,
            TrackingNumber,
            DispatchDate,
            Facility,
            ReturnDate,
            ReturnReason,
            CAST({{ dbt.dateadd(datepart="hour", interval=hr, from_date_or_timestamp="cast(Created as timestamp)") }} as {{ dbt.type_timestamp() }}) as Created,
            CAST({{ dbt.dateadd(datepart="hour", interval=hr, from_date_or_timestamp="cast(Updated as timestamp)") }} as {{ dbt.type_timestamp() }}) as Updated,
            CombinationIdentifier,
            CombinationDescription,
            TransferPrice,
            ItemCode,
            IMEI,
            Weight,
            GSTIN,
            CustomerGSTIN,
            TIN,
            FulfillmentTAT,
            ChannelShipping,
            ItemDetails,
            EWayBillNo,
            EWayBillDate,
            EWayBillValidTill,
            TCSAmount,
            ShippingCourier,
            PaymentInstrument,
            ShippingAddressName,
            ShippingAddressLine1,
            ShippingAddressLine2,
            ShippingAddressCity,
            ShippingAddressPhone,
            BillingAddressId,
            BillingAddressName,
            BillingAddressLine1,
            BillingAddressLine2,
            BillingAddressCity,
            BillingAddressCountry,
            BillingAddressPhone,
            {% if var('currency_conversion_flag') %}
                case when c.value is null then 1 else c.value end as exchange_currency_rate,
                case when c.from_currency_code is null then a.Currency else c.from_currency_code end as exchange_currency_code,
            {% else %}
                    cast(1 as decimal) as exchange_currency_rate,
                    a.Currency as exchange_currency_code, 
            {% endif %}
            a.{{daton_user_id()}} as _daton_user_id,
            a.{{daton_batch_runtime()}} as _daton_batch_runtime,
            a.{{daton_batch_id()}} as _daton_batch_id,
            current_timestamp() as _last_updated,
            '{{env_var("DBT_CLOUD_RUN_ID", "manual")}}' as _run_id,
            ROW_NUMBER() OVER (PARTITION BY a.OrderDateasdd_mm_yyyyhh_MM_ss order by a.{{daton_batch_runtime()}} desc) as row_num
            from {{i}} a 
                        {% if var('currency_conversion_flag') %}
                            left join {{ref('ExchangeRates')}} c on date(a.OrderDateasdd_mm_yyyyhh_MM_ss) = c.date and a.currency = c.to_currency_code   
                        {% endif %}
                        {% if is_incremental() %}
                        {# /* -- this filter will only be applied on an incremental run */ #}
                        WHERE a.{{daton_batch_runtime()}}  >= {{max_loaded}}
                    {% endif %}
                ) where row_num = 1
        {% if not loop.last %} union all {% endif %}
    {% endfor %}

