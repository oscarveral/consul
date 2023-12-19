/*
Asignatura: Bases de Datos
Curso: 2022/23
Convocatoria: junio

Practica: P3. Definicion y Modificacion de Datos en SQL

Equipo de practicas: bd2307
 Integrante 1: Oscar Vera Lopez 
 Integrante 2: Mattia Lucarini
*/

--------------------------------------------------------------------------------------
-- EJERCICIO 2. Insertar comentarios de tabla y de columna en el Diccionario de Datos

COMMENT ON TABLE solista IS 'Lista de solistas registrados en la plataforma.';
COMMENT ON COLUMN musico.id_musico IS 'Id del musico.';
COMMENT ON COLUMN musico.nombre IS 'Nombre del musico.';
COMMENT ON COLUMN musico.banda IS 'Banda a la que pertenece el musico.';

SELECT *
FROM USER_TAB_COMMENTS
WHERE table_name = 'SOLISTA';

SELECT *
FROM USER_COL_COMMENTS
WHERE table_name = 'MUSICO';

/*
    En Oracle, una sentencia COMMENT es una sentencia LDD, lo que significa que
    después de su ejecución exitosa se produce un COMMIT para confirmar los 
    cambios realizados de forma automática. Las sentencias LDD producen COMMIT 
    implícitos al finalizar con éxito.
    
    Desde el punto de vista de las transacciones, al ejecutar una sentencia 
    COMMENT se inicia y finaliza una transacción, de forma que si es exitosa,
    se produce el COMMIT implícito en las sentencias LDD.
    
    https://docs.oracle.com/cd/B14117_01/server.101/b10759/statements_1001.htm
*/

--------------------------------------------------------------------------------------
-- EJERCICIO 3. Modificar valores de una columna

SELECT id_usuario, nombre, cuota
FROM USUARIO
WHERE id_usuario IN (SELECT invitador
                        FROM USUARIO
                        GROUP BY invitador
                        HAVING COUNT(*) > 1 AND invitador IS NOT NULL)
ORDER BY nombre;

UPDATE USUARIO SET cuota=0.95*cuota
WHERE id_usuario IN (SELECT invitador
                        FROM USUARIO
                        GROUP BY invitador
                        HAVING COUNT(*) > 1 AND invitador IS NOT NULL);

SELECT id_usuario, nombre, cuota
FROM USUARIO
WHERE id_usuario IN (SELECT invitador
                        FROM USUARIO
                        GROUP BY invitador
                        HAVING COUNT(*) > 1 AND invitador IS NOT NULL)
ORDER BY nombre;

ROLLBACK;

SELECT id_usuario, nombre, cuota
FROM USUARIO
WHERE id_usuario IN (SELECT invitador
                        FROM USUARIO
                        GROUP BY invitador
                        HAVING COUNT(*) > 1 AND invitador IS NOT NULL)
ORDER BY nombre;

--------------------------------------------------------------------------------------
-- EJERCICIO 4. Modificar una clave primaria de manera ordenada.

/*
    Las únicas tablas que referencian a usuario son USUARIO, 
    LISTA y LISTA_CANCION.
*/
SELECT *
FROM USUARIO
WHERE id_usuario = 'U001' or invitador = 'U001';

SELECT *
FROM LISTA
WHERE usuario = 'U001';

SELECT *
FROM LISTA_CANCION
WHERE usuario = 'U001';

/*
    Una opción consiste en desactivar las restricciones 
    de las claves ajenas en todas las tablas que referencian 
    a un usuario para poder así actualizar la clave sin peligro de error.
*/

SET CONSTRAINTS user_fk_user DEFERRED;
SET CONSTRAINTS lista_fk_user DEFERRED;
SET CONSTRAINTS lista_cancion_fk_lista DEFERRED;

UPDATE USUARIO SET id_usuario = 'U901'
WHERE id_usuario = 'U001';

UPDATE USUARIO SET invitador = 'U901'
WHERE invitador = 'U001';

SET CONSTRAINTS user_fk_user IMMEDIATE;

UPDATE LISTA SET usuario = 'U901'
WHERE usuario = 'U001';

SET CONSTRAINTS lista_fk_user IMMEDIATE;

UPDATE LISTA_CANCION SET usuario = 'U901'
WHERE usuario = 'U001';

SET CONSTRAINTS lista_cancion_fk_lista IMMEDIATE;

