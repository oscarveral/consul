-- DROPS PARA ASEGURAR QUE LAS TABLAS NO EXISTEN YA.
--DROP TABLE USUARIO CASCADE CONSTRAINTS;
--DROP TABLE LISTA CASCADE CONSTRAINTS;
--DROP TABLE SOLISTA CASCADE CONSTRAINTS;
--DROP TABLE BANDA CASCADE CONSTRAINTS;
--DROP TABLE MUSICO CASCADE CONSTRAINTS;
--DROP TABLE INSTRUMENTO_MUSICO CASCADE CONSTRAINTS;
--DROP TABLE ALBUM CASCADE CONSTRAINTS;
--DROP TABLE CANCION CASCADE CONSTRAINTS;
--DROP TABLE ANHADIDA_A CASCADE CONSTRAINTS;


CREATE TABLE USUARIO (
    id_usuario  CHAR(4) NOT NULL,
    ultimo_acceso   DATE    NOT NULL,
    nombre  VARCHAR(30)    NOT NULL,
    email   VARCHAR(30)    NULL,
    telefono VARCHAR(30)   NULL,
    tipo    VARCHAR(20) DEFAULT 'GRATUITO' NOT NULL,
    cuota   NUMBER(4,2) DEFAULT 0 NOT NULL,
    invitador CHAR(4) NULL,
    
    CONSTRAINT user_pk PRIMARY KEY (id_usuario),
    CONSTRAINT user_ak1 UNIQUE (email),
    CONSTRAINT user_ak2 UNIQUE (telefono),
    CONSTRAINT user_fk_user FOREIGN KEY (invitador) REFERENCES USUARIO(id_usuario),
        -- ON DELETE: SET NULL ON UPDATE: CASCADE

    CONSTRAINT user_tipo_ok CHECK (tipo IN ('GRATUITO', 'PREMIUM INDIVIDUAL', 'PREMIUM DOS', 'PREMIUM FAMILIAR')),
    CONSTRAINT user_email_ok CHECK ((email IS NOT NULL AND telefono IS NULL) OR (email IS NULL AND telefono IS NOT NULL)),
    CONSTRAINT user_invitador_ok CHECK (id_usuario <> invitador)
);

CREATE TABLE LISTA (
    num_lista NUMBER(3) NOT NULL,
    nombre    VARCHAR(30)  NOT NULL,
    descripcion VARCHAR(30)   NULL,
    id_usuario CHAR(4) NOT NULL,
    
    CONSTRAINT lista_pk PRIMARY KEY (id_usuario, num_lista),
    CONSTRAINT lista_fk_user FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario)
        -- ON DELETE: CASCADE ON UPDATE: CASCADE
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
    
    CONSTRAINT musico_pk PRIMARY KEY (id_musico)
);

CREATE TABLE BANDA (
    id_artista CHAR(4) NOT NULL,
    nombre VARCHAR(30) NOT NULL,
    pais_origen VARCHAR(30) NULL,
    anho_fundacion NUMBER(4) NOT NULL,
    lider   CHAR(4) NOT NULL,
    
    CONSTRAINT banda_pk PRIMARY KEY (id_artista),
    CONSTRAINT banda_ak1 UNIQUE (nombre),
    CONSTRAINT banda_ak2 UNIQUE (lider),
    CONSTRAINT bada_fk_musico FOREIGN KEY (lider) REFERENCES MUSICO(id_musico)
        -- ON DELETE: NO ACTION ON UPDATE: CASCADE
);

ALTER TABLE MUSICO ADD (
    banda   CHAR(4) NOT NULL,
    CONSTRAINT musico_fk_banda FOREIGN KEY (banda) REFERENCES BANDA(id_artista)
);

CREATE TABLE INSTRUMENTO_MUSICO (
    id_musico CHAR(4) NOT NULL,
    instrumento VARCHAR(30) NOT NULL,
    
    CONSTRAINT instrumento_musico_pk PRIMARY KEY (id_musico, instrumento),
    CONSTRAINT instrumento_musico_fk_musico FOREIGN KEY (id_musico) REFERENCES MUSICO(id_musico),
        -- ON DELETE: CASCADE ON UPDATE: CASCADE

    CONSTRAINT instrumento_value_ok CHECK (instrumento IN ('VOZ', 'GUITARRA', 'BAJO', 'PIANO', 'BATERIA', 'OTRO'))
);

CREATE TABLE ALBUM (
    id_album CHAR(4) NOT NULL,
    titulo VARCHAR(30) NOT NULL,
    anho NUMBER(4)  NOT NULL,
    genero VARCHAR(30) NOT NULL,
    id_artista_solista CHAR(4) NULL,
    id_artista_banda CHAR(4) NULL,
    
    CONSTRAINT album_pk PRIMARY KEY (id_album),
    CONSTRAINT album_fk_solista FOREIGN KEY (id_artista_solista) REFERENCES SOLISTA(id_artista),
        -- ON DELETE: CASCADE ON UPDATE: CASCADE

    CONSTRAINT album_fk_banda FOREIGN KEY (id_artista_banda) REFERENCES BANDA(id_artista),
        -- ON DELETA: CASCADE ON UPDATE: CASCADE

    CONSTRAINT album_creator_ok CHECK ((id_artista_solista IS NOT NULL AND id_artista_banda IS NULL) OR (id_artista_solista IS NULL AND id_artista_banda IS NOT NULL)),
    CONSTRAINT album_genero_ok CHECK (genero IN ('POP', 'ROCK', 'INDIE', 'HIP HOP', 'K-POP', 'CLASICA', 'LATINO', 'FLAMENCO', 'OTRO'))
);

CREATE TABLE CANCION (
    posicion   NUMBER(3) NOT NULL,
    titulo VARCHAR(30) NOT NULL,
    duracion NUMBER(6) NOT NULL,
    cuantas_listas NUMBER(6) NOT NULL,
    id_album CHAR(4) NOT NULL,

    CONSTRAINT cancion_pk PRIMARY KEY (id_album, posicion),
    CONSTRAINT cancion_fk_album FOREIGN KEY (id_album) REFERENCES ALBUM(id_album)
        -- ON DELETE: CASCADE ON UPDATE: CASCADE

);

CREATE TABLE ANHADIDA_A (
    id_album CHAR(4) NOT NULL,
    posicion NUMBER(3) NOT NULL,
    id_usuario CHAR(4) NOT NULL,
    num_lista NUMBER(3) NOT NULL,
    fecha DATE NOT NULL,

    CONSTRAINT anhadida_a_pk PRIMARY KEY (id_album, posicion, id_usuario, num_lista),
    CONSTRAINT anhadida_a_fk_cancion FOREIGN KEY (id_album, posicion) REFERENCES CANCION(id_album, posicion),
        -- ON DELETE: CASCADE ON UPDATE: CASCADE
    CONSTRAINT anhadida_a_fk_lista FOREIGN KEY (id_usuario, num_lista) REFERENCES LISTA(id_usuario, num_lista)
        -- ON DELETE: CASCADE ON UPDATE: CASCADE
);


-- Sentencia para calcular el valor de CANCION.cuantas_listas
--UPDATE CANCION SET cuantas_listas = (SELECT COUNT(*) FROM ANHADIDA_A WHERE id_album = CANCION.id_album AND posicion = CANCION.posicion);
    