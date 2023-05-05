DELIMITER $$
CREATE PROCEDURE registrarRestaurante(
    IN p_id INT,
    IN p_direccion VARCHAR(60),
    IN p_municipio VARCHAR(30),
    IN p_zona INT,
    IN p_personal INT,
    IN p_parqueo BOOLEAN
)
BEGIN
    DECLARE municipio_id INT;
    
    SELECT id INTO municipio_id FROM municipio WHERE nombre = p_municipio;
    
    IF municipio_id IS NULL THEN
        INSERT INTO municipio (nombre) VALUES (p_municipio);
        SET municipio_id = LAST_INSERT_ID();
    END IF;
    
    INSERT INTO restaurante (id, direccion, zona, personal, parqueo, municipio_id) 
    VALUES (p_id, p_direccion, p_zona, p_personal, p_parqueo, municipio_id);
    SELECT 'Registro insertado correctamente.' as mensaje;

END $$
DELIMITER ;


DELIMITER //

CREATE PROCEDURE registrarEmpleado(
    IN nombres VARCHAR(30),
    IN apellidos VARCHAR(30),
    IN fecha_nac DATE,
    IN correo VARCHAR(30),
    IN telefono INT,
    IN direccion VARCHAR(60),
    IN dpi BIGINT,
    IN puesto_id INT,
    IN fecha_inicio DATE,
    IN idRestaurante INT
)
BEGIN
    DECLARE nuevo_id INT;
    DECLARE formato_valido INT DEFAULT 0;

    -- Validar formato de correo
    IF correo REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        SET formato_valido = 1;
    END IF;

	IF formato_valido = 1 THEN
        -- Generar nuevo ID
		SELECT IFNULL(MAX(id),0) + 1 INTO nuevo_id FROM empleado;

		-- Formatear ID con 8 dígitos
		SET nuevo_id = LPAD(nuevo_id, 8, '0');

		-- Insertar empleado en tabla empleado
		INSERT INTO empleado(id, nombres, apellidos, fecha_nac, correo, telefono, direccion, dpi, fecha_inicio, restaurante_id, puesto_id)
			VALUES(nuevo_id, nombres, apellidos, fecha_nac, correo, telefono, direccion, dpi, fecha_inicio, idRestaurante, puesto_id);
        SELECT 'Registro insertado correctamente.' as mensaje;
    ELSE
        SELECT 'Formato de correo electrónico inválido. Por favor ingrese un correo válido.' as mensaje;
    END IF;
    
    
END //

DELIMITER ;


DELIMITER $$
CREATE PROCEDURE insertarPuesto(
    IN p_Nombre VARCHAR(30),
    IN p_Descripcion VARCHAR(100),
    IN p_Salario DECIMAL(10, 2)
)
BEGIN
    IF p_Salario < 0 THEN
                SELECT 'El salario no puede ser negativo.' as mensaje;
    ELSE
        INSERT INTO puesto (nombre, descripcion, salario) VALUES (p_Nombre, p_Descripcion, p_Salario);
        SELECT 'Registro insertado correctamente.' as mensaje;

    END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE insertarCliente(
    IN dpi_p        BIGINT,
    IN nombre_p     VARCHAR(30),
    IN apellidos_p  VARCHAR(30),
    IN fecha_nac_p  DATE,
    IN correo_p     VARCHAR(30),
    IN telefono_p   INT,
    IN nit_p        INT
)
BEGIN
    DECLARE correo_valido INT;
    SET correo_valido = 0;
    
    IF correo_p REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        SET correo_valido = 1;
    END IF;
    
    IF correo_valido = 1 THEN
        INSERT INTO cliente(dpi, nombre, apellidos, fecha_nac, correo, telefono, nit) 
        VALUES(dpi_p, nombre_p, apellidos_p, fecha_nac_p, correo_p, telefono_p, nit_p);
        SELECT 'Registro insertado correctamente.' as mensaje;
    ELSE
        SELECT 'Formato de correo electrónico inválido. Por favor ingrese un correo válido.' as mensaje;
    END IF;
END$$
DELIMITER ;

DELIMITER //

