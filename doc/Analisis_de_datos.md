# Pipeline y análisis de datos 

Este El presente documento mostrará el paso a paso del flujo de datos, el proceso de limpieza y calidad, los hallazgos encontrados y la lógica de negocio aplicado en la resolución del repositorio.documento registra paso a paso el flujo de trabajo técnico, las decisiones de arquitectura, los hallazgos de calidad de datos y la lógica de negocio aplicada durante la resolución del desafío.


## Fase Bronce: Ingesta y almacenamiento 

### 1.1. Preparación de la Base de Datos
   La conexión a SQL Server fue mediante un servidor local, usando la autentificación personal de Windows.

**Creación de la base de datos:**

```sql
CREATE DATABASE proyectotesoreria_db
GO;
```

**Creación de tablas:**

Se crea las 5 tablas mediante el comando **DDL**, además, usamos el formato _VARCHAR(MAX)_ para los datos y así  asegurar una ingesta íntegra y sin errores de carga.

```sql
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
    [status] VARCHAR(MAX)  );
```

```sql
DROP TABLE IF EXISTS bz_payments;
CREATE TABLE dbo.bz_payments (
    payment_id VARCHAR(MAX),
    invoice_id VARCHAR(MAX),
    payment_date VARCHAR(MAX),
    payment_amount VARCHAR(MAX),
    method_id VARCHAR(MAX),
    processed_by VARCHAR(MAX) );
```

```sql
DROP TABLE IF EXISTS bz_payment_methods;
CREATE TABLE dbo.bz_payment_methods (
    method_id VARCHAR(MAX),
    method_name VARCHAR(MAX) );
```

```sql
DROP TABLE IF EXISTS bz_departments;
CREATE TABLE dbo.bz_departments (
    department_id VARCHAR(MAX),
    department_name VARCHAR(MAX),
    budget_owner VARCHAR(MAX) );
```

```sql
DROP TABLE IF EXISTS bz_suppliers;
CREATE TABLE dbo.bz_suppliers (
    supplier_id VARCHAR(MAX),
    supplier_name VARCHAR(MAX),
    category VARCHAR(MAX),
    country VARCHAR(MAX),
    rating VARCHAR(MAX) );
```

**Carga de datos:**

La ingesta de datos crudos (archivos CSV) se realizó mediante el asistente de SQL Server "Importa Flat File" a las tablas.


## Fase EDA: Análisis Exploratorio de Datos
Se utiliza esta fase para conocer la data. Encontrar patrones, datos nulos, duplicados y detectar errores si los hubiera.

### 2.1. Determinar el volumen y unicidad de las tablas

```sql
select count(*) as 'total_filas',
      count(distinct invoice_id)as 'facturas_unicas',

from bz_invoices
```

| total_filas  | facturas_unicas|
|--------------|--------------- |
| 6120         |           60000|

Se detecta 120 valores con registros dobles en la tabla bz_invoices.

```sql
select count(*) as 'total_filas',
      count(distinct payment_id)as 'pagos_unicos'
from bz_payments
```
| total_filas  | pagos_unicos |
|--------------|--------------|
| 4580        |           4500|

Se detecta 80 valores con registros dobles en la tabla bz_payments.


### 2.2.Búsqueda de valores nulos

```sql
select top 5 * from bz_invoices
where invoice_amount is null
```
| invoice_id | supplier_id | department_id | invoice_number | issue_date | due_date | invoice_amount | currency | status |
|------------:|-------------:|---------------:|----------------|-------------|-----------|----------------|----------|---------|
| 5   | 111 | 3  | F111-6442 | 2025-03-30 | 2025-04-29 | NULL | USD | Vencido |
| 57  | 77  | 1  | F77-4750  | 2024-03-18 | 2024-05-02 | NULL | PEN | Vencido |
| 90  | 39  | 7  | F39-9071  | 2023-04-30 | 2023-05-30 | NULL | PEN | Pendiente |
| 146 | 66  | 10 | F66-6780  | 2023-09-05 | 2023-10-05 | NULL | PEN | Vencido |
| 172 | 80  | 10 | F80-1744  | 2023-12-12 | 2023-12-27 | NULL | USD | Vencido |

