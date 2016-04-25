CREATE DEFINER=`root`@`localhost` PROCEDURE `splitStr`(
in cadena TEXT,
in separador VARCHAR(20)
)
BEGIN

    DECLARE itemArray TEXT;
    DECLARE i INT;
    DECLARE tmp INT;
 
    SET i = 1; # se le puede dar cualquier valor menos 0.
 
    
    #CREANDO TABLAS TEMPORALES
	DROP TEMPORARY TABLE IF EXISTS tmpSplitElements;
	
	CREATE TEMPORARY TABLE tmpSplitElements ( 
    id INT(11) , element VARCHAR(30)
	);   
    
    # INTRO BUCLE
    WHILE i > 0 DO
 
        SET i = INSTR(cadena,separador); 
        # seteo i a la posicion donde esta el caracter para separar
        # realiza lo mismo que indexOf en javascript
 
        SET itemArray = SUBSTRING(cadena,1,i-1); 
        # esta variable guardara el valor actual del supuesto array
        # se logra cortando desde la posicion 1 que para MySQL es la primera letra (en javascript es 0)
        # hasta la posicion donde se encuentra la cadena a separar -1 ya que sino incluiria el 1er caracter
        # del caracter o cadena de caracteres que hacen de separador
        
        IF i > 0 THEN
        
            SET cadena = SUBSTRING(cadena,i+CHAR_LENGTH(separador),CHAR_LENGTH(cadena));
                
        # corto / preparo la cadena total para la proxima vez que se entre al bucle para eso corto desde la posicion
        # donde esta el caracter separador hasta el tamaño total de la cadena
        # como el separador puede ser de n caracteres en el 2do parametro paso i que es la posicion del separador
        # sumado al tamaño de su cadena 
 
        ELSE
        
        # si el if entra aca es porque i ya vale 0 y no entrara nuevamente al bucle lo cual significa que la 
        # cadena original ya no tiene separadores por ende lo que queda de ella es igual a la ultima posicion
        # del supuesto array
 
            SET itemArray = cadena;
         
        END IF;
        
        # he creado una tabla test que tiene como estructura:
        # id int, i int, texto1 text, texto2 text para subir de muestra como cambia el indice (i)
        # y como sube el elemento iterado y por ultimo la cadena original para ver como va mutando
 
        #INSERT INTO test (i,texto1,texto2) VALUES (i,itemArray,cadena);
		#select i as counter, itemArray as palabra, cadena as cadena;
        
        
		insert into tmpSplitElements (id,element) VALUES (i,itemArray);
		
        #select count(id) from tmpSplitElements into tmp;        
        #select concat(tmp, concat(tmp, '<=')) as unionTmp;
        
    END WHILE;
    
	
    #select * from tmpSplitElements;
    
END