/*
Asignatura: Bases de Datos
Curso: 2022/23
Convocatoria: junio

Practica: P3. Definicion y Modificacion de Datos en SQL

Equipo de practicas: bd2307
 Integrante 1: Oscar Vera Lopez
 Integrante 2: Mattia Lucarini
*/

-- EJERCICIO 0. Sentencias CREATE definitivas

DROP TABLE USUARIO CASCADE CONSTRAINTS;
DROP TABLE LISTA CASCADE CONSTRAINTS;
DROP TABLE SOLISTA CASCADE CONSTRAINTS;
DROP TABLE BANDA CASCADE CONSTRAINTS;
DROP TABLE MUSICO CASCADE CONSTRAINTS;
DROP TABLE MUSICO_INSTRUMENTO CASCADE CONSTRAINTS;
DROP TABLE ALBUM CASCADE CONSTRAINTS;
DROP TABLE CANCION CASCADE CONSTRAINTS;
DROP TABLE LISTA_CANCION CASCADE CONSTRAINTS;

CREATE TABLE USUARIO (
    id_usuario  CHAR(4) NOT NULL,
    nombre  VARCHAR(30)    NOT NULL,
    email   VARCHAR(30)    NULL,
    telefono VARCHAR(30)   NULL,
    tipo    VARCHAR(20) DEFAULT 'GRATUITO' NOT NULL,
    cuota   NUMBER(4,2) DEFAULT 0 NOT NULL,
    invitador CHAR(4) NULL,
    ultimo_acceso   DATE    NOT NULL,

    CONSTRAINT user_pk PRIMARY KEY (id_usuario),
    CONSTRAINT user_ak1 UNIQUE (email),
    CONSTRAINT user_ak2 UNIQUE (telefono),
    CONSTRAINT user_fk_user FOREIGN KEY (invitador) REFERENCES USUARIO(id_usuario)
        INITIALLY IMMEDIATE DEFERRABLE,
        -- ON DELETE: SET NULL ON UPDATE: CASCADE

    CONSTRAINT user_tipo_ok CHECK (tipo IN ('GRATUITO', 'PREMIUM INDIVIDUAL', 'PREMIUM DOS', 'PREMIUM FAMILIAR')),
    CONSTRAINT user_email_ok CHECK ((email IS NOT NULL AND telefono IS NULL) OR (email IS NULL AND telefono IS NOT NULL)),
    CONSTRAINT user_invitador_ok CHECK (id_usuario <> invitador)
);

CREATE TABLE LISTA (
    usuario CHAR(4) NOT NULL,
    num_lista NUMBER(3) NOT NULL,
    nombre VARCHAR(30) NOT NULL,
    descripcion VARCHAR(30) NULL,
    
    CONSTRAINT lista_pk PRIMARY KEY (usuario, num_lista),
    CONSTRAINT lista_fk_user FOREIGN KEY (usuario) REFERENCES USUARIO(id_usuario)
        INITIALLY IMMEDIATE DEFERRABLE,
        -- ON DELETE: CASCADE ON UPDATE: CASCADE

    CONSTRAINT lista_num_lista_ok CHECK (num_lista > 0)
);

CREATE TABLE SOLISTA (
    id_artista CHAR(4) NOT NULL,
    nombre VARCHAR(30) NOT NULL,
    pais_origen VARCHAR(30) NULL,
    bio_breve VARCHAR(30) NULL,
    
    CONSTRAINT solista_pk PRIMARY KEY (id_artista),
    CONSTRAINT solista_ak UNIQUE (nombre)
);

CREATE TABLE MUSICO (
    id_musico CHAR(4) NOT NULL,
    nombre VARCHAR(30) NOT NULL,
    banda CHAR(4) NOT NULL,

    CONSTRAINT musico_pk PRIMARY KEY (id_musico)
);

