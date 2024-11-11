DECLARE @FechaInicio DATETIME = '2024-04-01';
DECLARE @FechaFin DATETIME = '2024-04-30';
DECLARE @UnidadOperativa int = 51; --dejar en 0 para todos los registros

WITH CambiosHabitacion AS (
    SELECT
        INNumInt,
        INFechaPase,
        INHoraPase,
        INHabitPase,
        INCamaPase,
        LEAD(INFechaPase) OVER (PARTITION BY INNumInt ORDER BY INFechaPase, INHoraPase) AS FechaSalida,
        LEAD(INHoraPase) OVER (PARTITION BY INNumInt ORDER BY INFechaPase, INHoraPase) AS HoraSalida
    FROM
        GACIHEALTH..INTERNA1 (NOLOCK)
),

CambiosConSalida AS (
    SELECT
        ch.INNumInt,
        ch.INFechaPase,
        ch.INHoraPase,
        ch.INHabitPase,
        ch.INCamaPase,
        COALESCE(ch.FechaSalida, i.INFechaEgreso) AS FechaSalida,
        COALESCE(ch.HoraSalida, i.INHoraEgreso) AS HoraSalida
    FROM
        CambiosHabitacion ch
    LEFT JOIN
        GACIHEALTH..INTERNAD (NOLOCK) i ON ch.INNumInt = i.INNumInt
)

SELECT
    s.SEDESCRIPCION AS 'Servicio Ingreso',
    MED.MENombre AS 'Apellido Y Nombre',
    HAB.HAUniOperativa AS 'Unidad Operativa',
    uni.UODESCRIPCION AS 'U.O. Descrip',
    HAB.HADescripcion AS 'Hab. Descrip',
    (LTRIM(RTRIM(H.HCApeSol)) + ', ' + LTRIM(RTRIM(H.HCNombre))) AS 'Datos Paciente',
    i.INNumInt,
    i.INNumero,
    i.inobrasocial AS ObraSocial,
    i.INICD10Actual AS INICD10Actual,
    c.INHabitPase AS 'Habitacion',
    c.INCamaPase AS 'Cama',
    c.INFechaPase AS 'Fecha Ingreso Hab.',
    c.INHoraPase AS 'Hora Ingreso Hab.',
    c.FechaSalida AS 'Fecha Egreso Hab.',
    c.HoraSalida AS 'Hora Egreso Hab.',

    CASE
        WHEN c.FechaSalida = '1753-01-01 00:00:00.000' THEN 'Egreso Pendiente'
        ELSE CAST(DATEDIFF(HOUR,
                CAST(c.INFechaPase AS DATETIME) + CAST(c.INHoraPase AS DATETIME),
                CAST(c.FechaSalida AS DATETIME) + CAST(c.HoraSalida AS DATETIME)
            ) AS VARCHAR)
    END AS 'Horas en Hab.',

    CASE
        WHEN c.FechaSalida = '1753-01-01 00:00:00.000' THEN 'Egreso Pendiente'
        ELSE CAST(DATEDIFF(DAY,
                CAST(c.INFechaPase AS DATETIME),
                CAST(c.FechaSalida AS DATETIME)
            ) AS VARCHAR)
    END AS 'Dias en Hab.',

    CASE
        WHEN c.FechaSalida = '1753-01-01 00:00:00.000' THEN 'Egreso Pendiente'
        ELSE CONVERT(VARCHAR, CEILING(
                DATEDIFF(DAY,
                    CAST(c.INFechaPase AS DATETIME) + CAST(c.INHoraPase AS DATETIME),
                    CAST(c.FechaSalida AS DATETIME) + CAST(c.HoraSalida AS DATETIME)
                ) + 1)) + ' días'
    END AS 'Tiempo Total en Hab.',
    epi.EpICD10Aper, EpDesICD10Aper

FROM
    GACIHEALTH..INTERNAD (NOLOCK) i
JOIN
    GACIHEALTH..HISTORIAS (NOLOCK) H ON H.HCNumIng = i.INHCNumIng
JOIN
    GACIHEALTH..SECCIONES (NOLOCK) s ON i.INSERVINGRESO = s.SECODIGO
JOIN
    GACIHEALTH..MEDICOS (NOLOCK) med ON i.INMedicoInterna = med.MECodigo
JOIN
    GACIHEALTH..HABIT (NOLOCK) HAB ON i.INHabitacion = HAB.HANumero
JOIN
    GACIHEALTH..UNIDOPER (NOLOCK) uni ON HAB.HAUniOperativa = uni.UOCodigo
LEFT JOIN
    GACIHEALTH..epicrisis (NOLOCK) epi ON epi.EpInNumInt = i.INNumInt
JOIN
    CambiosConSalida c ON i.INNumInt = c.INNumInt

WHERE
    (c.INFechaPase >= @FechaInicio and c.INFechaPase <= @FechaFin) 
	and (@UnidadOperativa IS NULL OR @UnidadOperativa = 0 OR hab.HAUniOperativa = @UnidadOperativa)

ORDER BY
    c.INFechaPase, c.INHoraPase;