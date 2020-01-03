--Measure Density on table columns to decide the order of fields in an index.
--high density --> less unique data. --> put first the fields with low density.
--Density values range from 0 to 1. Density = 1/[# of distinct values in a column] 

select	1.00/convert(decimal(10,2),count(distinct pl.Type))
		,1.00/convert(decimal(10,2),count(distinct pl.No_))
		,1.00/convert(decimal(10,2),count(distinct pl.[Job No_]))
		,1.00/convert(decimal(10,2),count(distinct pl.[Job Task No_]))
		,1.00/convert(decimal(10,2),count(distinct pl.[Planning Line No_]))
from [SSI$Purchase Line] pl