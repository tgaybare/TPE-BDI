
DROP TABLE IF EXISTS clientes_banco CASCADE;
DROP TABLE IF EXISTS prestamos_banco CASCADE;
DROP TABLE IF EXISTS pagos_cuotas CASCADE;
DROP TABLE IF EXISTS BACKUP CASCADE;



CREATE TABLE clientes_banco (
    Codigo SERIAL,
    DNI INT NOT NULL CHECK ( DNI > 0 ),
    Telefono TEXT,
    Nombre TEXT NOT NULL,
    Direccion TEXT,
    PRIMARY KEY (Codigo),
    UNIQUE (DNI, Telefono, Nombre)
);

CREATE TABLE prestamos_banco(
    Codigo SERIAL,
    Fecha DATE,
    Codigo_Cliente INT NOT NULL,
    Importe INT NOT NULL CHECK ( Importe > 0 ),
    PRIMARY KEY (Codigo),
    FOREIGN KEY (Codigo_Cliente) REFERENCES clientes_banco(Codigo)
);

CREATE TABLE pagos_cuotas(
    Nro_Cuota INT NOT NULL,
    Codigo_Prestamo INT NOT NULL,
    Importe INT NOT NULL CHECK ( Importe > 0 ),
    Fecha DATE,
    PRIMARY KEY (Nro_Cuota, Codigo_Prestamo),
    FOREIGN KEY (Codigo_Prestamo) REFERENCES prestamos_banco(Codigo)
);


CREATE TABLE BACKUP(
    DNI INT NOT NULL CHECK ( DNI > 0 ),
    Nombre TEXT NOT NULL,
    Telefono TEXT,
    CantPrestamos INT NOT NULL CHECK ( CantPrestamos >= 0 ),
    MontoPrestamos INT NOT NULL CHECK ( MontoPrestamos >= 0 ),
    MontoPagos INT NOT NULL CHECK ( MontoPagos >= 0 ),
    PagosPendientes BOOLEAN,
    PRIMARY KEY (DNI),
    FOREIGN KEY (DNI, Nombre, Telefono) REFERENCES clientes_banco(DNI, Nombre, Telefono)
);

COPY clientes_banco(Codigo, DNI, Telefono, Nombre, Direccion)
FROM './clientes_banco.csv'
DELIMITER ','
CSV HEADER;