declare @FechaEgresos DATETIME = '2024-04-09'

select 
	count(I.INNumInt) as 'Cantidad de egresos'
from 
	INTERNAD I
where
	i.INFechaEgreso = @FechaEgresos