SELECT *
FROM USUARIO
WHERE id_usuario = 'U901' or invitador = 'U901';

SELECT *
FROM LISTA
WHERE usuario = 'U901';

SELECT *
FROM LISTA_CANCION
WHERE usuario = 'U901';

COMMIT;

--------------------------------------------------------------------------------------
-- EJERCICIO 5. Intercambio

SELECT id_album, titulo, genero
FROM ALBUM
WHERE genero = SOME('INDIE','POP');

/*
    Para intercambiar los valores INDIE y POP sin usar ninguna estructura
    intermedia ni alterar la tabla, lo que hacemos es diferir la restricción 
    de integridad que comprueba que la columna genero tenga un valor válido,
    después hacer el intercambio de valores, y finalmente poner en 
    modo inmediato la restricción. El valor intermedio es 'x', que no pertenece
    a ninguno de los valores válidos en género.
    
    El proceso de intercambio es el siguiente:
        POP   --> x
        INDIE --> POP
        x     --> INDIE
*/

SET CONSTRAINTS album_genero_ok DEFERRED;

UPDATE ALBUM SET genero = 'x'
WHERE genero = 'POP';

UPDATE ALBUM SET genero = 'POP'
WHERE genero = 'INDIE';

UPDATE ALBUM SET genero = 'INDIE'
WHERE genero = 'x';

SET CONSTRAINTS album_genero_ok IMMEDIATE;

SELECT id_album, titulo, genero
FROM ALBUM
WHERE genero = SOME('INDIE','POP');

ROLLBACK;

SELECT id_album, titulo, genero
FROM ALBUM
WHERE genero = SOME('INDIE','POP');

/*
    Tras usar ROLLBACK se ha vuelto al estado original ya que todas las 
    sentencias utilizadas en el proceso son LMD y por tanto no realizan 
    COMMITs implícitos. Por eso ROLLBACK ha provocado que volviesemos
    al estado original ya que el intercambio no se ha confirmado manualmente.
    
    Si hubiesemos usado setencias ALTER TABLE (LDD) para desactivar y activar la 
    RI del género del album, si se habrían producido COMMITs implícitos que
    habrían impedido que ROLLBACK devolviese los datos a su estado original.
    Para volver al inicio habriamos tenido que volver a realizar el intercambio.
    
    Véase el siguiente ejemplo con ALTER TABLE.
*/
/*
    SELECT id_album, titulo, genero
    FROM ALBUM
    WHERE genero = SOME('INDIE','POP');
    
    ALTER TABLE ALBUM
        DISABLE CONSTRAINT album_genero_ok;

    UPDATE ALBUM SET genero = 'x'
    WHERE genero = 'POP';

    UPDATE ALBUM SET genero = 'POP'
    WHERE genero = 'INDIE';

    UPDATE ALBUM SET genero = 'INDIE'
    WHERE genero = 'x';

    ALTER TABLE ALBUM
        ENABLE CONSTRAINT album_genero_ok;
    
    SELECT id_album, titulo, genero
    FROM ALBUM
    WHERE genero = SOME('INDIE','POP');
    
    ROLLBACK;
    
    SELECT id_album, titulo, genero
    FROM ALBUM
    WHERE genero = SOME('INDIE','POP');
    
    -- No funciona ROLLBACK por el COMMIT implicito de ALTER TABLE.
    -- Es necesario repetir el intercambio para revertir los cambios.
    
    ALTER TABLE ALBUM
        DISABLE CONSTRAINT album_genero_ok;

    UPDATE ALBUM SET genero = 'x'
    WHERE genero = 'POP';

    UPDATE ALBUM SET genero = 'POP'
    WHERE genero = 'INDIE';

    UPDATE ALBUM SET genero = 'INDIE'
    WHERE genero = 'x';

    ALTER TABLE ALBUM
        ENABLE CONSTRAINT album_genero_ok;
    
    SELECT id_album, titulo, genero
    FROM ALBUM
    WHERE genero = SOME('INDIE','POP');
*/

--------------------------------------------------------------------------------------
-- EJERCICIO 6. Borrar algunas filas de una tabla.

(SELECT id_usuario, cuota, invitador, ultimo_acceso
FROM USUARIO
WHERE tipo = 'GRATUITO'
    AND ultimo_acceso < TO_DATE('19/11/2019','dd/mm/yyyy')
    AND id_usuario NOT IN (SELECT usuario
                            FROM LISTA))
