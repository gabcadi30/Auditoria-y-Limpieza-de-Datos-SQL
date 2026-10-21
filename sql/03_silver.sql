
/* =======================================================================
   OBJETIVO:
  -Ejecutar las reglas de limpieza definidas tras el EDA.
  -Aplicar funciones de ventana y filtrar nulos críticos.
  -Normalizar tipos de datos (CAST) y asegurar la consistencia del esquema.
   ======================================================================= */

USE proyectotesoreria_db;
GO

--1. Creación de tablas silver: 3 dimensiones + 2 hechos
   
DROP TABLE IF EXISTS sil_departments
CREATE TABLE dbo.sil_departments (
    department_id INT NOT NULL,
    department_name NVARCHAR(50),
    budget_owner NVARCHAR(50)
);

DROP TABLE IF EXISTS sil_payment_methods
CREATE TABLE dbo.sil_payment_methods (
    method_id INT NOT NULL,
    method_name NVARCHAR(50)
);

DROP TABLE IF EXISTS sil_suppliers
CREATE TABLE dbo.sil_suppliers (
    supplier_id INT NOT NULL,
    supplier_name NVARCHAR(50),
    category NVARCHAR(50),
    country NVARCHAR(50),
    rating VARCHAR(5)
);
DROP TABLE IF EXISTS sil_invoices;
CREATE TABLE dbo.sil_invoices (
    invoice_id INT NOT NULL,
    supplier_id INT,
    department_id INT,
    invoice_number VARCHAR(20),
    issue_date DATE,
    due_date DATE,
    invoice_amount DECIMAL(10,2),
    currency CHAR(3),
    status_original VARCHAR(12),      -- deprecada, se conserva por trazabilidad
    invoice_amount_status VARCHAR(10),  -- ok | faltante
    invoice_number_status VARCHAR(10)   -- ok | duplicado
);

DROP TABLE IF EXISTS sil_payments;
CREATE TABLE dbo.sil_payments (
    payment_id INT NOT NULL,
    invoice_id INT,
    payment_date DATE,
    payment_amount DECIMAL(10,2),
    method_id INT,
    processed_by NVARCHAR(50),
    payment_amount_status VARCHAR(10),  -- ok | faltante
    es_anticipo CHAR(2),                 -- si | no
    es_pago_final CHAR(2)                -- si | no
);


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
