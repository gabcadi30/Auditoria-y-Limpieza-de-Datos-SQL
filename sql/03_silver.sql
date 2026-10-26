
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
    status_original VARCHAR(12),      -- en desuso, se conserva por trazabilidad
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
-- Las 3 tablas dimensionales (sil_departments, sil_payment_methods, sil_suppliers):

INSERT INTO dbo.sil_departments ( department_id, department_name, budget_owner )
SELECT 
   CAST(department_id AS INT), 
   department_name, 
   budget_owner
FROM dbo.bz_departments;


INSERT INTO dbo.sil_payment_methods ( method_id, method_name )
SELECT 
   CAST(method_id AS INT), 
   method_name
FROM dbo.bz_payment_methods;   


INSERT INTO dbo.sil_suppliers ( supplier_id, supplier_name, category, country, rating )
SELECT
    CAST(supplier_id AS INT),
    supplier_name,
    category,
    country,
    rating
FROM dbo.bz_suppliers;
GO
   

-- Las 2 tablas de hechos (sil_invoices, sil payments):
--Carga de sil_invoices:
WITH 
ranked AS (
   SELECT *, ROW_NUMBER() 
          OVER ( PARTITION BY invoice_id, supplier_id, department_id, invoice_number,
                            issue_date, due_date, invoice_amount, currency, [status]
                  ORDER BY issue_date) AS rn
   FROM dbo.bz_invoices ) 
, 
duplicados_parciales AS (
    SELECT invoice_number
    FROM dbo.bz_invoices
    GROUP BY invoice_number
    HAVING COUNT(DISTINCT invoice_id) > 1
)
INSERT INTO dbo.sil_invoices
SELECT
    CAST(invoice_id AS INT),
    CAST(supplier_id AS INT),
    CAST(department_id AS INT),
    invoice_number,
    CAST(issue_date AS DATE),
    CAST(due_date AS DATE),
    CAST(invoice_amount AS DECIMAL(10,2)),
    UPPER(currency),
    [status],
    CASE WHEN invoice_amount IS NULL THEN 'faltante' ELSE 'ok' END,
    CASE WHEN invoice_number IN (SELECT invoice_number FROM duplicados_parciales)
         THEN 'duplicado' ELSE 'ok' END
FROM ranked
WHERE rn = 1;
GO

   
--Carga en sil_payments:
WITH 
ranked AS (
   SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY payment_id, invoice_id, payment_date, payment_amount,
                            method_id, processed_by
               ORDER BY payment_date) AS rn
    FROM dbo.bz_payments
),
ultimo_pago AS (
    SELECT r.*,
           ROW_NUMBER() OVER (PARTITION BY r.invoice_id
                              ORDER BY r.payment_date DESC, r.payment_id DESC) AS rn_final
    FROM ranked r
    WHERE r.rn = 1
)
INSERT INTO dbo.sil_payments
SELECT
    CAST(e.payment_id AS INT),
    CAST(e.invoice_id AS INT),
    CAST(e.payment_date AS DATE),
    CAST(e.payment_amount AS DECIMAL(10,2)),
    CAST(e.method_id AS INT),
    e.processed_by,
    CASE WHEN e.payment_amount IS NULL THEN 'faltante' ELSE 'ok' END,
    CASE WHEN i.issue_date IS NOT NULL AND e.payment_date < i.issue_date
         THEN 'si' ELSE 'no' END,
    CASE WHEN e.rn_final = 1 THEN 'si' ELSE 'no' END
FROM ultimo_pago e
LEFT JOIN dbo.sil_invoices i ON e.invoice_id = i.invoice_id;
GO

--3. Validación de la carga:
SELECT 'sil_invoices' AS tabla, COUNT(*) AS filas FROM dbo.sil_invoices                                                   --6000
UNION ALL SELECT 'sil_payments', COUNT(*) FROM dbo.sil_payments                                                           --4500  
UNION ALL SELECT 'invoices con monto faltante', COUNT(*) FROM dbo.sil_invoices WHERE invoice_amount_status='faltante'     --288 nulos 
UNION ALL SELECT 'invoices con folio duplicado', COUNT(*) FROM dbo.sil_invoices WHERE invoice_number_status='duplicado'   --24 duplicados/ 12 folios
UNION ALL SELECT 'pagos anticipados', COUNT(*) FROM dbo.sil_payments WHERE es_anticipo='si'                               --2245 anticipos
UNION ALL SELECT 'pagos marcados como final', COUNT(*) FROM dbo.sil_payments WHERE es_pago_final='si'                     --3137 ultimos pagos


