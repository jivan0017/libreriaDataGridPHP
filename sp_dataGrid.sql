CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_dataGrid`(
#PARAMETROS DE ENTRADA
IN _tableName VARCHAR(50),
IN _cols VARCHAR(200),
IN _criterio VARCHAR(200),
IN _concatWhere VARCHAR(200),

#PARAMETROS NUEVOS::
IN _pagina INT,
IN _reg_x_pagina INT,
#REQUERIMIENTO ORDENACION REQ-02-37
IN _columnNameOrder VARCHAR(35),
IN _orderType VARCHAR(10)
)
BEGIN
	#VARIABLES MIEMBRO
    DECLARE contador INT(5);
	DECLARE search VARCHAR(200) default '';
    DECLARE elementLoop VARCHAR (100);
    #NUMERO DE REGISTROS ALMACENADOS EN LA TABLA TEMPORAL
    DECLARE nrowsTmpTable INT(11);
    #CONTROLA LA CONCATENACION O CADENA WHERE concat
    
    DECLARE ciclo_fin INTEGER(1) DEFAULT 0;
    DECLARE strWHEREconcat VARCHAR (50);
    DECLARE strWHEREconcatEnd VARCHAR (1);
    DECLARE strColumsWhere VARCHAR (50);
    DECLARE strFinalWhere VARCHAR (100);
	#CU-02-37
    DECLARE colOrder VARCHAR(65);
    DECLARE strOrderBy VARCHAR (65);
    DECLARE strOrderType VARCHAR(4);
    #END [ CU-02-37 ]
	#NUEVO DATO
    DECLARE pagina_actual INT;
	#declaracion del cursor para recorrer tabla temporal	  
    DECLARE cursorWheres CURSOR FOR 
          SELECT element FROM tmpSplitElements;

    #DECLARACION DEL PUNTERO PARA EL LOOP
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET ciclo_fin=1;
    #CONTADOR PARA EL LOOP
    
    #-----------------[ PAGINADOR ]-------------------------------------
    SET pagina_actual = (_pagina - 1) * _reg_x_pagina;
    #-------------------------------------------------------------------
    
    
	SET contador = 0;
	SET strWHEREconcat = ' CONCAT (';
	SET strWHEREconcatEnd = ') ';
	SET strColumsWhere = '';
	SET elementLoop = '';        
	SET strFinalWhere = '';
    
	#si los campos que forman el criterio de busqueda estan diferentes de vacio
	IF (_concatWhere != '')THEN
		#ENVIAR LA CADENA LINEAL A LA FUNCTION::
        #CALL splitStr('jaime,ivan,diaz,gaona', ',');
        CALL splitStr(_concatWhere, ',');

        # OBTENIENDO LA CANTIDAD DE REGISTROS
        select count(id) from tmpSplitElements into nrowsTmpTable; 
        
		  

        
        IF (nrowsTmpTable > 1) THEN
          
		  #select nrowsTmpTable as totalLoops;
		  #APERTURA DEL CURSOR
          OPEN cursorWheres;
          
          #INICIO DEL CICLO ]------------ LOOP --------------------------
          getAlltmpTable : LOOP			 
              #select contador as valorContador;
		      #ASIGNANDO EL ELEMENTO
              fetch cursorWheres INTO elementLoop;
             
              IF (contador = (nrowsTmpTable-1))THEN
              
				SET strColumsWhere = CONCAT(strColumsWhere, elementLoop);
                #select "ultimo elemento";
              ELSEIF (contador < (nrowsTmpTable-1)) THEN
				#select "primer elemento" as recorrido1;
				#SET strColumsWhere = CONCAT(strColumsWhere, CONCAT(elementLoop, ',"  ",'));
                 SET strColumsWhere = CONCAT(strColumsWhere, elementLoop);
                 SET strColumsWhere = CONCAT(strColumsWhere,', "  ",');
                 
              END IF;
                            
			  #saber si es el final del ciclo
			  IF ciclo_fin = 1 THEN
				LEAVE getAlltmpTable;
			  END IF;
              #INCREMENTANDO CONTADOR
			  SET contador = (contador+1);
                            
          END LOOP getAlltmpTable;
          # END LOOP ]--------------------------------------------------------
          #CERRANDO CURSOR
          CLOSE cursorWheres;
          
          #BORRAR TABLA TEMPORAL
          drop table tmpSplitElements;
		  #--------------------------------------------------------------
          #PRIMERA CONCATENACION  "CONCAT("
          SET strFinalWhere = strWHEREconcat;          
          #SEGUNDA CONCATENACION "CONCAT(" + " [ID, "  ", USERNAME] "
          SET strFinalWhere = CONCAT(strFinalWhere, strColumsWhere);          
          #TERCERA CONCATENACION "CONCAT(" + " [ID, "  ", USERNAME] " + "[)]"
          SET strFinalWhere = CONCAT(strFinalWhere, strWHEREconcatEnd);          
          #select strFinalWhere as whereTotal;
          
        ELSE
		  #asignando criterio SIMPLE:  WHERE [ID] LIKE "%' _criterio_ '%"
                    
          SET strFinalWhere = _concatWhere;
          #select strFinalWhere as whereUnitario;
          
        END IF;
        
    END IF;

    #select _criterio as criterioPrevioWhere;
	# concatenando todo el WHERE
	IF (_criterio != '') THEN
        #CONCAT (username,"  ",email)
		SET search = CONCAT('WHERE ', strFinalWhere ,' LIKE "%', _criterio, '%"');        
    END IF;
    
    SET strOrderType = '';
    SET colOrder = _columnNameOrder;
    #CASO DE USO  CU02-37  CREAR CADENAS DE ORDENAMIENTO POR COLUMNAS 
    IF (colOrder != '') THEN
		# SI EXISTE TIPO DE ORDENAMIENTO
		IF (_orderType != '') THEN
			SET strOrderType = _orderType;
		ELSE
			SET strOrderType = 'ASC';
        END IF;
    
		SET strOrderBy = CONCAT('ORDER BY ', colOrder, ' ', strOrderType, ' ');
	ELSE
		#DEJAR VACIO POR DEFECTO LA CADENA
		SET strOrderType = '';
    END IF;
	#FINAL [ CU-02-37 ]----------------------------------------------

	#PAGINATOR :::::::::::::::::::::::::::::::::::::::::::::
	SET @sentencia = CONCAT('
		SELECT
			  COUNT(*) INTO @countx
	    FROM  ',_tableName,'
        ',search,';
    ');
    #SELECT @sentencia as sentencia;
    #PREPARANDO LA CONSULTA
    PREPARE consulta FROM @sentencia;
    EXECUTE consulta;    
    #liberando variables::
    DEALLOCATE PREPARE consulta;
    SET @sentencia = NULL;	
    # ::::::::::::::::::::::::::::::::::::::::::::::::::::::

    SET @sentencia = CONCAT('
		SELECT
			  ',_cols,', @countx as partialTotal
	    FROM  ',_tableName,'
        ',search, strOrderBy,'
        
        LIMIT ',pagina_actual,',',_reg_x_pagina,';
    ');
    #SELECT @sentencia as sentencia;
    #PREPARANDO LA CONSULTA
    PREPARE consulta FROM @sentencia;
    EXECUTE consulta;    
    #liberando variables::
    DEALLOCATE PREPARE consulta;
    SET @sentencia = NULL;

END