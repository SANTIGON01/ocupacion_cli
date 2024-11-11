DECLARE @FechaInicio DATETIME = '2024-04-01';
DECLARE @FechaFin DATETIME = '2024-04-30';
DECLARE @UnidadOperativa int = 60;

DECLARE @Multiplicador int = 
    CASE @UnidadOperativa 
		WHEN 20 THEN 14		--NEONATOLOGÍA                  
		WHEN 30 THEN 2		--GUARDIA
        WHEN 50 THEN 12		--INTERNACION PB                
        WHEN 51 THEN 14		--INTERNACION 1A                
        WHEN 53 THEN 17		--INTERNACION 2A                
		WHEN 60 THEN 12		--MATERNIDAD
		WHEN 70 THEN 8		--QUIROFANOS GRALES
		WHEN 90 THEN 6		--SERV. GASTROENTEROLOGÍA                   
		WHEN 150 THEN 7		--SERV. HEMODINAMIA                          
		WHEN 180 THEN 6		--UNIDAD CORONARIA              
		WHEN 190 THEN 10	--UNIDAD TERAPIA INTENSIVA      	
        ELSE 100			--Cantidad total de camas
    END;

DECLARE @HorasTotalesPeriodo int = DATEDIFF(HOUR, @FechaInicio, DATEADD(DAY, 1, @FechaFin));

;WITH CambiosHabitacion AS (
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
),
EstanciasLimitadas AS (
    SELECT
        c.INNumInt,
        c.INFechaPase,
        c.INHoraPase,
        c.INHabitPase,
        c.INCamaPase,
        CASE
            WHEN c.INFechaPase < @FechaInicio THEN @FechaInicio
            ELSE c.INFechaPase
        END AS FechaIngresoAjustada,
        CASE
            WHEN c.INFechaPase < @FechaInicio THEN '00:00:00'
            ELSE c.INHoraPase
        END AS HoraIngresoAjustada,
        CASE
            WHEN c.FechaSalida = '1753-01-01 00:00:00.000' OR c.FechaSalida > @FechaFin THEN @FechaFin
            ELSE c.FechaSalida
        END AS FechaSalidaAjustada,
        CASE
            WHEN c.FechaSalida = '1753-01-01 00:00:00.000' OR c.FechaSalida > @FechaFin THEN '23:59:59'
            ELSE c.HoraSalida
        END AS HoraSalidaAjustada
    FROM
        CambiosConSalida c
    WHERE
        (c.INFechaPase <= @FechaFin AND (c.FechaSalida >= @FechaInicio OR c.FechaSalida = '1753-01-01 00:00:00.000'))
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
    e.INHabitPase AS 'Habitacion',
    e.INCamaPase AS 'Cama',
    e.FechaIngresoAjustada AS 'Fecha Ingreso Hab. (Ajustada)',
    e.HoraIngresoAjustada AS 'Hora Ingreso Hab. (Ajustada)',
    e.FechaSalidaAjustada AS 'Fecha Egreso Hab. (Ajustada)',
    e.HoraSalidaAjustada AS 'Hora Egreso Hab. (Ajustada)',
    CASE
        WHEN e.FechaSalidaAjustada = '1753-01-01 00:00:00.000' THEN 'Egreso Pendiente'
        ELSE CAST(DATEDIFF(HOUR,
                CAST(e.FechaIngresoAjustada AS DATETIME) + CAST(e.HoraIngresoAjustada AS DATETIME),
                CAST(e.FechaSalidaAjustada AS DATETIME) + CAST(e.HoraSalidaAjustada AS DATETIME)
            ) AS VARCHAR)
    END AS 'Horas en Hab. Ajustadas',
    epi.EpICD10Aper, 
    EpDesICD10Aper,
    
    CAST(
        (SUM(CASE
            WHEN e.FechaSalidaAjustada = '1753-01-01 00:00:00.000' THEN 0
            ELSE DATEDIFF(HOUR,
                    CAST(e.FechaIngresoAjustada AS DATETIME) + CAST(e.HoraIngresoAjustada AS DATETIME),
                    CAST(e.FechaSalidaAjustada AS DATETIME) + CAST(e.HoraSalidaAjustada AS DATETIME)
                )
        END) OVER()) * 100.0 / 
        NULLIF(@Multiplicador * @HorasTotalesPeriodo, 0) AS DECIMAL(10,2)
    ) AS 'Porcentaje de Ocupación'

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
    EstanciasLimitadas e ON i.INNumInt = e.INNumInt
WHERE 
    (@UnidadOperativa IS NULL OR @UnidadOperativa = 0 OR hab.HAUniOperativa = @UnidadOperativa)
ORDER BY
	HAB.HAUniOperativa,
    CONVERT(INT, DATEDIFF(HOUR,
                CAST(e.FechaIngresoAjustada AS DATETIME) + CAST(e.HoraIngresoAjustada AS DATETIME),
                CAST(e.FechaSalidaAjustada AS DATETIME) + CAST(e.HoraSalidaAjustada AS DATETIME)
            )) DESC;