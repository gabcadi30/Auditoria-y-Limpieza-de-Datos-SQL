
/* =======================================================================
   OBJETIVO:
  -Ejecutar las reglas de limpieza definidas tras el EDA para transformar datos de Bronze a tablas estructuradas.
  -Aplicar desduplicación (funciones de ventana) y filtrar nulos críticos.
  -Normalizar tipos de datos (CAST) y asegurar la consistencia del esquema.
  -Mantener tablas sin PRIMARY KEY temporalmente para facilitar la auditoría de duplicados.
   ======================================================================= */

USE proyectotesoreria_db;
GO

-- 1. Definición de Estructura (Tablas Silver)
CREATE TABLE Departments (
    department_id INT,
    department_name VARCHAR(20),
    budget_owner VARCHAR(20)
);

CREATE TABLE Payment_methods (
     method_id INT,
     method_name VARCHAR(20)
);

CREATE TABLE Suppliers (
    supplier_id INT,
    supplier_name VARCHAR(20),
    category VARCHAR(20),
    country VARCHAR(20),
    rating VARCHAR(5)
);

CREATE TABLE Invoices (
    invoice_id INT,
    supplier_id INT,
    department_id INT,
    invoice_number VARCHAR(12),
    issue_date DATE,
    due_date DATE,
    invoice_amount DECIMAL(12,2),
    currency VARCHAR(3),
    [status] VARCHAR(20)
);

CREATE TABLE Payments (
    payment_id INT,
    invoice_id INT,
    payment_date DATE,
    payment_amount DECIMAL(12,2),
    method_id INT,
    processed_by VARCHAR(50)
);
GO

-- 2. Proceso de Transformación e Inserción (ETL)

-- Limpieza y carga de Invoices
WITH invoice_temporal AS (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY invoice_id ORDER BY issue_date) AS rn
    FROM stg_invoices
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
    FROM stg_payments
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