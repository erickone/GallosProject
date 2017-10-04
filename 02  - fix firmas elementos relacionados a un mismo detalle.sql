set xact_abort on
begin tran
	  declare @SegElementoConfigFirmaNOborrar as table (idelemento int)

	  insert into @SegElementoConfigFirmaNOborrar(idelemento)
	  select min(idElemento)
			from SegElementoConfigFirma 
			group by idFirmaConfigDet
			having count(*) > 1




	 declare @SegElementoConfigFirmaSIborrar as table (id int,idFirmaConfigDet int)

	 insert into @SegElementoConfigFirmaSIborrar(id, idFirmaConfigDet)
	  select ROW_NUMBER() over (order by idFirmaConfigDet),idFirmaConfigDet
			from SegElementoConfigFirma 
			where idElemento not in (select idelemento from @SegElementoConfigFirmaNOborrar)
			group by idFirmaConfigDet
			having count(*) > 1
	
	declare @detallesinsertados  as table (idFirmaConfigDet int, idelemento int)

	insert into SegFirmaConfigDet(idFirmaConfig,Firma1,Puesto1,Funcion1,Firma2,Puesto2,Funcion2,Firma3,Puesto3,Funcion3,Firma4,Puesto4,Funcion4,Firma5,Puesto5,Funcion5)
	output inserted.idFirmaConfigDet, inserted.Firma5 into @detallesinsertados
	select C.idFirmaConfig, C.Firma1, C.Puesto1, C.Funcion1, C.Firma2, C.Puesto2, C.Funcion2, C.Firma3, C.Puesto3, C.Funcion3, C.Firma4, C.Puesto4, C.Funcion4, A.idElemento, C.Puesto5, C.Funcion5 
	from SegElementoConfigFirma as A
	join @SegElementoConfigFirmaSIborrar as B on (A.idFirmaConfigDet = B.idFirmaConfigDet)
	join SegFirmaConfigDet as C on (C.idFirmaConfigDet = B.idFirmaConfigDet)
	
	update A set idFirmaConfigDet = B.idFirmaConfigDet from  SegElementoConfigFirma as A
	   join @detallesinsertados as B on (A.idElemento = B.idelemento)

	update B  set Firma5 = 0 from @detallesinsertados as A
	   join SegFirmaConfigDet as B on (A.idFirmaConfigDet = B.idFirmaConfigDet)


	

	commit tran