/* =======================================================================
   OBJETIVO:
   - Crear tablas de hechos/negocio para análisis en Power BI.
   - Procesar datos desde las tablas Silver mediante lógica de negocio:
     1. Pagos sin factura (Control de integridad).
     2. Gestión de tiempos de facturación (KPIs de retraso/anticipo).
     3. Detección de sobrepagos (Control financiero).
   ======================================================================= */

USE proyectotesoreria_db;
GO

-- 1. Tabla: Pagos sin factura (Control de excepciones)
IF OBJECT_ID('dbo.unassociated_payments', 'U') IS NOT NULL DROP TABLE dbo.unassociated_payments;
CREATE TABLE unassociated_payments (
    invoice_id INT,
    payment_id INT,
    payment_date DATE,
    payment_amount DECIMAL(10,2),
    method_name VARCHAR(50),
    payment_type VARCHAR(20)
);

INSERT INTO unassociated_payments
SELECT 
    i.invoice_id,
    p.payment_id,
    p.payment_date,
    p.payment_amount,
    m.method_name,
    CASE
        WHEN p.invoice_id IS NOT NULL THEN 'con factura'
        ELSE 'sin factura' 
    END AS payment_type
FROM Payments p
LEFT JOIN Invoices i ON p.invoice_id = i.invoice_id
LEFT JOIN Suppliers s ON i.supplier_id = s.supplier_id
LEFT JOIN Payment_methods m ON p.method_id = m.method_id;


-- 2. Tabla: Gestión de tiempos de facturación 
IF OBJECT_ID('dbo.invoice_time_management', 'U') IS NOT NULL DROP TABLE dbo.invoice_time_management;
CREATE TABLE invoice_time_management (
    invoice_id INT,
    status VARCHAR(15),
    supplier_name VARCHAR(20), 
    issue_date DATE,
    due_date DATE,
    payment_date DATE, 
    department_name VARCHAR(20),
    invoice_amount DECIMAL(10,2),
    plazo_pactado INT,
    final_status VARCHAR(15),
    dias_retraso INT,
    dias_anticipo INT,
    tipo_pago VARCHAR(20)
);

INSERT INTO invoice_time_management 
SELECT t.invoice_id, t.status, t.supplier_name, t.issue_date, t.due_date, t.payment_date, t.department_name, t.invoice_amount, t.plazo_pactado, t.final_status, t.dias_retraso, t.dias_anticipo,
    CASE 
        WHEN t.final_status = 'pagado' AND t.dias_anticipo IS NULL THEN 'dentro del plazo'
        WHEN t.final_status = 'pagado' AND t.dias_anticipo IS NOT NULL THEN 'antes del plazo'
        WHEN t.final_status = 'vencido' AND t.dias_anticipo IS NULL THEN 'fuera del plazo'
        WHEN t.final_status = 'pendiente' AND t.dias_anticipo IS NULL THEN 'fuera del plazo'
        ELSE 'otro' 
    END AS tipo_pago
FROM (
    SELECT i.invoice_id, i.status, s.supplier_name, i.issue_date, i.due_date, p.payment_date, d.department_name, i.invoice_amount,
           DATEDIFF(day, i.issue_date, i.due_date) AS plazo_pactado,
           CASE
               WHEN p.payment_date IS NOT NULL AND p.payment_date <= i.due_date THEN 'pagado'
               WHEN p.payment_date IS NOT NULL AND p.payment_date > i.due_date THEN 'vencido'
               WHEN p.payment_date IS NULL THEN 'pendiente'
           END AS final_status,
           CASE 
               WHEN p.payment_date IS NOT NULL AND due_date < payment_date THEN DATEDIFF(day, i.due_date, p.payment_date)
               WHEN p.payment_date IS NOT NULL AND due_date > payment_date THEN 0
               ELSE DATEDIFF(day, i.due_date, '2025-03-31')
           END AS dias_retraso,
           CASE 
               WHEN p.payment_date < i.issue_date THEN DATEDIFF(day, p.payment_date, i.issue_date)
           END AS dias_anticipo
    FROM Invoices i
    LEFT JOIN Payments p ON i.invoice_id = p.invoice_id
    LEFT JOIN Suppliers s ON i.supplier_id = s.supplier_id
    LEFT JOIN Departments d ON i.department_id = d.department_id
) t;


-- 3. Tabla: Sobrepagos (Control financiero)
IF OBJECT_ID('dbo.overpayment_invoices', 'U') IS NOT NULL DROP TABLE dbo.overpayment_invoices;
CREATE TABLE overpayment_invoices (
    invoice_id INT,
    supplier_name VARCHAR(30),
    monto_factura DECIMAL(10,2),
    monto_pagado DECIMAL(10,2),
    sobrepago_error DECIMAL(10,2),
    department_name VARCHAR(20) 
);

INSERT INTO overpayment_invoices 
SELECT i.invoice_id, s.supplier_name,
 i.invoice_amount AS monto_factura, 
 p.total_pagado AS monto_pagado, 
 (p.total_pagado - i.invoice_amount) AS sobrepago_error, 
 d.department_name
FROM Invoices i
LEFT JOIN (
    SELECT invoice_id, SUM(payment_amount) AS total_pagado 
    FROM Payments 
    GROUP BY invoice_id
) p ON i.invoice_id = p.invoice_id
LEFT JOIN Suppliers s ON i.supplier_id = s.supplier_id
LEFT JOIN Departments d ON i.department_id = d.department_id
WHERE p.total_pagado > i.invoice_amount;
GO