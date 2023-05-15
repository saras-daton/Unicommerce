# Unicommerce Data Unification

This dbt package is for the Unicommerce Ads data unification Ingested by [Daton](https://sarasanalytics.com/daton/). [Daton](https://sarasanalytics.com/daton/) is the Unified Data Platform for Global Commerce with 100+ pre-built connectors and data sets designed for accelerating the eCommerce data and analytics journey by [Saras Analytics](https://sarasanalytics.com).

### Supported Datawarehouses:
- BigQuery
- Snowflake

#### Typical challanges with raw data are:
- Array/Nested Array columns which makes queries for Data Analytics complex
- Data duplication due to look back period while fetching report data from Unicommerce
- Seperate tables at marketplaces/Store, brand, account level for same kind of report/data feeds

By doing Data Unification the above challenges can be overcomed and simplifies Data Analytics. 
As part of Data Unification, the following funtions are performed:
- Consolidation - Different marketplaces/Store/account & different brands would have similar raw Daton Ingested tables, which are consolidated into one table with column distinguishers brand & store
- Deduplication - Based on primary keys, the data is De-duplicated and the latest records are only loaded into the consolidated stage tables
- Incremental Load - Models are designed to include incremental load which when scheduled would update the tables regularly
- Standardization -
	- Currency Conversion (Optional) - Raw Tables data created at Marketplace/Store/Account level may have data in local currency of the corresponding marketplace/store/account. Values that are in local currency are standardized by converting to desired currency using Daton Exchange Rates data.
	  Prerequisite - Exchange Rates connector in Daton needs to be present - Refer [this](https://github.com/saras-daton/currency_exchange_rates)
	- Time Zone Conversion (Optional) - Raw Tables data created at Marketplace/Store/Account level may have data in local timezone of the corresponding marketplace/store/account. DateTime values that are in local timezone are standardized by converting to specified timezone using input offset hours.

#### Prerequisite 
Daton Integrations for  
- Unicommerce
- Exchange Rates(Optional, if currency conversion is not required)

# Configuration 

## Required Variables

This package assumes that you have an existing dbt project with a BigQuery/Snowflake profile connected & tested. Source data is located using the following variables which must be set in your `dbt_project.yml` file.
```yaml
vars:
    raw_database: "your_database"
    raw_schema: "your_schema"
```

## Setting Target Schema

Models will be create unified tables under the schema (<target_schema>_stg_unicommerce). In case, you would like the models to be written to the target schema or a different custom schema, please add the following in the dbt_project.yml file.

```yaml
models:
  Unicommerce:
    +schema: custom_schema_name
```

## Optional Variables

Package offers different configurations which must be set in your `dbt_project.yml` file. These variables can be marked as True/False based on your requirements. Details about the variables are given below.

### Currency Conversion 

To enable currency conversion, which produces two columns - exchange_currency_rate & exchange_currency_code, please mark the currency_conversion_flag as True. By default, it is False.
Prerequisite - Daton Exchange Rates Integration

Example:
```yaml
vars:
    currency_conversion_flag: True
```

### Timezone Conversion 

To enable timezone conversion, which converts the timezone columns from UTC timezone to local timezone, please mark the timezone_conversion_flag as True in the dbt_project.yml file, by default, it is False. Additionally, you need to provide offset hours between UTC and the timezone you want the data to convert into for each raw table for which you want timezone converison to be taken into account.

Example:
```yaml
vars:
  timezone_conversion_flag : True
  raw_table_timezone_offset_hours: {
    "edm-saras.EDM_Daton.Brand_US_Unicommerce_BQ_Invoice" : -7,
    "edm-saras.EDM_Daton.Brand_US_Unicommerce_BQ_ReturnInvoices" : -7,
    "edm-saras.EDM_Daton.Brand_US_Unicommerce_BQ_ReversePickup" : -7,
    "edm-saras.EDM_Daton.Brand_US_Unicommerce_BQ_Putaway" : -7,
    "edm-saras.EDM_Daton.Brand_US_Unicommerce_BQ_Vendors" : -7,
    "edm-saras.EDM_Daton.Brand_US_Unicommerce_BQ_VendorItemMaster" : -7,
    "edm-saras.EDM_Daton.Brand_US_Unicommerce_BQ_GRN" : -7,
    "edm-saras.EDM_Daton.Brand_US_Unicommerce_BQ_Gatepass" : -7,
    "edm-saras.EDM_Daton.Brand_US_Unicommerce_BQ_ShippingPackage" : -7,
    "edm-saras.EDM_Daton.Brand_US_Unicommerce_BQ_CourierReturnItemwise" : -7,
    "edm-saras.EDM_Daton.Brand_US_Unicommerce_BQ_ShelfwiseInventory" : -7,
    "edm-saras.EDM_Daton.Brand_US_Unicommerce_BQ_InventorySnapshot" : -7,
    "edm-saras.EDM_Daton.Brand_US_Unicommerce_BQ_ItemMaster" : -7,
    "edm-saras.EDM_Daton.Brand_US_Unicommerce_BQ_PurchaseOrders" : -7,
    "edm-saras.EDM_Daton.Brand_US_Unicommerce_BQ_SaleOrders" : -7
    }

```
Here, -7 represents the offset hours between UTC and PDT considering we are sitting in PDT timezone and want the data in this timezone


### Table Exclusions

If you need to exclude any of the models, declare the model names as variables and mark them as False. Refer the table below for model details. By default, all tables are created.

Example:
```yaml
vars:
ShoppingPerformanceView: False
```

## Models

This package contains models from the Unicommerce API which includes reports on {{sales, margin, inventory, product}}. The primary outputs of this package are described below.

| **Category**                 | **Model**  | **Description** |
| ------------------------- | ---------------| ----------------------- |
|Returns | [UnicommerceCourierReturnItemwise](models/Unicommerce/UnicommerceCourierReturnItemwise.sql)  | This table provides courier details for a reverse pick-up (CIR) for a returned order item in Uniware. |
|Outbound | [UnicommerceGatepass](models/Unicommerce/UnicommerceGatepass.sql)  | This table lists all the Gatepass details . A Gatepass is a simple document containing the detail of items while making any product movement outside the warehouse |
|Inbound | [UnicommerceGRN](models/Unicommerce/UnicommerceGRN.sql)  | This table lists all the issued GRN with item details for a vendor compared to Purchase Order.A GRN (Goods Received Note) is a record used to confirm all goods have been received|
|Inventory | [UnicommerceInventory](models/Unicommerce/UnicommerceInventory.sql)  | This table provides complete overview of inventory distribution of a SKU in a facility and inventory overview of SKU(s) based on time since last inventory update |
|Fulfillment | [UnicommerceInvoice](models/Unicommerce/UnicommerceInvoice.sql)  | This table contains a list of invoices generated with detailed invoice sections and shipping code based on order number|
|Inventory | [UnicommerceItemMaster](models/Unicommerce/UnicommerceItemMaster.sql)  | The list of products or items existing within Uniware. It defines the product SKU code (which is unique for each item), its name, the product category it belongs to and the tax associated if any |
|Product | [UnicommercePurchaseOrders](models/Unicommerce/UnicommercePurchaseOrders.sql)  | A list purchase orders for products in inventory along with its status [Purchase Order is a document shared with the vendor indicating the product (SKUs), their respective quantities and the agreed price] |
|Inbound | [UnicommercePutaway](models/Unicommerce/UnicommercePutaway.sql)  | This table provides putaway item details based on Inventory Shelf code |
|Inventory | [UnicommerceReturnInvoice](models/Unicommerce/UnicommerceReturnInvoice.sql)  | This table lists all the return invioces genrated with the shipping details based on item sku code  |
|Inventory | [UnicommerceReversePickup](models/Unicommerce/UnicommerceReversePickup.sql)  | This table provides reverse pickup details with sale order item code and putaway details if applicable |
|SaleOrder | [UnicommerceSaleOrders](models/Unicommerce/UnicommerceSaleOrders.sql)| A list of sale orders issued to customers. It confirms the sale of goods or services and details the sale’s specifics, including the quantity, pricing, and quality of goods or services provided |
|Inventory | [UnicommerceShelfwiseInventory](models/Unicommerce/UnicommerceShelfwiseInventory.sql)  | This table provides complete overview of inventory distribution of a SKU in a facility and inventory overview of SKU(s) based on shelf |
|Fulfillment | [UnicommerceShippingPackage](models/Unicommerce/UnicommerceShippingPackage.sql)  | This table provides all the shipping details with tracker and provider|
|Inbound | [UnicommerceVendorItemMaster](models/Unicommerce/UnicommerceVendorItemMaster.sql)  | This table provides list of products or items existing within Uniware based on the vendor Sku code |
|Inbound | [UnicommerceVendors](models/Unicommerce/UnicommerceVendors.sql)  | This table provides list of all associated vendors and details about their accounts like gst number and contact details |


### For details about default configurations for Table Primary Key columns, Partition columns, Clustering columns, please refer the properties.yaml used for this package as below. 
	You can overwrite these default configurations by using your project specific properties yaml.
```yaml
version: 2
models:
  - name: UnicommerceCourierReturnItemwise
    description: This table provides courier details for a reverse pick-up (CIR) for a returned order item in Uniware.
    config: 
        materialized : incremental  
        incremental_strategy : merge 
        unique_key : ['SaleOrderNo','SaleOrderItem']
        partition_by : { 'field': 'ReturnDate', 'data_type': dbt.type_timestamp() }
        cluster_by : ['SaleOrderNo']

  - name: UnicommerceGatepass
    description: This table lists all the Gatepass details . A Gatepass is a simple document containing the detail of items while making any product movement outside the warehouse.
    config: 
        materialized : incremental  
        incremental_strategy : merge 
        unique_key : ['GatepassCode','ItemSkuCode']   
        partition_by : { 'field': 'GatepassCreatedAt', 'data_type': dbt.type_timestamp() }
        cluster_by : ['GatepassCode']

  - name: UnicommerceGRN
    description: This table lists all the issued GRN with item details for a vendor compared to Purchase Order.A GRN (Goods Received Note) is a record used to confirm all goods have been received.
    config: 
        materialized : incremental  
        incremental_strategy : merge 
        unique_key : ['GRNCode','ItemSkuCode']
        partition_by : { 'field': 'GRNDate', 'data_type': dbt.type_timestamp() }
        cluster_by : ['GRNCode']

  - name: UnicommerceInventory
    description: This table provides overview of inventory distribution of SKU(s) in the warehouse.
    config: 
        materialized : incremental 
        incremental_strategy : merge 
        unique_key : ['Facility','ItemSkuCode']
        partition_by : { 'field': 'updated', 'data_type': dbt.type_timestamp(), 'granularity' : day }
        cluster_by : ['ItemSkuCode']

  - name: UnicommerceInvoice
    description: This table contains a list of invoices generated with detailed invoice sections and shipping code based on order number.
    config: 
        materialized : incremental 
        incremental_strategy : merge 
        unique_key : ['OrderNo','SKUCode','_seq_id']
        partition_by : { 'field': 'InvoiceCreatedDate', 'data_type': dbt.type_timestamp(), 'granularity' : day }
        cluster_by : ['OrderNo']

  - name: UnicommerceItemMaster
    description: The list of products or items existing within Uniware. It defines the product SKU code (which is unique for each item), its name, the product category it belongs to and the tax associated  
    config : 
        materialized : incremental
        incremental_strategy : merge 
        unique_key : ['ProductCode','ComponentProductCode']
        partition_by : { 'field': 'updated', 'data_type': dbt.type_timestamp(), 'granularity' : day }
        cluster_by : ['ProductCode']


  - name: UnicommercePurchaseOrders
    description: This Table provides information about Purchase orders with prices and order status
    config :
        materialized : incremental
        incremental_strategy : merge
        unique_key : ['ItemSkuCode']
        partition_by : { 'field': 'Updated', 'data_type': dbt.type_timestamp(), 'granularity' : day }
        cluster_by : ['ItemSkuCode']

  - name: UnicommercePutaway
    description:  This table provides putaway item details based on Inventory Shelf code.
    config: 
        materialized : incremental  
        incremental_strategy : merge
        unique_key : ['PutawayItemId','ItemTypeskuCode'] 
        partition_by : { 'field': 'created', 'data_type': dbt.type_timestamp() }
        cluster_by : ['PutawayItemId']

  - name: UnicommerceReturnInvoice
    description: This table lists all the return invioces genrated with the shipping details based on item sku code.
    config: 
        materialized : incremental  
        incremental_strategy : merge 
        unique_key : ['InvoiceCode','ItemSKUCode']
        partition_by : { 'field': 'ReturnDate', 'data_type': dbt.type_timestamp() }
        cluster_by : ['InvoiceCode']


  - name: UnicommerceReversePickup
    description: This table provides reverse pickup details with sale order item code and putaway details if applicable.
    config: 
        materialized : incremental  
        incremental_strategy : merge 
        unique_key : ['ItemSKUCode','ReversePickupNo']
        partition_by : { 'field': 'ReversePickupCreated', 'data_type': dbt.type_timestamp() }
        cluster_by : ['ItemSKUCode']

  - name: UnicommerceSaleOrders
    description: A list of sale orders issued to customers. It confirms the sale of goods or services and details the sale’s specifics, including the quantity, pricing, and quality of goods or services provided
    config :
        materialized : incremental
        incremental_strategy : merge
        unique_key : ['SaleOrderItemCode','DisplayOrderCode']
        partition_by : { 'field': 'order_date', 'data_type': dbt.type_timestamp(), 'granularity' : day }
        cluster_by : ['ItemSKUCode']

  - name: UnicommerceShelfwiseInventory
    description: This table provides complete overview of inventory distribution of a SKU in a facility and inventory overview of SKU(s)) based on shelf.
    config: 
        materialized : incremental  
        incremental_strategy : merge 
        unique_key : ['ItemTypeSKUCode','Shelf']
        cluster_by : ['Shelf']


  - name: UnicommerceShippingPackage
    description: This table provides all the shipping details with tracker and provider.
    config: 
        materialized : incremental  
        incremental_strategy : merge 
        unique_key : ['ShippingPackageNo']
        partition_by : { 'field': 'Created', 'data_type': dbt.type_timestamp() }
        cluster_by : ['ShippingPackageNo']

  - name: UnicommerceVendorItemMaster
    description: This table provides list of products or items existing within Uniware based on the vendor Sku code
    config: 
        materialized : incremental  
        incremental_strategy : merge 
        unique_key : ['VendorSkuCode','VendorCode','ProductCode']
        partition_by : { 'field': 'Updated', 'data_type': dbt.type_timestamp() }
        cluster_by : ['VendorCode']

  - name: UnicommerceVendors
    description: This table provides list of all associated vendors and details about their accounts like gst number and contact details
    config: 
        materialized : incremental  
        incremental_strategy : merge 
        unique_key : ['VendorCode']
        partition_by : { 'field': 'Updated', 'data_type': dbt.type_timestamp() }
        cluster_by : ['VendorCode']


```
## Resources:
- Have questions, feedback, or need [help]? Schedule a call with our data experts or email us at info@sarasanalytics.com.
- Learn more about Daton [here](https://sarasanalytics.com/daton/).
- Refer [this](https://youtu.be/6zDTbM6OUcs) to know more about how to create a dbt account & connect to {{Bigquery/Snowflake}}