MINUS
(SELECT id_usuario, cuota, invitador, ultimo_acceso
FROM USUARIO
WHERE id_usuario IN (SELECT invitador FROM USUARIO)); 

DELETE FROM USUARIO
WHERE id_usuario IN
                ((SELECT id_usuario
                FROM USUARIO
                WHERE tipo = 'GRATUITO'
                    AND ultimo_acceso < TO_DATE('19/11/2019','dd/mm/yyyy')
                    AND id_usuario NOT IN (SELECT usuario
                                            FROM LISTA))
                MINUS
                (SELECT id_usuario
                FROM USUARIO
                WHERE id_usuario IN (SELECT invitador FROM USUARIO)));

COMMIT;

--------------------------------------------------------------------------------------
-- EJERCICIO 7. Borra algunas filas de varias tablas.

/* 
    Para eliminar toda la información relacionada con una banda hay que eliminar:
    - Las entradas en LISTA_CANCION que referencian canciones de albumes de la banda.
    - Las entradas en CANCION de canciones de albumes de la banda.
    - Los entradas en ALBUM de los albumes de la banda.
    - Las entradas en MUSICO_INSTRUMENTO para todos los musicos de la banda.
    - Las entradas en MUSICO para todos los MUSICOS de la banda
    - La banda de la tabla BANDA.
    
    Para eliminar las últimas dos cosas se debe desactivar una de las reglas de 
    integridad que provocan un ciclo referencial entre las tablas MUSICO y BANDA.
*/

DELETE FROM LISTA_CANCION
WHERE album IN (SELECT id_album
                FROM ALBUM
                WHERE banda = 'B001');
                
DELETE FROM CANCION
WHERE album IN (SELECT id_album
                FROM ALBUM
                WHERE banda = 'B001');

DELETE FROM ALBUM
WHERE banda = 'B001';

DELETE FROM MUSICO_INSTRUMENTO
WHERE musico IN (SELECT id_musico
                    FROM MUSICO
                    WHERE banda = 'B001');

/*
    Se desactiva la RI que provoca que toda banda deba referenciar
    músico lider de la misma. De esta forma, se pueden eliminar los músicos
    y a continuación la banda.
*/
SET CONSTRAINTS banda_fk_musico DEFERRED;    

DELETE FROM MUSICO
WHERE banda = 'B001';

DELETE FROM BANDA
WHERE id_artista = 'B001';

SET CONSTRAINTS banda_fk_musico IMMEDIATE;

COMMIT;

--------------------------------------------------------------------------------------
-- EJERCICIO 8. Eliminar algunas columnas.

/*
    Sentencias para eliminar una a una las columnas pais_origen y bio_breve
    de la tabla SOLISTA.
*/
/*
    ALTER TABLE SOLISTA DROP COLUMN pais_origen;
    ALTER TABLE SOLISTA DROP COLUMN bio_breve;
*/

-- Sentencia para eliminar ambas columnas a la vez.
ALTER TABLE SOLISTA DROP (pais_origen, bio_breve);

--------------------------------------------------------------------------------------
-- EJERCICIO 9. Crear y manipular una vista.

DROP VIEW DATOS_USUARIO CASCADE CONSTRAINTS;

CREATE VIEW DATOS_USUARIO
    AS SELECT U.nombre usuario, U.tipo, U.cuota, COUNT(DISTINCT num_lista) listas, COUNT(lista) canciones, ROUND(AVG(SYSDATE - U.ultimo_acceso)) desconexion
        FROM USUARIO U
            LEFT JOIN LISTA L ON U.id_usuario = L.usuario
            LEFT JOIN LISTA_CANCION T ON U.id_usuario = T.usuario AND L.num_lista = T.lista
        WHERE U.tipo <> 'GRATUITO'
        GROUP BY U.nombre, U.tipo, U.cuota;

SELECT *
FROM DATOS_USUARIO
ORDER BY usuario;

CREATE OR REPLACE VIEW DATOS_USUARIO
    AS SELECT U.nombre usuario, U.cuota*1.21 cuota, COUNT(DISTINCT num_lista) listas, COUNT(lista) canciones, ROUND(AVG(SYSDATE - U.ultimo_acceso)) desconexion
        FROM USUARIO U
            LEFT JOIN LISTA L ON U.id_usuario = L.usuario
            LEFT JOIN LISTA_CANCION T ON U.id_usuario = T.usuario AND L.num_lista = T.lista
        WHERE U.tipo <> 'GRATUITO'
        GROUP BY U.nombre, U.tipo, U.cuota;

