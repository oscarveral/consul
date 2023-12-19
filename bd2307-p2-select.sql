/*
Asignatura: Bases de Datos (BBDD)
Curso: 2022-2023
Convocatoria: Mayo

Practica: P2. Consultas en SQL

Equipo de practicas: bd2307
 Integrante 1: Mattia Lucarini
 Integrante 2: Óscar Vera López
*/

-- EJERCICIOS:

/*  
    Ejercicio 1:
    Socios que actualmente tienen prestadas (aún no devueltas) películas dirigidas por un
    director no estadounidense. Columnas: (nombre, direccion).
*/

-- Mejor alternativa por legibilidad y eficiencia.
SELECT nombre, direccion
FROM SOCIO
WHERE idsocio IN (SELECT socio
                    FROM PRESTAMO
                    WHERE finalizado = 'NO'
                        AND PELICULA IN (SELECT idpel
                                            FROM PELICULA
                                            WHERE director IN (
                                                SELECT iddir
                                                FROM DIRECTOR
                                                WHERE nacionalidad <> 'EEUU')));
-- Alternativa más ofuscada.
SELECT DISTINCT S.nombre, S.direccion
FROM SOCIO S, PRESTAMO T, PELICULA P, DIRECTOR D
WHERE T.finalizado = 'NO'
    AND D.nacionalidad <> 'EEUU'
    AND S.idsocio = T.socio
    AND T.pelicula = P.idpel
    AND P.director = D.iddir;
    
/*  
    Ejercicio 2:
    Lista de todos los socios, con indicación de las copias de las películas de nacionalidad
    argentina que han tomado prestadas. Para aquellos socios que no han tomado
    prestadas nunca películas argentinas, rellenar la columna titulo con tres guiones: '---' y
    copia con un 0. Ordenado por idsocio, titulo y copia. Columnas: (idsocio, nombre,
    titulo, copia).
*/

-- Mejor versión sin online view
SELECT S.idsocio ids, S.nombre, NVL(P.titulo, '---') titulo, NVL(T.copia,0) copia
FROM SOCIO S LEFT JOIN 
        (PRESTAMO T JOIN PELICULA P
            ON P.nacionalidad='Argentina'
            AND T.pelicula = P.idpel)
    ON S.idsocio = T.socio
ORDER BY S.idsocio, P.titulo, T.copia;
    
-- Versión algo más ofuscada.
SELECT S.idsocio ids, S.nombre, NVL(titulo, '---') titulo, NVL(T.copia,0) copia
FROM SOCIO S LEFT JOIN 
        (PRESTAMO T JOIN 
            (SELECT idpel,titulo
             FROM PELICULA 
             WHERE nacionalidad = 'Argentina') 
        ON T.pelicula = idpel)
    ON S.idsocio = T.socio
ORDER BY S.idsocio, titulo, T.copia;

/*  
    Ejercicio 3:
    Intérpretes que han participado en más de 2 películas del director 'WOODY ALLEN',
    ordenados alfabéticamente. Columna: (idinter, nombre).
*/

-- Mejor version por legibilidad y eficiencia.
SELECT idinter idi, nombre
FROM INTERPRETE
WHERE idinter IN (SELECT interprete
                    FROM REPARTO
                    WHERE pelicula IN (SELECT idpel
                                        FROM PELICULA
                                        WHERE director = (SELECT iddir
                                                            FROM DIRECTOR
                                                            WHERE nombre = 'WOODY ALLEN'))
                    GROUP BY interprete
                    HAVING COUNT(*)>2)
ORDER BY nombre;
                    
-- Versión menos eficiente y legible.        
SELECT idinter idi, nombre
FROM INTERPRETE
WHERE (idinter) IN (SELECT interprete
                    	FROM REPARTO R, PELICULA P, DIRECTOR D
                    	WHERE R.pelicula = P.idpel
                        	AND P.director = D.iddir
                        	AND D.nombre = 'WOODY ALLEN'
                        GROUP BY interprete
                        HAVING COUNT(*)>2)