CREATE PROCEDURE crearDireccion(
    IN dpi_cliente BIGINT,
    IN direccion VARCHAR(100),
    IN municipio_nombre VARCHAR(30),
    IN zona INT
)
END_PROCEDURE: BEGIN
    DECLARE municipio_id INT;
    
    -- Buscar el id del municipio
    SELECT id INTO municipio_id FROM municipio WHERE nombre = municipio_nombre;
    
    IF municipio_id IS NULL THEN
        INSERT INTO municipio (nombre) VALUES (municipio_nombre);
        SET municipio_id = LAST_INSERT_ID();
    END IF;
    
    -- Validar que el cliente exista
    IF NOT EXISTS (SELECT * FROM cliente WHERE dpi = dpi_cliente) THEN
		SELECT 'El cliente no existe' as mensaje;
		leave END_PROCEDURE;
    END IF;

    -- Validar que la zona sea entero positivo
    IF zona < 1 THEN
		SELECT 'La zona debe de ser un numero positivo.' as mensaje;
		leave END_PROCEDURE;

    END IF;

    -- Insertar la dirección
    INSERT INTO direccion (direccion, zona, cliente_dpi, municipio_id)
    VALUES (direccion, zona, dpi_cliente, municipio_id);
    
    SELECT LAST_INSERT_ID() AS id; -- Retorna el id de la dirección recién creada
    SELECT 'Registro insertado correctamente.' as mensaje;

END END_PROCEDURE//

DELIMITER ;




#drop procedure crear_orden;

DELIMITER $$
CREATE PROCEDURE crearOrden (
    IN dpi_cliente BIGINT,
    IN id_direccion_cliente NUMERIC,
    IN canal CHAR(1)
)
END_PROCEDURE: BEGIN
    DECLARE id_restaurante NUMERIC;
    DECLARE fecha_inicio DATETIME;
    DECLARE fecha_final DATETIME DEFAULT NULL;
    -- Obtener la dirección del cliente
    DECLARE direccion_cliente VARCHAR(100);
    DECLARE municipio_cliente VARCHAR(50);
    DECLARE zona_cliente NUMERIC;
    SET fecha_inicio = NOW();
    
    
    IF (canal <> 'L' AND canal <> 'A') THEN
		SELECT CONCAT('El canal con valor ', canal, ' no es permitido, debe ser L o A.') AS mensaje;
        Leave END_PROCEDURE;    
	END IF;
    
    -- Validar que el cliente exista
    IF NOT EXISTS (SELECT * FROM cliente WHERE dpi = dpi_cliente) THEN
		SELECT CONCAT('El cliente con DPI ', dpi_cliente, ' no existe.') AS mensaje;
        Leave END_PROCEDURE;
    END IF;
    
    
    SELECT direccion, municipio_id, zona
    INTO direccion_cliente, municipio_cliente, zona_cliente
    FROM direccion
    WHERE id = id_direccion_cliente;
    
    -- Validar que la dirección exista
    IF direccion_cliente is null THEN
        SELECT CONCAT('La dirección con ID ', id_direccion_cliente, ' no existe.') AS mensaje ;
        Leave END_PROCEDURE;
    END IF;
    
    -- Obtener el restaurante que cubre la zona y municipio de la dirección del cliente
    SELECT id
    INTO id_restaurante
    FROM restaurante
    WHERE municipio_id = municipio_cliente AND zona = zona_cliente;
    
    -- Validar que exista un restaurante en la misma zona y municipio que la dirección del cliente
    IF id_restaurante IS NULL THEN
        INSERT INTO orden (fecha_inicio, cliente_dpi, direccion_id, restaurante_id, canal, estado)
        VALUES (fecha_inicio, dpi_cliente, id_direccion_cliente, NULL, canal, 'SIN COBERTURA');
		SELECT 'Registro insertado correctamente.' as mensaje;

        Leave END_PROCEDURE;

    END IF;
    
    -- Insertar la orden en la base de datos
    INSERT INTO orden (fecha_inicio, cliente_dpi, direccion_id, restaurante_id, canal, estado)
    VALUES (fecha_inicio, dpi_cliente, id_direccion_cliente, id_restaurante, canal, 'INICIADA');
    
    SELECT 'Registro insertado correctamente.' as mensaje;
    
  
    
END END_PROCEDURE$$
DELIMITER ;

DELIMITER //

