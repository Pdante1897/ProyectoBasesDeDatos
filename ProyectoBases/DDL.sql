DROP DATABASE IF EXISTS proyecto;

CREATE DATABASE proyecto;
USE proyecto;

CREATE TABLE producto (
    id varchar(2) not null,
    nombre VARCHAR(30) NOT NULL,
    precio decimal(10,2) not null,
    PRIMARY KEY (id)
);

CREATE TABLE cliente (
    dpi bigint NOT NULL,
    nombre VARCHAR(30) NOT NULL,
    apellidos VARCHAR(30) NOT NULL,
    fecha_nac DATE NOT NULL,
    correo VARCHAR(30) NOT NULL,
    telefono INT NOT NULL,
    nit INT,
    PRIMARY KEY (dpi)
);

CREATE TABLE tipo (
    id     INT auto_increment NOT NULL,
    nombre VARCHAR(15) NOT NULL,
    PRIMARY KEY (id)
);


CREATE TABLE municipio (
    id INT auto_increment NOT NULL,
    nombre VARCHAR(30) NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE puesto (
    id INT auto_increment NOT NULL,
    nombre VARCHAR(30) NOT NULL,
	descripcion VARCHAR(100) NOT NULL,
    salario decimal (10,2) NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE direccion (
    id INT auto_increment NOT NULL ,
    direccion VARCHAR(100) NOT NULL,
    zona INT NOT NULL,
    cliente_dpi bigint NOT NULL,
    municipio_id INT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (cliente_dpi) REFERENCES cliente (dpi),
    FOREIGN KEY (municipio_id) REFERENCES municipio (id)
);

CREATE TABLE restaurante (
    id INT auto_increment NOT NULL,
    direccion VARCHAR(60) NOT NULL,
    zona INT NOT NULL,
    personal INT NOT NULL,
    parqueo boolean NOT NULL,
    municipio_id INT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (municipio_id) REFERENCES municipio (id)
);

CREATE TABLE empleado (
    id INT NOT NULL,
    nombres VARCHAR(30) NOT NULL,
    apellidos VARCHAR(30) NOT NULL,
    fecha_nac DATE NOT NULL,
    correo VARCHAR(30) NOT NULL,
    telefono INT NOT NULL,
    direccion VARCHAR(60) NOT NULL,
    dpi bigint NOT NULL,
    fecha_inicio DATE NOT NULL,
    restaurante_id INT NOT NULL,
    puesto_id INT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (puesto_id) REFERENCES puesto (id),
    FOREIGN KEY (restaurante_id) REFERENCES restaurante (id)
);


CREATE TABLE orden (
    id INT auto_increment NOT NULL,
    canal CHAR(1) NOT NULL,
    estado VARCHAR(13) NOT NULL,
    cliente_dpi bigint NOT NULL,
    direccion_id INT NOT NULL,
    empleado_id INT,
    fecha_inicio datetime not null,
    fecha_entrega datetime null,
    restaurante_id int null,
    PRIMARY KEY (id),
    FOREIGN KEY (cliente_dpi) REFERENCES cliente (dpi),
    FOREIGN KEY (direccion_id) REFERENCES direccion (id),
    FOREIGN KEY (empleado_id) REFERENCES empleado (id),
    FOREIGN KEY (restaurante_id) REFERENCES restaurante (id)

);

CREATE TABLE item (
    id INT auto_increment NOT NULL,
    tipo_producto CHAR(1) NOT NULL,
    producto_id varchar(2) NOT NULL,
    cantidad INT NOT NULL,
    orden_id INT NOT NULL,
    observacion varchar(100) null,
    PRIMARY KEY (id),
    FOREIGN KEY (orden_id) REFERENCES orden (id),
    FOREIGN KEY (producto_id) REFERENCES producto (id)

);

CREATE TABLE factura (
    id INT auto_increment NOT NULL,
    serie VARCHAR(25) NOT NULL,
    monto decimal(10,2) NOT NULL,
    fecha DATETIME NOT NULL,
    nit VARCHAR(20) NOT NULL,
    forma_pago CHAR(1) NOT NULL,
    orden_id INT NOT NULL,
    lugar int not null,
    PRIMARY KEY (id),
    FOREIGN KEY (orden_id) REFERENCES orden (id)
);




CREATE TABLE transaccion (
    id          INT auto_increment NOT NULL,
    fecha datetime not null,
    descripcion VARCHAR(100) NOT NULL,
    tipo_id     INT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (tipo_id) REFERENCES tipo (id)
);