SELECT *
FROM DATOS_USUARIO
ORDER BY usuario;

INSERT INTO USUARIO (id_usuario, nombre, email, telefono, tipo, cuota, invitador, ultimo_acceso)
VALUES ('U999', 'PIPPO', 'pippo@gmail.com', NULL, 'PREMIUM DOS', 14, NULL, SYSDATE);

SELECT *
FROM DATOS_USUARIO
ORDER BY usuario;

/*
    Se puede ver que aparece el nuevo usuario, con el cambio del 21% en la cuota.
    Esto se debe a que la vista no almacena datos, se obtienen a partir de su definición 
    y tablas base en el momento de realizar una consulta sobre la misma. Cualquier 
    usuario nuevo insertado que cumpla la definición de la vista podrá ser obtenido 
    consultándola.
*/

--------------------------------------------------------------------------------------
-- EJERCICIO 10. Crear y cargar una tabla, y modificar (alterar) su estructura.

DROP TABLE HITS CASCADE CONSTRAINTS;

/*
    Creamos la table mediante un SELECT seleccionando los campos
    pedidos de las tablas CANCION y ALBUM. Se necesia una UNION
    porque el campo artista debe contener el solista o la banda,
    y estos valores se almacenan en columnas diferentes y son
    exlcusivos el uno con el otro (si uno es NULL el otro no y viceversa).
*/
CREATE TABLE HITS (cancion, album, artista, cuantas_listas)
    AS (SELECT C.titulo, A.titulo, A.banda, C.cuantas_listas 
    FROM CANCION C, ALBUM A
    WHERE C.cuantas_listas > 1
        AND C.album = A.id_album
        AND A.banda IS NOT NULL)
    UNION
    (SELECT C.titulo, A.titulo, A.solista, C.cuantas_listas
    FROM CANCION C, ALBUM A
    WHERE C.cuantas_listas > 1
        AND C.album = A.id_album
        AND A.solista IS NOT NULL);
    
SELECT *
FROM HITS
ORDER BY cuantas_listas DESC;

ALTER TABLE HITS ADD( cuando NUMBER(4) DEFAULT 1972 NOT NULL );

/*
    Dado que HITS no almacena la clave primaria de ALBUM, no se puede identificar
    unequivocamente el album que corresponde a la cancion de una entrada determinada.
    Debemos confiar que no habrá ningun artista tendrá dos albumes con el mismo nombre.
*/
UPDATE HITS SET cuando = (SELECT anno
                            FROM ALBUM
                            WHERE titulo = album
                                AND (artista = solista OR artista = banda));

/* 
    Como seguridad extra se puede agregar la comprobación de que el id_album
    del album del que se va a coger el año, debe aparecer entre los albumes 
    de las canciones que se llaman como "título".
    
    El único peligro restante es que un artista tenga dos o más albumes de mismo
    nombre y que todos ellos contengan una canción con el mismo nombre.
*/
UPDATE HITS SET cuando = (SELECT anno
                            FROM ALBUM
                            WHERE titulo = album
                                AND (artista = solista OR artista = banda)
                                AND id_album IN (SELECT album
                                                    FROM CANCION
                                                    WHERE cancion = titulo));

SELECT *
FROM HITS
ORDER BY cuantas_listas DESC;

COMMIT;

DROP TABLE HITS CASCADE CONSTRAINTS;

--------------------------------------------------------------------------------------
-- EJERCICIO 11. Restricciones de integridad.