Para determinar la cantidad exacta de valores nulos:

```sql
select count(*) as 'total_nulos'
from bz_invoices
where invoice_amount is null
```
| total_nulos  | 
|--------------|
| 300      |



```sql
select top 5 * from bz_payments
where payment_amount is null
```

 | payment_id | invoice_id | payment_date | payment_amount | method_id | processed_by |
|-------------|------------:|---------------|----------------|-----------:|---------------|
| 163 | 1892 | 2024-08-05 | NULL | 3 | María |
| 168 | 4590 | 2024-09-17 | NULL | 2 | Ana |
| 187 | 2338 | 2023-05-19 | NULL | 3 | Luis |
| 190 | 4881 | 2024-03-31 | NULL | 1 | José |
| 206 | 2782 | 2024-04-27 | NULL | 1 | Ana |


Para determinar la cantidad exacta de valores nulos:

```sql
select count(*) as 'total_nulos'
from bz_payments
where payment_amount is null
```
| total_nulos  | 
|--------------|
| 131          |

------

### 2.3. Búsqueda de duplicados
```sql
select invoice_id, count( invoice_id) as 'facturas'
from bz_invoices
group by invoice_id
having count(invoice_id)>1
```
| invoice_id | facturas |
|------------:|----------:|
| 10   | 2 |
| 1030 | 2 |
| 1062 | 2 |
| 1162 | 2 |
| 117  | 2 |
| 1179 | 2 |
| 1213 | 2 |
| 1218 | 2 |
| 1315 | 2 |
| 1525 | 2 |
| 1556 | 2 |
| 1601 | 2 |
| 1611 | 2 |
| ... | ...

Se hallaron 120 facturas duplicadas, cada una con doble registro asociado.

```sql
select payment_id, count( payment_id) as 'pagos'
from bz_payments
group by payment_id
having count(payment_id)>1
```
| payment_id | pagos |
|------------:|----------:|
| 1020   | 2 |
| 1064 | 2 |
| 1130 | 2 |
| 1185 | 2 |
| 1198 | 2 |
| 1267 | 2 |
| 1483 | 2 |
| 1489 | 2 |
| 1685 | 2 |
| 1711 | 2 |
| 1761 | 2 |
| 1768 | 2 |
| 1847 | 2 |
| ... | ...

Se hallaron 80 pagos duplicados, cada una con doble registro asociados.

### 2.4 Búsqueda de valores anómalos


---
```sql
select invoice_number, count(*) as 'veces_repetido'
from bz_invoices
group by invoice_number
having count(*) > 1
```
| invoice_number | veces_repetido |
|---------------|---------------:|
| F100-7417 | 2 |
| F102-7978 | 2 |
| F103-2902 | 2 |
| F105-2856 | 2 |
| F10-6453  | 2 |
| F107-5225 | 2 |
| F107-6590 | 2 |
| F108-9922 | 2 |
| F109-3534 | 2 |
| F110-6071 | 2 |
| F110-6973 | 2 |
| F113-5937 | 2 |
| ... | ... |

-Se detectaron 132 invoice_number con doble registro, descartando a invoice_number como una 'primary key' de valor único. 

-Ya se encontraba mapeado 120 duplicados exactos en bz_invoices, quedando estos 12 valores con invoice_number duplicado pendiente de revisión.

