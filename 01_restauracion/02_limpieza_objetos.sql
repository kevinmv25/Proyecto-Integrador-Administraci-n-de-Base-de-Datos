/*
Proyecto integrador ABD — 02_limpieza_objetos.sql
Archivo: 02_limpieza_objetos.sql
Equipo: PENDIENTE

Qué hace: elimina ÚNICAMENTE los 10 stored procedures predeterminados (demo)
que trae AdventureWorks2014 recién restaurada. NO toca los SPs del equipo.
Se puede correr varias veces: la segunda vez ya no encuentra nada que borrar.

Precondiciones:
- La base AdventureWorks2014 ya restaurada (script 01).
- Ejecutar conectado a la instancia, como sa.
- Si el inventario del PASO 1 muestra un SP demo que NO está en la lista
  del PASO 2, agrégalo a #Objetivos antes de ejecutar el PASO 3.

Parámetros:
- Base destino: AdventureWorks2014 (el script se niega a correr en otra base).
- SPs a eliminar: los 10 de la tabla #Objetivos (7 en dbo, 3 en HumanResources).

Evidencia de ejecución: PENDIENTE 
*/

USE AdventureWorks2014;
GO

-- 
-- GUARDIA: este script SOLO corre en AdventureWorks2014
-- 

IF DB_NAME() <> N'AdventureWorks2014'
BEGIN
    RAISERROR('Este script solo se ejecuta en AdventureWorks2014. Base actual: %s', 16, 1, DB_NAME());
    SET NOEXEC ON;
END
GO

-- 
-- PASO 1: Inventario de TODOS los SPs de la base (solo lectura)
-- Revisar primero este listado antes de borrar nada.

SELECT
    s.name AS Esquema,
    p.name AS Procedimiento,
    p.create_date AS Creado,
    p.modify_date AS Modificado
FROM sys.procedures AS p
JOIN sys.schemas AS s ON s.schema_id = p.schema_id
ORDER BY s.name, p.name;
GO

-- ============================================================
-- PASO 2: Lista de los SPs predeterminados a eliminar
-- Solo estos 10 se borran. Cualquier SP del equipo NO está aquí,
-- así que nunca se genera un DROP para él, aunque se repita el despliegue.
-- ============================================================
CREATE TABLE #Objetivos
(
    Esquema SYSNAME NOT NULL,
    Nombre  SYSNAME NOT NULL,
    PRIMARY KEY (Esquema, Nombre)
);

INSERT INTO #Objetivos (Esquema, Nombre) VALUES
    (N'dbo',            N'uspGetBillOfMaterials'),
    (N'dbo',            N'uspGetEmployeeManagers'),
    (N'dbo',            N'uspGetManagerEmployees'),
    (N'dbo',            N'uspGetWhereUsedProductID'),
    (N'dbo',            N'uspLogError'),
    (N'dbo',            N'uspPrintError'),
    (N'dbo',            N'uspSearchCandidateResumes'),
    (N'HumanResources', N'uspUpdateEmployeeHireInfo'),
    (N'HumanResources', N'uspUpdateEmployeeLogin'),
    (N'HumanResources', N'uspUpdateEmployeePersonalInfo');
GO

-- Vista previa: solo los de la lista que REALMENTE existen en la base.
-- Si aquí falta uno de la lista, es porque ya se borró antes (o no existía).
SELECT
    s.name AS Esquema,
    p.name AS Procedimiento,
    N'Se eliminará' AS Accion
FROM sys.procedures AS p
JOIN sys.schemas AS s ON s.schema_id = p.schema_id
JOIN #Objetivos AS o ON o.Esquema = s.name AND o.Nombre = p.name
ORDER BY s.name, p.name;
GO

-- ============================================================
-- PASO 3: Generar el SQL dinámico y ejecutarlo
-- Se arma con nombres calificados (esquema.procedimiento) y QUOTENAME,
-- por si algún nombre trae espacios o caracteres especiales.
-- El PRINT muestra los DROP antes de ejecutarlos: revísalos en la
-- pestaña de mensajes. Para hacer solo una revisión sin borrar nada,
-- comenta la línea del EXEC, corre el script y revisa lo impreso.
-- ============================================================
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += N'DROP PROCEDURE '
    + QUOTENAME(s.name) + N'.' + QUOTENAME(p.name) + N';'
    + CHAR(13) + CHAR(10)
FROM sys.procedures AS p
JOIN sys.schemas AS s ON s.schema_id = p.schema_id
JOIN #Objetivos AS o ON o.Esquema = s.name AND o.Nombre = p.name
ORDER BY s.name, p.name;

PRINT N'--- SQL dinámico generado (revisar antes de ejecutar) ---';
PRINT @sql;

IF @sql <> N''
BEGIN
    EXEC sp_executesql @sql;
    PRINT N'Limpieza ejecutada.';
END
ELSE
BEGIN
    PRINT N'No había SPs predeterminados que eliminar (ya estaban borrados o no existían).';
END
GO

-- ============================================================
-- PASO 4: Verificación final
-- Debe quedar VACÍO de los 10 demo. Si aparecen SPs del equipo,
-- es correcto: esos no se tocan nunca.
-- ============================================================
SELECT
    s.name AS Esquema,
    p.name AS Procedimiento
FROM sys.procedures AS p
JOIN sys.schemas AS s ON s.schema_id = p.schema_id
ORDER BY s.name, p.name;

SELECT COUNT(*) AS SPsRestantes
FROM sys.procedures;
GO

DROP TABLE #Objetivos;
GO

-- Reactiva la ejecución (por si la guardia la había apagado).
SET NOEXEC OFF;
GO