CREATE PROCEDURE agregarItem(
    IN IdOrden INT,
    IN TipoProducto CHAR(1),
    IN Producto INT,
    IN Cantidad INT,
    IN Observacion VARCHAR(100)
)
END_PROCEDURE: BEGIN
    DECLARE EstadoOrden VARCHAR(13);
    DECLARE ProductoId VARCHAR(2);
    
    IF Producto < 0 THEN
                SELECT 'El producto especificado no existe' as mensaje;
		Leave END_PROCEDURE;
    END IF;
    
    -- Obtener el estado actual de la orden
    SELECT estado INTO EstadoOrden FROM orden WHERE id = IdOrden;
    
    -- Validar que la orden esté en estado INICIADA o AGREGANDO
    IF EstadoOrden NOT IN ('INICIADA', 'AGREGANDO') OR EstadoOrden is null THEN
        SELECT 'No se puede agregar productos a una orden que ya ha sido finalizada o está en camino para ser entregada al cliente' as mensaje;
		Leave END_PROCEDURE;
    END IF;
    
    -- Validar que el tipo de producto sea válido
    IF TipoProducto NOT IN ('C', 'E', 'B', 'P') THEN
        SELECT 'Tipo de producto inválido' as mensaje;
		Leave END_PROCEDURE;
    END IF;
    
    -- Validar que el producto exista
    SET ProductoId = CONCAT(TipoProducto, Producto);
    IF NOT EXISTS(SELECT id FROM producto WHERE id = ProductoId) THEN
        SELECT'El producto especificado no existe' as mensaje;
		Leave END_PROCEDURE;
    END IF;
    
    -- Insertar el item en la tabla
    INSERT INTO item (tipo_producto, producto_id, cantidad, orden_id, observacion)
    VALUES (TipoProducto, ProductoId, Cantidad, IdOrden, Observacion);
    
    -- Actualizar el estado de la orden si es necesario
    IF EstadoOrden = 'INICIADA' THEN
        UPDATE orden SET estado = 'AGREGANDO' WHERE id = IdOrden;
    END IF;
    SELECT 'Registro insertado correctamente.' as mensaje;

END END_PROCEDURE//

DELIMITER ;

drop procedure if exists confirmarOrden;
DELIMITER $$
CREATE PROCEDURE confirmarOrden(
    IN p_IdOrden INT,
    IN p_FormaPago CHAR(1),
    IN p_IdRepartidor INT
)
END_PROCEDURE: BEGIN
    DECLARE v_Impuesto DECIMAL(5,2);
    DECLARE v_Total DECIMAL(10,2);
    DECLARE v_Municipio VARCHAR(50);
    DECLARE v_NIT VARCHAR(50);
    DECLARE v_NumSerie VARCHAR(20);
    DECLARE v_Hora DATETIME;
    
    -- Validar que la orden exista y su estado sea válido
    SELECT estado, municipio_id, nit
    INTO @estado, v_Municipio, v_NIT
    FROM orden join cliente join direccion on direccion.id = orden.direccion_id 
    WHERE orden.id = p_IdOrden ;
    
    IF v_NIT IS NULL THEN
        set v_NIT = 'CF';
    END IF;
    
    IF @estado IS NULL OR @estado NOT IN ('INICIADA', 'AGREGANDO') THEN
        select 'La orden no existe o no se puede confirmar en este momento.' as mensaje;
        leave END_PROCEDURE;
    END IF;
    
    -- Calcular el impuesto y total
    SELECT SUM(precio * cantidad) * 0.12 AS impuesto, SUM(precio * cantidad) + SUM(precio * cantidad) * 0.12 AS total
    INTO v_Impuesto, v_Total
    FROM item
    join orden JOIN producto ON item.producto_id = producto.id
    WHERE item.orden_id = p_IdOrden;
    
    -- Actualizar el estado de la orden y el repartidor asignado
    UPDATE orden SET estado = 'EN CAMINO', empleado_id = p_IdRepartidor WHERE id = p_IdOrden;
    
    -- Generar la factura
    SET v_NumSerie = CONCAT(YEAR(CURDATE()), '-', p_IdOrden);
    SET v_Hora = NOW();
    
    INSERT INTO factura (serie, monto, lugar, fecha, orden_id, nit, forma_pago)
    VALUES (v_NumSerie, v_Total + v_Impuesto, v_Municipio, v_Hora, p_IdOrden, v_NIT, p_FormaPago);
    
    SELECT 'Registro insertado correctamente.' as mensaje;

END END_PROCEDURE$$
DELIMITER ;


