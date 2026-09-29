
/* =======================================================================
   OBJETIVO:
  -Ejecutar las reglas de limpieza definidas tras el EDA para transformar datos de Bronze a tablas estructuradas.
  -Aplicar desduplicación (funciones de ventana) y filtrar nulos críticos.
  -Normalizar tipos de datos (CAST) y asegurar la consistencia del esquema.
  -Mantener tablas sin PRIMARY KEY temporalmente para facilitar la auditoría de duplicados.
   ======================================================================= */

USE proyectotesoreria_db;
GO

--1. Creación de Tablas Silver
   
DROP TABLE IF EXISTS sil_departments
CREATE TABLE sil_departments (
    department_id int,
    department_name varchar(20),
    budget_owner varchar(20) )

DROP TABLE IF EXISTS sil_payment_methods
CREATE TABLE sil_payment_methods (
     method_id int,
     method_name varchar(20) )

DROP TABLE IF EXISTS sil_suppliers
CREATE TABLE sil_suppliers (
    supplier_id int,
    supplier_name varchar(20),
    category varchar(20),
    country varchar(20),
    rating varchar(5) )

DROP TABLE IF EXISTS sil_invoices;
CREATE TABLE sil_invoices (
invoice_id int,
supplier_id int,
department_id int,
invoice_number varchar(12),
issue_date date,
due_date date,
invoice_amount decimal(10,2),
invoice_amount_status varchar (20),
invoice_number_status varchar(20),
currency varchar(3),
status varchar(12) )

DROP TABLE IF EXISTS sil_payments;
CREATE TABLE sil_payments (
  payment_id INT,
  invoice_id INT ,
  payment_date DATE,
  payment_amount NUMERIC(10,2),
  payment_amount_status VARCHAR(20),
  method_id INT,
  processed_by VARCHAR(20) )

-- 2. Transformación y Carga de Datos:
   
INSERT INTO sil_departments (
department_id,
department_name,
budget_owner )
   
SELECT 
 cast(department_id as int),
 department_name,
 budget_owner
FROM bz_departments




   

-- Limpieza y carga de Invoices
WITH invoice_temporal AS (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY invoice_id ORDER BY issue_date) AS rn
    FROM bz_invoices
    WHERE invoice_amount IS NOT NULL
)
INSERT INTO Invoices
SELECT 
    CAST(invoice_id AS INT),
    CAST(supplier_id AS INT),
    CAST(department_id AS INT),
    invoice_number,
    CAST(issue_date AS DATE),
    CAST(due_date AS DATE),
    CAST(invoice_amount AS DECIMAL(12,2)),
    currency,
    [status]
FROM invoice_temporal
WHERE rn = 1;

-- Limpieza y carga de Payments
WITH payment_temporal AS (
    SELECT *, 
           ROW_NUMBER() OVER(PARTITION BY payment_id ORDER BY payment_date) AS rn
    FROM bz_payments
    WHERE payment_amount IS NOT NULL
)
INSERT INTO Payments
SELECT 
    CAST(payment_id AS INT),
    CAST(invoice_id AS INT),
    CAST(payment_date AS DATE),
    CAST(payment_amount AS DECIMAL(12,2)),
    CAST(method_id AS INT),
    processed_by
FROM payment_temporal
WHERE rn = 1;
GO