ORDER BY nombre;

/*  
    Ejercicio 4:
    Número total de copias de aquellas películas en las que ha actuado algún intérprete
    australiano. Columnas: (idpel, titulo, total_copias).
*/

-- Mejor alternativa por legibilidad y eficiencia.
SELECT P.idpel idp, P.titulo, total_copias
FROM PELICULA P JOIN (SELECT C.pelicula, COUNT(*) total_copias
                    FROM COPIA C
                    WHERE C.pelicula IN (SELECT R.pelicula
                                        FROM REPARTO R 
                                        WHERE R.interprete IN (SELECT idinter
                                                                FROM INTERPRETE
                                                                WHERE nacionalidad = 'Australia'))
                    GROUP BY C.pelicula)
    ON P.idpel = pelicula;

-- Alternativa más ofuscada.
SELECT P.idpel idp, P.titulo, COUNT(*) total_copias
FROM INTERPRETE I, REPARTO R, PELICULA P, COPIA C 
WHERE (I.nacionalidad = 'Australia'
    AND R.interprete = I.idinter
    AND P.idpel = R.pelicula
    AND C.pelicula = P.idpel)
GROUP BY P.idpel, P.titulo;


/*  
    Ejercicio 5:
    Lista de nombres y nacionalidades respectivas de personas no estadounidenses, que
    han dirigido, participado, o ambas cosas, en películas de nacionalidad estadounidense.
    Ordenado por nombre. Columnas: (nombre, nacionalidad). 
*/

(SELECT I.nombre, I.nacionalidad
FROM INTERPRETE I
WHERE I.nacionalidad <> 'EEUU'
    AND I.idinter IN (SELECT interprete
                    FROM REPARTO
                    WHERE pelicula IN (SELECT P.idpel
                                        FROM PELICULA P
                                        WHERE P.nacionalidad = 'EEUU')))
UNION
(SELECT D.nombre, D.nacionalidad
FROM DIRECTOR D
WHERE D.nacionalidad <> 'EEUU'
    AND D.iddir IN (SELECT P.director
                    FROM PELICULA P
                    WHERE P.nacionalidad = 'EEUU'))
ORDER BY nombre;

/*  
    Ejercicio 6:
    Película que más veces ha sido prestada a un mismo socio, indicando a quién ha sido.
    Columnas: (titulo, nombre).
*/

-- Mejor versión por legibilidad y eficiencia.
SELECT P.titulo, nombre
FROM PELICULA P, SOCIO
WHERE (P.idpel, idsocio) IN (SELECT pelicula, socio
                            FROM PRESTAMO
                            GROUP BY pelicula, socio
                            HAVING COUNT(*) = (SELECT MAX(COUNT(*))
                                                FROM PRESTAMO
                                                GROUP BY pelicula, socio)); 

-- Versión poco legible.
SELECT P.titulo, S.nombre
FROM PELICULA P, SOCIO S, PRESTAMO T
WHERE T.socio = S.idsocio
	AND P.idpel = T.pelicula
GROUP BY P.titulo, S.nombre
HAVING COUNT(*) = (SELECT MAX(numero)
            	FROM (SELECT COUNT(P.idpel) numero
            	FROM PELICULA P, SOCIO S, PRESTAMO T
            	WHERE T.socio = S.idsocio
                	AND P.idpel = T.pelicula
            	GROUP BY P.titulo, S.nombre));
/*  
    Ejercicio 7:
    Para cada intérprete mostrar el número de ocasiones en las que ha participado en
    películas como protagonista y como secundario (nombre, veces_prota, veces_secun),
    ordenado por nombre del intérprete. Si un intérprete no ha participado nunca como
    protagonista y/o como secundario, debe aparecer un 0 en la columna correspondiente.
*/