```sql
SELECT *
FROM bz_invoices
WHERE invoice_number IN (
    SELECT invoice_number
    FROM bz_invoices
    GROUP BY invoice_number
    HAVING COUNT(DISTINCT invoice_id) > 1 )
ORDER BY invoice_number desc
```
| invoice_id | supplier_id | department_id | invoice_number | issue_date | due_date | invoice_amount | currency | status |
|------------:|-------------:|--------------:|----------------|-------------|-----------|---------------:|----------|----------|
| 367  | 8  | 3 | F8-9871  | 2025-02-09 | 2025-02-24 | 1805.58  | USD | Vencido |
| 2657 | 8  | 9 | F8-9871  | 2023-12-08 | 2024-01-22 | 14731.29 | PEN | Pagado |
| 586  | 84 | 1 | F84-6901 | 2023-03-10 | 2023-05-09 | 13241.42 | PEN | Pendiente |
| 5662 | 84 | 8 | F84-6901 | 2023-06-07 | 2023-07-07 | 5203.75  | PEN | Pendiente |
...
| 1911 | 33 | 9 | F33-3907 | 2023-05-08 | 2023-05-23 | 5306.00  | USD | Pagado |
| 1471 | 33 | 3 | F33-3907 | 2024-12-07 | 2025-01-06 | 4643.96  | PEN | Vencido |
| 239  | 1  | 9 | F1-5501  | 2024-07-18 | 2024-09-16 | 335.83   | USD | Pendiente |
| 513  | 1  | 9 | F1-5501  | 2023-02-13 | 2023-04-14 | 7486.81  | USD | Pendiente |
| 1237 | 15 | 1 | F15-3741 | 2023-01-18 | 2023-03-04 | 16723.64 | PEN | Pendiente |
| 4314 | 15 | 8 | F15-3741 | 2024-01-05 | 2024-03-05 |**NULL**   | PEN | Pendiente |
| 3947 | 12 | 3 | F12-6573 | 2023-11-27 | 2023-12-27 | 5542.98  | PEN | Pagado |
| 1561 | 12 | 2 | F12-6573 | 2024-12-29 | 2025-02-27 | 17058.96 | USD | Pagado |

-Se detectaron 24 registros con valores duplicados en invoice_number y supplier_id, pero con diferentes: invoice_id, department_id,issue_date, due_date e invoice_amount. 

-Impidiendo ser eliminados por no ser filas duplicadas exactas.

---
### 2.5. Revisión de formato en Fechas:
Usamos la funcion ISDATE para consultar la calidad de los valores en formato fecha. Nos devuelve valores booleanos siendo 1 para de fechas válidas y 0 si hay fechas inválidas. 
```sql
SELECT issue_date
FROM bz_invoices
WHERE ISDATE(issue_date) = 0
```

```sql
SELECT due_date
FROM bz_invoices
WHERE ISDATE(due_date) = 0
```

```sql
SELECT payment_date
FROM bz_payments
WHERE ISDATE(payment_date) = 0
```
No devuelve resultados en ninguna de las 3 consultas, concluyendo la  presencia de valores válidos en el formato fecha.

---
## Fase Silver: Estandarización y limpieza
Con los resultados encontrados en el Análisis Exploratorio, se procede a crear las tablas silver con datos limpios, excluyendo y eliminando los errores, duplicados y data inconsistente.
### 3.1. Creación de Tablas finales:
Se crean las 5 tablas con los tipos de datos correctos: 
```sql
DROP TABLE IF EXISTS sil_departments
CREATE TABLE sil_departments (
    department_id int,
    department_name varchar(20),
    budget_owner varchar(20) )
```
```sql
DROP TABLE IF EXISTS sil_payment_methods
CREATE TABLE sil_payment_methods (
     method_id int,
     method_name varchar(20) )
```
```sql
DROP TABLE IF EXISTS sil_suppliers
CREATE TABLE sil_suppliers (
    supplier_id int,
    supplier_name varchar(20),
    category varchar(20),
    country varchar(20),
    rating varchar(5) )
```
```sql
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
```
```sql
DROP TABLE IF EXISTS sil_payments;
CREATE TABLE sil_payments (
  payment_id INT,
  invoice_id INT ,
  payment_date DATE,
  payment_amount NUMERIC(10,2),
  payment_amount_status VARCHAR(20),
  method_id INT,
  processed_by VARCHAR(20) );
```
