/*
Proyecto integrador ABD — 01_restore_adventureworks.sql
Archivo: 01_restore_adventureworks.sql
Equipo: ???

Precondiciones:
- Instancia SQL Server en Docker ya corriendo (MSQLSRVHP puerto 1433 o MSQLSRVLP puerto 1435).
- El archivo AdventureWorks2014.bak copiado DENTRO del contenedor en /var/opt/mssql/backup/.
- Conectarse como sa (tiene permisos para restaurar).
- La base AdventureWorks2014 NO debe existir todavía. Si existe, ver la nota de WITH REPLACE al final.

Parámetros:
- Respaldo: /var/opt/mssql/backup/AdventureWorks2014.bak
- Base destino: AdventureWorks2014
- Archivos de datos: /var/opt/mssql/AdventureWorks2014.mdf y /var/opt/mssql/AdventureWorks2014_log.ldf
  (en /var/opt/mssql, SIN /data: en el contenedor HP la carpeta /var/opt/mssql/data da el error 5149)

Evidencia de ejecución: PENDIENTE (guardar la salida de los SELECT y del DBCC CHECKDB).
*/



-- Restaurar la base (aquí sí se crea AdventureWorks2014)

-- MOVE cambia la ruta donde quedan los archivos .mdf y .ldf.
-- Si el LogicalName del paso 1 es distinto, corrígelo aquí.
RESTORE DATABASE AdventureWorks2014
FROM DISK = N'/var/opt/mssql/backup/AdventureWorks2014.bak'
WITH
    MOVE N'AdventureWorks2014_Data' TO N'/var/opt/mssql/AdventureWorks2014.mdf',
    MOVE N'AdventureWorks2014_Log'  TO N'/var/opt/mssql/AdventureWorks2014_log.ldf',
    RECOVERY,
    STATS = 5;
GO


-- PASO 3: Verificar que quedó bien

-- La base debe aparecer como ONLINE.
SELECT name, state_desc, recovery_model_desc
FROM sys.databases
WHERE name = 'AdventureWorks2014';
GO

-- Revisa la integridad de toda la base. Debe terminar sin errores.
USE AdventureWorks2014;
GO
DBCC CHECKDB;
GO

-- Conteo rápido de prueba en una tabla conocida.
SELECT COUNT(*) AS TotalPersonas FROM Person.Person;
GO