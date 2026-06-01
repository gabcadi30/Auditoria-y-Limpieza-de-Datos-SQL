/*
===============================================================================
   ARQUITECTURA:
   - Implementación de capa de Staging (prefijo 'stg_') para un modelo Star Schema.
   - Uso del tipo de datos VARCHAR(MAX) para garantizar una carga íntegra y sin errores.

   NOTA DE INGESTA:
   -La estructura de las tablas ha sido definida mediante DDL. 
   -La ingesta de datos (bulk load) fue realizada con el asistente "Import Flat File" de SQL Server Management Studio.
===============================================================================
*/

--1.Creación de tablas staging
USE proyectotesoreria_db;
GO

--Tabla de Invoices
DROP TABLE IF EXISTS stg_invoices;
CREATE TABLE dbo.stg_invoices (
    invoice_id VARCHAR(MAX),
    supplier_id VARCHAR(MAX),
    department_id VARCHAR(MAX),
    invoice_number VARCHAR(MAX),
    issue_date VARCHAR(MAX),
    due_date VARCHAR(MAX),
    invoice_amount VARCHAR(MAX),
    currency VARCHAR(MAX),
    [status] VARCHAR(MAX) 
);

--Tabla de Payments
DROP TABLE IF EXISTS stg_payments;
CREATE TABLE dbo.stg_payments (
    payment_id VARCHAR(MAX),
    invoice_id VARCHAR(MAX),
    payment_date VARCHAR(MAX),
    payment_amount VARCHAR(MAX),
    method_id VARCHAR(MAX),
    processed_by VARCHAR(MAX)
);

--Tabla de Métodos de Pago
DROP TABLE IF EXISTS stg_payment_methods;
CREATE TABLE dbo.stg_payment_methods (
    method_id VARCHAR(MAX),
    method_name VARCHAR(MAX)
);

--Tabla de Departamentos
DROP TABLE IF EXISTS stg_departments;
CREATE TABLE dbo.stg_departments (
    department_id VARCHAR(MAX),
    department_name VARCHAR(MAX),
    budget_owner VARCHAR(MAX)
);

--Tabla de Proveedores
DROP TABLE IF EXISTS stg_suppliers;
CREATE TABLE dbo.stg_suppliers (
    supplier_id VARCHAR(MAX),
    supplier_name VARCHAR(MAX),
    category VARCHAR(MAX),
    country VARCHAR(MAX),
    rating VARCHAR(MAX)
);
