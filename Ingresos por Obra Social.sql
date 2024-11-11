DECLARE @FechaInicio DATETIME = '2024-05-01';
DECLARE @FechaFin DATETIME = '2024-05-31';

SELECT 
    O.OSRazonSocial as 'Obra Social', 
    COUNT(I.INNumInt) AS Internaciones
FROM 
    INTERNAD I
JOIN 
    OBRASOCIAL O ON I.INObraSocial = O.OSCodigo
WHERE 
    I.INFechaIngreso >= @FechaInicio and I.INFechaIngreso <= @FechaFin
GROUP BY 
    O.OSRazonSocial
ORDER BY 
    o.OSRazonSocial;