/*
DROP ASSERTION RI1;
DROP ASSERTION RI2;
DROP ASSERTION RI3;
*/
/* 
    Buscamos los solistas tales que su id no aparezca entre los solistas
    de todos los albumes.
*/
CREATE ASSERTION RI1
    CHECK (NOT EXISTS (SELECT id_artista
                        FROM SOLISTA
                        WHERE id_artista NOT IN (SELECT solista
                                                    FROM ALBUM
                                                    WHERE solista IS NOT NULL));
SELECT id_artista
FROM SOLISTA
WHERE id_artista NOT IN (SELECT solista
                            FROM ALBUM
                            WHERE solista IS NOT NULL);

/*
    Buscamos los albumes tales que se no encuentren mas de 6 veces
    entre los albumes de las canciones.

*/
CREATE ASSERTION RI2
    CHECK (NOT EXISTS (SELECT id_album
                        FROM ALBUM
                        WHERE id_album NOT IN (SELECT album
                                                FROM CANCION
                                                GROUP BY album
                                                HAVING COUNT(*) >= 7)));
SELECT id_album
FROM ALBUM
WHERE id_album NOT IN (SELECT album
                        FROM CANCION
                        GROUP BY album
                        HAVING COUNT(*) >= 7);
                        
/*
    Buscamos las bandas tales que su lider no aparezca entre
    la lista de músicos de dicha banda.
*/
CREATE ASSERTION RI3
    CHECK (NOT EXISTS (SELECT id_artista
                        FROM BANDA
                        WHERE lider NOT IN (SELECT id_musico
                                                    FROM MUSICO
                                                    WHERE banda = id_artista)));
SELECT id_artista
FROM BANDA
WHERE lider NOT IN (SELECT id_musico
                            FROM MUSICO
                            WHERE banda = id_artista);

/* 
    Para probar los selects vamos a hacer varias inserciones.
*/

-- Insertar un nuevo solista provoca que se incumpla R1.
INSERT INTO SOLISTA (id_artista, nombre)
  VALUES ('S999', 'PRUEBA');
SELECT id_artista
FROM SOLISTA
WHERE id_artista NOT IN (SELECT solista
                            FROM ALBUM
                            WHERE solista IS NOT NULL);
                            
                            
-- Insertar un album para el solista anterior provoca que ahora se cumpla RI1
-- Ahora no se cumple RI2 ya que el album tiene menos de 7 canciones.
INSERT INTO ALBUM (id_album, titulo, anno, genero, solista, banda)
VALUES ('A999', 'PRUEBA', 1972, 'ROCK', 'S999', NULL);
SELECT id_artista
FROM SOLISTA
WHERE id_artista NOT IN (SELECT solista
                            FROM ALBUM
                            WHERE solista IS NOT NULL);
SELECT id_album
FROM ALBUM
WHERE id_album NOT IN (SELECT album
                        FROM CANCION
                        GROUP BY album
                        HAVING COUNT(*) >= 7);
                        
-- Insertar 7 canciones hace que ahora se cumpla RI2.
INSERT INTO CANCION (album, posicion, titulo, duracion, cuantas_listas)
VALUES ('A999', 1, 'PRUEBA1', 3, 0); 
INSERT INTO CANCION (album, posicion, titulo, duracion, cuantas_listas)
VALUES ('A999', 2, 'PRUEBA2', 3, 0); 
INSERT INTO CANCION (album, posicion, titulo, duracion, cuantas_listas)
VALUES ('A999', 3, 'PRUEBA3', 3, 0); 
INSERT INTO CANCION (album, posicion, titulo, duracion, cuantas_listas)
VALUES ('A999', 4, 'PRUEBA4', 3, 0); 
INSERT INTO CANCION (album, posicion, titulo, duracion, cuantas_listas)
VALUES ('A999', 5, 'PRUEBA5', 3, 0); 
INSERT INTO CANCION (album, posicion, titulo, duracion, cuantas_listas)
VALUES ('A999', 6, 'PRUEBA6', 3, 0); 
SELECT id_album
FROM ALBUM
WHERE id_album NOT IN (SELECT album
                        FROM CANCION
                        GROUP BY album
                        HAVING COUNT(*) >= 7);
INSERT INTO CANCION (album, posicion, titulo, duracion, cuantas_listas)
VALUES ('A999', 7, 'PRUEBA7', 3, 0);
SELECT id_album
FROM ALBUM
WHERE id_album NOT IN (SELECT album
                        FROM CANCION
                        GROUP BY album
                        HAVING COUNT(*) >= 7);
                        
-- Insertar una banda cuyo lider es un músico de otra banda incumple RI3.
INSERT INTO BANDA ( id_artista, nombre, pais_origen, a_fundacion, lider)
VALUES ('B999', 'PRUEBA', 'Estados Unidos', 2000, 'M004');
SELECT id_artista
FROM BANDA
WHERE lider NOT IN (SELECT id_musico
                            FROM MUSICO
                            WHERE banda = id_artista);