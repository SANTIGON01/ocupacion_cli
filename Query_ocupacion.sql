	
   SELECT 
    s.SEDESCRIPCION	   AS 'Servicio Ingreso',
    MED.MENombre	   AS 'Apellido Y Nombre',
    HAB.HAUniOperativa AS 'Unidad Operativa',
    uni.UODESCRIPCION  AS 'U.O. Descrip ',
    HAB.HADescripcion  AS 'Hab. Descrip ',
    (ltrim(rtrim(H.[HCApeSol]))  + ', '+ ltrim(rtrim(H.[HCNombre]))) AS 'Datos Paciente', 
	i.INNumInt,
    i.INNumero,
	i.inobrasocial as ObraSocial,
	i.INICD10Actual as INICD10Actual,
    i.INHabitacion   AS 'Habitacion', 
    i.INCama         AS 'Cama',
    i.INFechaIngreso AS 'Fecha Ingreso',
    i.INHoraIngreso  AS 'Hora Ingreso',
    i.INFechaEgreso  AS 'Fecha Egreso',
    i.INHoraEgreso   AS 'Hora Egreso',
    CAST(i.INFechaIngreso AS DATETIME) + CAST(i.INHoraIngreso AS DATETIME) AS 'Dia Hora de Ingreso',
    CAST(i.INFechaEgreso AS DATETIME) + CAST(i.INHoraEgreso AS DATETIME) AS   'Dia Hora de Egreso',
	
    
  CASE 
        WHEN i.INFechaEgreso = '1753-01-01 00:00:00.000' THEN 'Egreso Pendiente'
        ELSE CAST(DATEDIFF(HOUR, 
                CAST(i.INFechaIngreso AS DATETIME) + CAST(i.INHoraIngreso AS DATETIME), 
                CAST(i.INFechaEgreso AS DATETIME)  + CAST(i.INHoraEgreso AS DATETIME)
            ) AS VARCHAR)
    END AS 'Horas En Habitacion',
	
	CASE 
        WHEN i.INFechaEgreso  = '1753-01-01 00:00:00.000' THEN 'Egreso Pendiente'
        ELSE CAST(DATEDIFF(DAY, 
                CAST(i.INFechaIngreso AS DATETIME), 
                CAST(i.INFechaEgreso AS DATETIME)
            ) AS VARCHAR)
    END AS 'Dias En Habitacion',
    CASE 
        WHEN i.INFechaEgreso   = '1753-01-01 00:00:00.000' THEN 'Egreso Pendiente'
        ELSE CONVERT(varchar, CEILING(
                DATEDIFF(DAY, 
                    CAST(i.INFechaIngreso AS DATETIME) + CAST(i.INHoraIngreso AS DATETIME), 
                    CAST(i.INFechaEgreso AS DATETIME) + CAST(i.INHoraEgreso AS DATETIME)
                ) + 1)) + ' días'
    END AS 'Tiempo Total Habitacion',
	epi.EpICD10Aper, EpDesICD10Aper

FROM 
    GACIHEALTH..INTERNAD(Nolock) i
JOIN 
	GACIHEALTH..HISTORIAS(Nolock) H ON  H.[HCNumIng] = I.[INHCNumIng]
JOIN 
    GACIHEALTH..SECCIONES(Nolock) s ON i.INSERVINGRESO = s.SECODIGO
JOIN 
    GACIHEALTH..MEDICOS(Nolock) med ON i.INMedicoInterna = med.MECodigo AND i.INMedicoEnvia = med.MECodigo
JOIN 
    GACIHEALTH..HABIT(Nolock) HAB ON i.INHabitacion = HAB.HANumero
JOIN 
    GACIHEALTH..UNIDOPER(Nolock) uni ON HAB.HAUniOperativa = uni.UOCodigo
lEFT JOIN
GACIHEALTH..epicrisis(Nolock) epi ON epi.EpInNumInt = i.INNumInt

WHERE 
    MONTH(CAST(i.INFechaIngreso AS DATETIME)) >= 4
    AND YEAR(CAST(i.INFechaIngreso AS DATETIME)) = 2024

GROUP BY 
    s.SEDESCRIPCION,
    MED.MENombre,
    HAB.HAUniOperativa,
    uni.UODESCRIPCION,
    HAB.HADescripcion,
	(ltrim(rtrim(H.[HCApeSol]))  + ', '+ ltrim(rtrim(H.[HCNombre]))),
    i.INNumInt,
    i.INNumero,
	i.inobrasocial,
	i.INICD10Actual ,
    i.INHabitacion,
    i.INCama,
    i.INFechaIngreso,
    i.INHoraIngreso,
    i.INFechaEgreso,
    i.INHoraEgreso,
    CAST(i.INFechaIngreso AS DATETIME) + CAST(i.INHoraIngreso AS DATETIME),
    CAST(i.INFechaEgreso AS DATETIME)  + CAST(i.INHoraEgreso AS DATETIME),
	epi.EpICD10Aper, EpDesICD10Aper
ORDER BY 
    i.INFechaIngreso ;

