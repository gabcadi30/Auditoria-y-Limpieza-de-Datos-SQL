/*
===============================================================================
   OBJETIVOS:
   - Ingesta y almacenamiento seguro de datos en bruto (5 archivos en formato CSV).
   - Implementación de la capa 'Bronze' bajo la estructura de la arquitectura Medallion.
   - Uso del tipo de datos VARCHAR(MAX) para garantizar una carga íntegra y sin errores.

   NOTA DE INGESTA:
   -La estructura de las tablas ha sido definida mediante DDL. 
   -La ingesta de datos (bulk load) fue realizada con el asistente "Import Flat File" de SQL Server Management Studio.
===============================================================================
*/

--1.Creación de tablas bronce
USE proyectotesoreria_db;
GO

--Tabla bz_invoices
DROP TABLE IF EXISTS bz_invoices;
CREATE TABLE dbo.bz_invoices (
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

--Tabla  bz_payments
DROP TABLE IF EXISTS bz_payments;
CREATE TABLE dbo.bz_payments (
    payment_id VARCHAR(MAX),
    invoice_id VARCHAR(MAX),
    payment_date VARCHAR(MAX),
    payment_amount VARCHAR(MAX),
    method_id VARCHAR(MAX),
    processed_by VARCHAR(MAX)
);

--Tabla bz_payment_methods 
DROP TABLE IF EXISTS bz_payment_methods;
CREATE TABLE dbo.bz_payment_methods (
    method_id VARCHAR(MAX),
    method_name VARCHAR(MAX)
);

--Tabla bz_departments
DROP TABLE IF EXISTS bz_departments;
CREATE TABLE dbo.bz_departments (
    department_id VARCHAR(MAX),
    department_name VARCHAR(MAX),
    budget_owner VARCHAR(MAX)
);

--Tabla bz_suppliers
DROP TABLE IF EXISTS bz_suppliers;
CREATE TABLE dbo.bz_suppliers (
    supplier_id VARCHAR(MAX),
    supplier_name VARCHAR(MAX),
    category VARCHAR(MAX),
    country VARCHAR(MAX),
    rating VARCHAR(MAX)
);
