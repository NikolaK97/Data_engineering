
--L1 contracts_crm
--byl implementován test na unikátnost ID a nulových hodnot
CREATE OR REPLACE VIEW `psychic-heading-455311-r2.L1.L1_contracts_crm` AS SELECT  
id_contract AS contract_id --PK
, id_branch AS branch_id --FK
, DATE(TIMESTAMP(date_contract_valid_from), "Europe/Prague") AS contract_valid_from
, DATE(TIMESTAMP(date_contract_valid_to), "Europe/Prague") AS contract_valid_to
, DATE(TIMESTAMP(date_registered), "Europe/Prague") AS registred_date
, DATE(TIMESTAMP(date_signed), "Europe/Prague") AS signed_date
, DATE(TIMESTAMP(activation_process_date), "Europe/Prague") AS activation_process_date
, DATE(TIMESTAMP(prolongation_date), "Europe/Prague") AS prolongation_date
, LOWER(registration_end_reason) AS registration_end_reason
, flag_prolongation
--If the invoice is sent as email. True - yes, False - other methods
, CAST(flag_send_inv_email AS BOOL) AS flag_send_email
, LOWER(contract_status) AS contract_status
, load_date
FROM `psychic-heading-455311-r2.L0_crm.contracts_crm` 
;

--L1 branch
--byl implementován test na unikátnost ID a nulových hodnot
CREATE OR REPLACE VIEW `psychic-heading-455311-r2.L1.L1_branch` AS SELECT
CAST(id_branch AS INT) AS branch_id --PK
, LOWER(branch_name) AS branch_name
--, DATE(TIMESTAMP(date_update), "Europe/Prague") AS branch_date_update_date --smazat, zbytečné
FROM `psychic-heading-455311-r2.L0_google_sheets.branch` 
WHERE id_branch != "NULL";

--L1 invoice
--byl implementován test na unikátnost ID a nulových hodnot
CREATE OR REPLACE VIEW `psychic-heading-455311-r2.L1.L1_invoice` AS SELECT
id_invoice AS invoice_id --PK
, id_invoice_old AS invoice_previous_id
, invoice_id_contract AS contract_id --FK
, status AS invoice_status_id
--, id_branch AS branch_id --FK
--Invoice status. Invoice status < 100 have been issued. Invoice status >= 100 not issued
--, IF(status < 100, TRUE, FALSE) AS flag_invoice_issued --proč tady????
, DATE(date, "Europe/Prague") AS issue_date
, DATE(scadent,"Europe/Prague" ) AS due_date
, DATE(date_paid, "Europe/Prague") AS paid_date
, DATE(start_date, "Europe/Prague") AS start_date
, DATE(end_date, "Europe/Prague") AS end_date
--, DATE(date_insert, "Europe/Prague") AS insert_date
--, DATE(date_update, "Europe/Prague") AS update_date
, value AS amount_w_vat
--, payed AS amount_payed
--, flag_paid_currier
, invoice_type AS invoice_type_id -- invoice_type: 1 - invoice, 3 - credit_note, 2 - return, 4 - other
, CASE
    WHEN invoice_type = 1 THEN "invoice"
    WHEN invoice_type = 3 THEN "credit_note"
    WHEN invoice_type = 2 THEN "return"
    WHEN invoice_type = 4 THEN "other"
END AS invoice_type
--, number AS invoice_number
, value_storno AS return_w_vat, 
DATE(date_insert, "Europe/Prague") AS date_insert,
status AS invoice_status_id,
IF(status < 100, TRUE, FALSE) AS flag_invoice_issued,
 DATE(date_update, "Europe/Prague") AS update_date,
 id_branch AS branch_id,
FROM `psychic-heading-455311-r2.L0_accounting_system.invoice`
;

--L1 invoice_load
--byl implementován test na unikátnost ID a nulových hodnot
CREATE OR REPLACE VIEW `psychic-heading-455311-r2.L1.L1_invoice_load` AS SELECT
id_load AS invoice_load_id --PK
, id_contract AS contract_id --FK
, id_package  AS package_id --FK
, id_package_template AS product_id --FK
, id_invoice as invoice_id
, notlei AS price_wo_VAT_usd
, LOWER(currency) AS currency_usd
, tva AS vat_rate
, value AS price_w_vat_usd
, payed AS paid_w_vat_usd
, LOWER(um) AS um --převedení hodnot ve sloupci um na eng názvy
, CASE 
    WHEN um IN ('mesia','m?síce','m?si?1ce','měsice','mesiace','měsíce','mesice') then  'month'
    WHEN um = "kus" THEN "item"
    WHEN um = "min" THEN "minute"
    WHEN um = "den" THEN 'day'
    WHEN um = '0' THEN null 
    ELSE um END AS unit