drop procedure if exists finalizarOrden;

DELIMITER $$
CREATE PROCEDURE finalizarOrden(
    IN pIdOrden INT
)
BEGIN
    DECLARE vEstado VARCHAR(20);
    
    -- Verificar que la orden exista y esté en estado "EN CAMINO"
    SELECT estado INTO vEstado FROM orden WHERE id = pIdOrden;
    
    IF vEstado IS NULL THEN
        SELECT "La orden no existe" AS mensaje;
    ELSEIF vEstado <> "EN CAMINO" THEN
        SELECT "La orden no se puede finalizar porque su estado es distinto a 'EN CAMINO'" AS Mensaje;
    ELSE
        -- Actualizar el estado de la orden a "ENTREGADA"
        UPDATE orden SET estado = "ENTREGADA", fecha_entrega = NOW() WHERE id = pIdOrden;
        SELECT "La orden se ha finalizado correctamente" AS Mensaje;
    END IF;
END$$
DELIMITER ;



#---------------------------Triggers Transacciones-----------------------------




DELIMITER //

CREATE TRIGGER registro_transaccionIempleado AFTER INSERT ON empleado
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una inserción en la tabla empleados.'), 1);
END//

CREATE TRIGGER registro_transaccionUempleado AFTER UPDATE ON empleado
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una actualización en la tabla empleados.'), 2);
END//

CREATE TRIGGER registro_transaccionDempleado AFTER DELETE ON empleado
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una eliminación en la tabla empleados.'), 3);
END//

DELIMITER ;

DELIMITER //

CREATE TRIGGER registro_transaccionIcliente AFTER INSERT ON cliente
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una inserción en la tabla clientes.'), 1);
END//

CREATE TRIGGER registro_transaccionUcliente AFTER UPDATE ON cliente
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una actualización en la tabla clientes.'), 2);
END//

CREATE TRIGGER registro_transaccionDcliente AFTER DELETE ON cliente
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una eliminación en la tabla clientes.'), 3);
END//

DELIMITER ;


DELIMITER //

CREATE TRIGGER registro_transaccionIrestaurante AFTER INSERT ON restaurante
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una inserción en la tabla restaurantes.'), 1);
END//

CREATE TRIGGER registro_transaccionUrestaurante AFTER UPDATE ON restaurante
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una actualización en la tabla restaurantes.'), 2);
END//

CREATE TRIGGER registro_transaccionDrestaurante AFTER DELETE ON restaurante
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una eliminación en la tabla restaurantes.'), 3);
END//

DELIMITER ;

DELIMITER //

CREATE TRIGGER registro_transaccionIdireccion AFTER INSERT ON direccion
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una inserción en la tabla direcciones.'), 1);
END//

CREATE TRIGGER registro_transaccionUdireccion AFTER UPDATE ON direccion
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una actualización en la tabla direcciones.'), 2);
END//

CREATE TRIGGER registro_transaccionDdireccion AFTER DELETE ON direccion
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una eliminación en la tabla direcciones.'), 3);
END//

DELIMITER ;

DELIMITER //

CREATE TRIGGER registro_transaccionIfactura AFTER INSERT ON factura
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una inserción en la tabla facturas.'), 1);
END//

CREATE TRIGGER registro_transaccionUfactura AFTER UPDATE ON factura
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una actualización en la tabla facturas.'), 2);
END//

CREATE TRIGGER registro_transaccionDfactura AFTER DELETE ON factura
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una eliminación en la tabla facturas.'), 3);
END//

DELIMITER ;

DELIMITER //

CREATE TRIGGER registro_transaccionIitem AFTER INSERT ON item
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una inserción en la tabla items.'), 1);
END//

CREATE TRIGGER registro_transaccionUitem AFTER UPDATE ON item
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una actualización en la tabla items.'), 2);
END//

CREATE TRIGGER registro_transaccionDitem AFTER DELETE ON item
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una eliminación en la tabla items.'), 3);
END//

DELIMITER ;

DELIMITER //

CREATE TRIGGER registro_transaccionImunicipio AFTER INSERT ON municipio
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una inserción en la tabla municipios.'), 1);
END//

CREATE TRIGGER registro_transaccionUmunicipio AFTER UPDATE ON municipio
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una actualización en la tabla municipios.'), 2);
END//

