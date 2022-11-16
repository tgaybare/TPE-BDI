
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
    FOREIGN KEY (Codigo_Cliente) REFERENCES clientes_banco(Codigo) ON DELETE CASCADE
);

CREATE TABLE pagos_cuotas(
    Nro_Cuota INT NOT NULL,
    Codigo_Prestamo INT NOT NULL,
    Importe INT NOT NULL CHECK ( Importe > 0 ),
    Fecha DATE,
    PRIMARY KEY (Nro_Cuota, Codigo_Prestamo),
    FOREIGN KEY (Codigo_Prestamo) REFERENCES prestamos_banco(Codigo) ON DELETE CASCADE
);


CREATE TABLE BACKUP(
    DNI INT NOT NULL CHECK ( DNI > 0 ),
    Nombre TEXT NOT NULL,
    Telefono TEXT,
    CantPrestamos INT NOT NULL CHECK ( CantPrestamos >= 0 ),
    MontoPrestamos INT NOT NULL CHECK ( MontoPrestamos >= 0 ),
    MontoPagos INT NOT NULL CHECK ( MontoPagos >= 0 ),
    PagosPendientes BOOLEAN,
    PRIMARY KEY (DNI)
);


DROP FUNCTION IF EXISTS CalcCantPrestamos;
DROP FUNCTION IF EXISTS CalcMontoPagos;
DROP FUNCTION IF EXISTS CalcMontoPrestamos;

CREATE FUNCTION CalcCantPrestamos(IN documento INT) RETURNS INT AS $$
DECLARE toRet INTEGER;
BEGIN
    SELECT count(prestamos_banco.Codigo) INTO toRet
    FROM clientes_banco JOIN prestamos_banco ON clientes_banco.Codigo = prestamos_banco.Codigo_Cliente
    WHERE documento = clientes_banco.DNI
    GROUP BY clientes_banco.DNI;
    RETURN toRet;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION CalcMontoPrestamos(IN documento INT) RETURNS INT AS $$
DECLARE toRet INTEGER;
BEGIN
    SELECT COALESCE(sum(prestamos_banco.Importe),0) INTO toRet
    FROM clientes_banco JOIN prestamos_banco ON clientes_banco.Codigo = prestamos_banco.Codigo_Cliente
    WHERE documento = clientes_banco.DNI
    GROUP BY clientes_banco.DNI;
    RETURN toRet;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION CalcMontoPagos(IN documento INT) RETURNS INT AS $$
DECLARE toRet INTEGER;
BEGIN
    SELECT sum(pagos_cuotas.Importe) INTO toRet
    FROM clientes_banco JOIN prestamos_banco ON clientes_banco.Codigo = prestamos_banco.Codigo_Cliente JOIN pagos_cuotas ON pagos_cuotas.Codigo_Prestamo = prestamos_banco.Codigo
    WHERE documento = clientes_banco.DNI
    GROUP BY clientes_banco.DNI;
    RETURN COALESCE(toRet,0);
END
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS RemoveClienteTrigger ON clientes_banco;
DROP FUNCTION IF EXISTS RemoveCliente();

CREATE FUNCTION RemoveCliente() RETURNS TRIGGER AS $$
DECLARE montoPrestamos INTEGER;
montoPagos INTEGER;
BEGIN
    montoPrestamos = CalcMontoPrestamos(OLD.DNI);
    montoPagos = CalcMontoPagos(OLD.DNI);
    INSERT INTO BACKUP
    VALUES (OLD.DNI, OLD.Nombre, OLD.Telefono, CalcCantPrestamos(OLD.DNI), montoPrestamos, montoPagos, montoPrestamos >= montoPagos);
    RETURN OLD;
end
$$ LANGUAGE plpgsql;

CREATE TRIGGER RemoveClienteTrigger BEFORE DELETE ON clientes_banco FOR ROW EXECUTE PROCEDURE RemoveCliente();