CREATE TABLE BANDA (
    id_artista CHAR(4) NOT NULL,
    nombre VARCHAR(30) NOT NULL,
    pais_origen VARCHAR(30) NULL,
    a_fundacion NUMBER(4) NOT NULL,
    lider   CHAR(4) NOT NULL,
    
    CONSTRAINT banda_pk PRIMARY KEY (id_artista),
    CONSTRAINT banda_ak1 UNIQUE (nombre),
    CONSTRAINT banda_ak2 UNIQUE (lider),
    CONSTRAINT banda_fk_musico FOREIGN KEY (lider) REFERENCES MUSICO(id_musico)
        INITIALLY IMMEDIATE DEFERRABLE
        -- ON DELETE: NO ACTION ON UPDATE: CASCADE
);

ALTER TABLE MUSICO ADD (
    CONSTRAINT musico_fk_banda FOREIGN KEY (banda) REFERENCES BANDA(id_artista)
        -- ON DELETE: CASCADE ON UPDATE CASCADE
);

CREATE TABLE MUSICO_INSTRUMENTO (
    musico CHAR(4) NOT NULL,
    instrumento VARCHAR(30) NOT NULL,
    
    CONSTRAINT instrumento_musico_pk PRIMARY KEY (musico, instrumento),
    CONSTRAINT instrumento_musico_fk_musico FOREIGN KEY (musico) REFERENCES MUSICO(id_musico),
        -- ON DELETE: CASCADE ON UPDATE: CASCADE
        
    CONSTRAINT instrumento_value_ok CHECK (instrumento IN ('VOZ', 'GUITARRA', 'BAJO', 'PIANO', 'BATERIA', 'OTRO'))
);

CREATE TABLE ALBUM (
    id_album CHAR(4) NOT NULL,
    titulo VARCHAR(30) NOT NULL,
    anno NUMBER(4)  NOT NULL,
    genero VARCHAR(30) NOT NULL,
    solista CHAR(4) NULL,
    banda CHAR(4) NULL,
    
    CONSTRAINT album_pk PRIMARY KEY (id_album),
    CONSTRAINT album_fk_solista FOREIGN KEY (solista) REFERENCES SOLISTA(id_artista),
        -- ON DELETE: CASCADE ON UPDATE: CASCADE

    CONSTRAINT album_fk_banda FOREIGN KEY (banda) REFERENCES BANDA(id_artista),
        -- ON DELETA: CASCADE ON UPDATE: CASCADE

    CONSTRAINT album_creator_ok CHECK ((solista IS NOT NULL AND banda IS NULL) OR (solista IS NULL AND banda IS NOT NULL)),
    CONSTRAINT album_genero_ok CHECK (genero IN ('POP', 'ROCK', 'INDIE', 'HIP HOP', 'K-POP', 'CLASICA', 'LATINO', 'FLAMENCO', 'OTRO'))
        INITIALLY IMMEDIATE DEFERRABLE
);

CREATE TABLE CANCION (
    album CHAR(4) NOT NULL,
    posicion   NUMBER(3) NOT NULL,
    titulo VARCHAR(30) NOT NULL,
    duracion NUMBER(6) NOT NULL,
    cuantas_listas NUMBER(6) NOT NULL,

    CONSTRAINT cancion_pk PRIMARY KEY (album, posicion),
    CONSTRAINT cancion_fk_album FOREIGN KEY (album) REFERENCES ALBUM(id_album),
        -- ON DELETE: CASCADE ON UPDATE: CASCADE
        
    CONSTRAINT cancion_posicion_ok CHECK (posicion > 0),
    CONSTRAINT cancion_duracion_ok CHECK (duracion > 0)
);

CREATE TABLE LISTA_CANCION (
    usuario CHAR(4) NOT NULL,
    lista NUMBER(3) NOT NULL,
    album CHAR(4) NOT NULL,
    cancion NUMBER(3) NOT NULL,
    fecha DATE NOT NULL,

    CONSTRAINT lista_cancion_pk PRIMARY KEY (usuario, lista, album, cancion),
    CONSTRAINT lista_cancion_fk_cancion FOREIGN KEY (album, cancion) REFERENCES CANCION(album, posicion),
        -- ON DELETE: CASCADE ON UPDATE: CASCADE
        
    CONSTRAINT lista_cancion_fk_lista FOREIGN KEY (usuario, lista) REFERENCES LISTA(usuario, num_lista)
        INITIALLY IMMEDIATE DEFERRABLE
        -- ON DELETE: CASCADE ON UPDATE: CASCADE
);