, quantity 
, DATE(TIMESTAMP(start_date), "Europe/Prague") AS start_date
, DATE(TIMESTAMP(end_date), "Europe/Prague") AS end_date
, DATE(TIMESTAMP(date_insert), "Europe/Prague") AS insert_date
, DATE(TIMESTAMP(date_update), "Europe/Prague") AS update_date
--, id_invoice AS invoice_id --FK
FROM `psychic-heading-455311-r2.L0_accounting_system.invoices_load` 
;

--L1 product
--byl implementován test na unikátnost ID a nulových hodnot
CREATE OR REPLACE VIEW `psychic-heading-455311-r2.L1.L1_product` AS SELECT
CAST(id_product AS INT) AS product_id --PK
, LOWER(name) AS product_name
, LOWER(type) AS product_type
, LOWER(category) AS product_category
--, is_vat_applicable AS is_vat_applicable
--, DATE(TIMESTAMP(date_update), "Europe/Prague") AS product_date_update_date
FROM `psychic-heading-455311-r2.L0_google_sheets.all_products` 
    WHERE id_product IS NOT NULL --Tady je nutná podmínka
    AND name IS NOT NULL
QUALIFY ROW_NUMBER() OVER(PARTITION BY product_id) = 1 --odstranění duplicit
;

--L1 product purchases
--byl implementován test na unikátnost ID a nulových hodnot
CREATE OR REPLACE VIEW `psychic-heading-455311-r2.L1.L1_product_purchases` AS SELECT
pp.id_package AS product_purchase_id --PK
, pp.id_contract AS contract_id --FK
, pp.id_package_template AS product_id --FK
, DATE(TIMESTAMP(pp.date_insert), "Europe/Prague") AS create_date
, DATE(TIMESTAMP(pp.start_date), "Europe/Prague") AS product_valid_from
, DATE(TIMESTAMP(pp.end_date), "Europe/Prague") AS product_valid_to
, pp.fee AS price_wo_vat
, DATE(TIMESTAMP(pp.date_update), "Europe/Prague") AS update_date
, pp.package_status AS product_status_id --FK
 --převedení hodnot ve sloupci na eng názvy
/*, CASE 
    WHEN LOWER(pp.measure_unit) IN ('mesia','m?síce','m?si?1ce','měsice','mesiace','měsíce','mesice') THEN "month" 
    WHEN LOWER(pp.measure_unit) = "kus" THEN "item"
    WHEN LOWER(pp.measure_unit) = "min" THEN "minutes"
    WHEN LOWER(pp.measure_unit) = "den" THEN "day"
    WHEN LOWER(pp.measure_unit) = '0' THEN null
  END AS unit*/
, pp.id_branch AS branch_id --FK
, pp.load_date 
, s.product_status_name AS product_status
, p.product_name
, p.product_type
, p.product_category
FROM `psychic-heading-455311-r2.L0_crm.product_purchases` pp
LEFT JOIN `psychic-heading-455311-r2.L1.L1_product` p
ON pp.id_package_template = p.product_id
LEFT JOIN `psychic-heading-455311-r2.L1.L1_status` s
ON pp.package_status = s.product_status_id
;

--L1 status
--byl implementován test na unikátnost ID a nulových hodnot
CREATE OR REPLACE VIEW `psychic-heading-455311-r2.L1.L1_status` AS SELECT
CAST(id_status AS INT)AS product_status_id --PK
, LOWER(status_name) AS product_status_name
--, DATE(TIMESTAMP(date_update), "Europe/Prague") AS product_status_update_date
FROM `psychic-heading-455311-r2.L0_google_sheets.status`
WHERE id_status IS NOT NULL --odstranění nulových hodnot
AND status_name IS NOT NULL
QUALIFY ROW_NUMBER() OVER(PARTITION BY product_status_id) = 1 --odstranění duplicit
;


