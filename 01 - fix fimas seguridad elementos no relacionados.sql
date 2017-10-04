set xact_abort on
begin tran
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	declare @TipoElemento AS VARCHAR(50) = '1',
                                          @Anio         AS INT = 2017


	if OBJECT_ID('tempdb..#Elementos') is not null
	drop table #Elementos

    CREATE TABLE #Elementos
      (
         idElemento  INT,
         Clave       VARCHAR(100),
         Descripcion VARCHAR(8000)
      )

    DECLARE @idcvedef AS INT

    SET @idcvedef = (SELECT
                       idcvedef
                     FROM
                       PppCveDef
                     WHERE
                      anio = @Anio)

/*



1.	Dependencia

2.	Evento Genérico

3.	Tipo de Requisición

4.	Tipo de Activo

5.	Tipo de Adecuación

6.	Tipo de Solicitud

7.	Tipo de Almacén

8.	Tipo de Póliza

9.	Tipo de Padrón

10.	Clase del CRI

11.	Tipo de Ingreso

12.	Caja Cobro









*/
    ----1. Dependencias
    IF @TipoElemento = '1'
      BEGIN
          INSERT INTO #Elementos
          SELECT
            iddependencia,
            dependencia,
            descripcion
          FROM
            AbsDependencia
          WHERE
            idcvedef = @idcvedef
            AND idnivel = (SELECT
                             Max(idnivel)
                           FROM
                             AbsNivelDep
                           WHERE
                            idcvedef = @idcvedef)
      END

    ----2.	Evento Genérico
    IF @TipoElemento = '2'
      BEGIN
          INSERT INTO #Elementos
          SELECT
            E.idevento,
            E.clave,
            E.descripcion
          FROM
            AbsEventoGen G
            INNER JOIN absevento E
                    ON G.idevento = G.IdEvento
          WHERE
            E.idnivel = (SELECT
                           Max(idnivel)
                         FROM
                           AbsNivelEvento)
            AND baja <> 1
          GROUP  BY
            E.idevento,
            E.clave,
            E.descripcion
      END

    ----3.	Tipo de Requisición
    IF @TipoElemento = '3'
      BEGIN
          INSERT INTO #Elementos
          SELECT
            idtiposolicitud,
            '',
            descripcion
          FROM
            AdqTipoSolicitud
      END

    ---4.	Tipo de Activo
    IF @TipoElemento = '4'
      BEGIN
          INSERT INTO #Elementos
          SELECT
            IdTipoActivo,
            CVETIPO,
            descripcion
          FROM
            AfTipoActivo A
          WHERE
            idNivel = (SELECT
                         Max(idNivel)
                       FROM
                         AfNivelTipoActivo)
      END

    ---5.	Tipo de Adecuación
    IF @TipoElemento = '5'
      BEGIN
          INSERT INTO #Elementos
          SELECT
            idtipoadpptal,
            '',
            descripcion
          FROM
            PppTipoAdPptal
      END

    --6.	Tipo de Solicitud
    IF @TipoElemento = '6'
      BEGIN
          INSERT INTO #Elementos
          SELECT
            idtiposolpago,
            '',
            descripcion
          FROM
            EpTipoSolPago
      END

    -----7.	Tipo de Almacén
    IF @TipoElemento = '7'
      BEGIN
          INSERT INTO #Elementos
          SELECT
            AlmTAlmIdTAlmacen,
           AlmTalmClave,
            AlmTAlmDescripcion
          FROM
            AlmTAlmacen
      END

    -----8.	Tipo de Póliza
    IF @TipoElemento = '8'
      BEGIN
          INSERT INTO #Elementos
          SELECT
            idtipopoliza,
            '',
            descripcion
          FROM
            ContaTipoPoliza
      END

    -----9.	Tipo de Padrón
    IF @TipoElemento = '9'
      BEGIN
          INSERT INTO #Elementos
          SELECT
            IdTipoPadron,
            '',
            Descripcion
          FROM
            IngTipoPadron
      END

    -----10. Clase del CRI
    IF @TipoElemento = '10'
      BEGIN
          INSERT INTO #Elementos
          SELECT
            idNivConceptoCobroArbol,
            clave,
            Descripcion
          FROM
            IngNivConceptoCobroArbol
          WHERE
            anio = @Anio
            AND relTipoIngreso = 1
            AND idTipoConceptoCobroArbol = (SELECT
                                              idTipoConceptoCobroArbol
                                            FROM
                                              IngTipoConceptoCobroArbol
                                            WHERE
                                             presupuestal = 1)
      END

    -----11.Caja Cobro
    IF @TipoElemento = '11'
      BEGIN
          INSERT INTO #Elementos
          SELECT
            IdCajaOfing,
            clave,
            Descripcion
          FROM
            IngCajaOfIng
      END

    -----12. Colectiva
    IF @TipoElemento = '12'
      BEGIN
          INSERT INTO #Elementos
          SELECT
            IdColectiva,
            clave,
            NombreoRazon + Isnull(' ' + ApPaterno, '')
            + Isnull(' ' + ApMaterno, '') AS Descripcion
          FROM
            AbsColectiva
          WHERE
            IdTipoColectiva IN(SELECT
                                 IdTipoColectiva
                               FROM
                                 ContaTipoColectiva
                               WHERE
                                Ltrim(Rtrim(nombrecorto)) IN( 'OPD', 'PO', 'FIS', 'EPEM',
                                                              'OA', 'ONG', 'DFED', 'BA' ))
             OR Clave in('PR04507','OB04094')
      END
	
	
	INSERT INTO SegElementoConfigFirma(idFirmaConfig,idElemento)
    SELECT
		'1',
      A.idelemento
    FROM
      #Elementos as A 
	  left join SegElementoConfigFirma as B on (A.idElemento = B.idElemento)
	WHERE B.idElementoConfigFirma IS NULL
	  order by coalesce(B.idFirmaConfigDet,0)


	  declare @detallesinsertados  as table (idFirmaConfigDet int, idelemento int)

	  insert into SegFirmaConfigDet(idFirmaConfig,Firma1,Puesto1,Funcion1,Firma2,Puesto2,Funcion2,Firma3,Puesto3,Funcion3,Firma4,Puesto4,Funcion4,Firma5,Puesto5,Funcion5)
	  output inserted.idFirmaConfigDet, inserted.Firma5 into @detallesinsertados
	  select '1',0,'','',0,'','',0,'','',0,'','',idElemento,'',''  from  SegElementoConfigFirma where idFirmaConfigDet is null

	   update A set idFirmaConfigDet = B.idFirmaConfigDet from  SegElementoConfigFirma as A
	   join @detallesinsertados as B on (A.idElemento = B.idelemento)
	   where A.idFirmaConfigDet is null

	   update B  set Firma5 = 0 from @detallesinsertados as A
	   join SegFirmaConfigDet as B on (A.idFirmaConfigDet = B.idFirmaConfigDet)

	 commit tran


			