SELECT nombre,NVL(nprota,'0') veces_prota ,NVL(nsecun,'0') veces_secun
FROM INTERPRETE LEFT JOIN 
                (
                    (
                    SELECT R1.interprete i1, COUNT(*) nprota
                            FROM REPARTO R1
                            WHERE tipo_papel = 'PROTAGONISTA'
                            GROUP BY R1.interprete
                    )
                    FULL JOIN
                    (
                    SELECT R2.interprete i2, COUNT(*) nsecun
                        FROM REPARTO R2
                        WHERE tipo_papel = 'SECUNDARIO'
                        GROUP BY R2.interprete
                    )
                    ON i1 = i2
                )
                ON idinter = SOME(i1,i2)
ORDER BY nombre;

/*  
    Ejercicio 8:
    Socios que han tomado prestadas todas las películas de la actriz 'CECILIA ROTH'.
    Columnas: (idsocio, nombre).
*/
SELECT S.idsocio ids, S.nombre
FROM SOCIO S
WHERE NOT EXISTS(
     (SELECT R.pelicula
        FROM REPARTO R
        WHERE R.interprete IN (SELECT I.idinter
                                FROM INTERPRETE I
                                WHERE I.nombre = 'CECILIA ROTH'))
    MINUS
    (SELECT T.pelicula
        FROM PRESTAMO T
        WHERE T.socio = S.idsocio));
        
/*
    Ejercicio 9:
    Socios responsables de aquellos socios que no han devuelto alguna de las películas que
    tienen en préstamo. Para aquellos socios que no tengan responsable, mostrar la cadena
    '*sin responsable*' en la columna nombre_respo. Ordenado por nombre_socio.
    Columnas: (nombre_respo, telef_respo, nombre_socio).
*/

SELECT NVL(S1.nombre, '*sin responsable*') nombre_respo, S1.telefono telefono_res, S2.nombre nombre_socio
FROM SOCIO S1 RIGHT JOIN SOCIO S2 ON S1.idsocio = S2.responsable
WHERE S2.idsocio IN (SELECT T.socio
                            FROM PRESTAMO T
                            WHERE finalizado = 'NO')
ORDER BY nombre_socio;

/*
    Ejercicio 10:
    Nombre del socio que ha tomado prestadas el mayor número de películas diferentes y
    cuántas han sido. Columnas: (nombre, cuantas_peliculas).
*/

-- Mejor version por legibilidad y elegancia.
SELECT nombre, cuantas_peliculas
FROM SOCIO,(SELECT socio, COUNT(DISTINCT pelicula) cuantas_peliculas
            FROM PRESTAMO
            GROUP BY socio)
WHERE idsocio = socio
GROUP BY nombre, cuantas_peliculas
HAVING cuantas_peliculas = (SELECT MAX(COUNT(DISTINCT pelicula))
                                    FROM PRESTAMO
                                    GROUP BY socio);
                                    
-- Version menos correcta. Online views anidadas.
SELECT nombre, cuantas_peliculas
FROM SOCIO,(SELECT socio, COUNT(*) cuantas_peliculas
                FROM (SELECT socio
                        FROM PRESTAMO
                        GROUP BY socio, pelicula)
                GROUP BY socio
                HAVING COUNT(*) = (SELECT MAX(COUNT(DISTINCT pelicula))
                                    FROM PRESTAMO
                                    GROUP BY socio))
WHERE idsocio = socio;

-- Version menos correcta. Comprobación del máximo en la consulta anidada en vez en la consulta principal.
SELECT nombre, cuantas_peliculas
FROM SOCIO,(SELECT socio, COUNT(DISTINCT pelicula) cuantas_peliculas
                FROM PRESTAMO
                GROUP BY socio
                HAVING COUNT(DISTINCT pelicula) = (SELECT MAX(COUNT(DISTINCT pelicula))
                                                    FROM PRESTAMO
                                                    GROUP BY socio))
WHERE idsocio = socio;