CREATE TRIGGER registro_transaccionDmunicipio AFTER DELETE ON municipio
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una eliminación en la tabla municipios.'), 3);
END//

DELIMITER ;

DELIMITER //

CREATE TRIGGER registro_transaccionIorden AFTER INSERT ON orden
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una inserción en la tabla ordenes.'), 1);
END//

CREATE TRIGGER registro_transaccionUorden AFTER UPDATE ON orden
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una actualización en la tabla ordenes.'), 2);
END//

CREATE TRIGGER registro_transaccionDorden AFTER DELETE ON orden
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una eliminación en la tabla ordenes.'), 3);
END//

DELIMITER ;

DELIMITER //


DELIMITER //

CREATE TRIGGER registro_transaccionIpuesto AFTER INSERT ON puesto
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una inserción en la tabla puestos.'), 1);
END//

CREATE TRIGGER registro_transaccionUpuesto AFTER UPDATE ON puesto
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una actualización en la tabla puestos.'), 2);
END//

CREATE TRIGGER registro_transaccionDpuesto AFTER DELETE ON puesto
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una eliminación en la tabla puestos.'), 3);
END//

DELIMITER ;


DELIMITER //

CREATE TRIGGER registro_transaccionIproducto AFTER INSERT ON producto
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una inserción en la tabla puestos.'), 1);
END//

CREATE TRIGGER registro_transaccionUproducto AFTER UPDATE ON producto
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una actualización en la tabla puestos.'), 2);
END//

CREATE TRIGGER registro_transaccionDproducto AFTER DELETE ON producto
FOR EACH ROW
BEGIN
    INSERT INTO transaccion (fecha, descripcion, tipo_id)
    VALUES (NOW(), CONCAT('Se ha realizado una eliminación en la tabla puestos.'), 3);
END//

DELIMITER ;

INSERT INTO tipo (nombre) VALUES ('INSERT');
INSERT INTO tipo (nombre) VALUES ('UPDATE');
INSERT INTO tipo (nombre) VALUES ('DELETE');

INSERT INTO producto (id, nombre, precio)
VALUES 
('C1', 'Cheeseburger', '41.00'),
('C2', 'Chicken Sandwich', '32.00'),
('C3', 'BBQ Ribs', '54.00'),
('C4', 'Pasta Alfredo', '47.00'),
('C5', 'Pizza Espinator', '85.00'),
('C6', 'Buffalo Wings', '36.00'),
('E1', 'Papas fritas', '15.00'),
('E2', 'Aros de cebolla', '17.00'),
('E3', 'Coleslaw', '12.00'),
('B1', 'Coca-Cola', '12.00'),
('B2', 'Fanta', '12.00'),
('B3', 'Sprite', '12.00'),
('B4', 'Té frío', '12.00'),
('B5', 'Cerveza de barril', '18.00'),
('P1', 'Copa de helado', '13.00'),
('P2', 'Cheesecake', '15.00'),
('P3', 'Cupcake de chocolate', '8.00'),
('P4', 'Flan', '10.00');





CALL insertarPuesto('Gerente', 'Encargado de supervisar el restaurante', 5000.00);
CALL insertarPuesto('Gerente2', 'Encargado de supervisar el restaurante', -5000.00);



CALL registrarRestaurante(1, '4a Calle 7-58, Zona 2', 'Guatemala', 2, 15, 0);
CALL registrarEmpleado('Juan', 'Pérez', '1990-01-01', 'juan.perez@example.com', 12345678, '5a. Avenida 15-20, Zona 10', 1234567890123, 1, '2022-01-01', 1);

CALL insertarCliente(1234567890123, 'Juan', 'Pérez', '1990-01-01', 'juanperez@gmail.com', 12345678, NULL);

CALL crearDireccion(1234567890123, '5a. Avenida 10-25, Zona 2', 'Guatemala', 2);
CALL crearDireccion(1234567890123, '5a. Avenida 10-25, Zona 1', 'Guatemala', 1);
CALL crearDireccion(1234567890123, '5a. Avenida 10-25, Zona 6', 'Guatemala', 6);


CALL crearOrden(1234567890123, 2, 'A');
CALL crearOrden(1234567890123, 1, 'A');


CALL agregarItem(2, 'C', 3, 1, 'Sin cebolla');
CALL confirmarOrden(2, 'T', 1);

CALL finalizarOrden(2);

