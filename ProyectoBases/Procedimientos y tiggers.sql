#---------------------------------------------------Registros---------------------------------------------------------------------

drop procedure if exists RegistrarRestaurante;
DELIMITER $$
CREATE PROCEDURE RegistrarRestaurante(
    IN p_id varchar(20),
    IN p_direccion VARCHAR(60),
    IN p_municipio VARCHAR(30),
    IN p_zona INT,
    IN p_tel INT,
    IN p_personal INT,
    IN p_parqueo BOOLEAN
)
END_PROCEDURE: BEGIN
    DECLARE municipio_id INT;
    DECLARE rest_id varchar(20);
    IF p_zona < 0 THEN
                SELECT 'El zona no puede ser negativo.' as mensaje;
                leave END_PROCEDURE;
    END IF;
	
    SELECT id INTO rest_id FROM restaurante WHERE id = p_id;
    
    IF rest_id IS not NULL THEN
        SELECT 'El restaurante no puede ser estar duplicado.' as mensaje;
		leave END_PROCEDURE;
    END IF;
    
    IF p_personal < 0 THEN
                SELECT 'El personal no puede ser negativo.' as mensaje;
                leave END_PROCEDURE;
    END IF;
    
    SELECT id INTO municipio_id FROM municipio WHERE nombre = p_municipio;
    
    IF municipio_id IS NULL THEN
        INSERT INTO municipio (nombre) VALUES (p_municipio);
        SET municipio_id = LAST_INSERT_ID();
    END IF;
    
    INSERT INTO restaurante (id, direccion, zona, personal, parqueo, municipio_id, telefono) 
    VALUES (p_id, p_direccion, p_zona, p_personal, p_parqueo, municipio_id, p_tel);
    SELECT 'Registro insertado correctamente.' as mensaje;

END END_PROCEDURE$$
DELIMITER ;

drop procedure if exists CrearEmpleado;

DELIMITER //

CREATE PROCEDURE CrearEmpleado(
    IN nombres VARCHAR(30),
    IN apellidos VARCHAR(30),
    IN fecha_nac DATE,
    IN correo VARCHAR(30),
    IN telefono INT,
    IN direccion VARCHAR(60),
    IN dpi BIGINT,
    IN puesto_id INT,
    IN fecha_inicio DATE,
    IN idRestaurante varchar(20)
)
END_PROCEDURE: BEGIN
    DECLARE nuevo_id INT;
    DECLARE formato_valido INT DEFAULT 0;
	declare v_puesto VARCHAR(30);
	DECLARE rest_id varchar(20);
	DECLARE emp_id varchar(20);
	DECLARE v_personal int;
	DECLARE v_personalC int;

	select personal into v_personalC  from restaurante where id = idRestaurante;
    select count(empleado.id)INTO v_personal from empleado join restaurante on empleado.restaurante_id = restaurante.id where restaurante.id = idRestaurante;    
    
    IF v_personal >= v_personalC THEN
        SELECT 'El personal del restaurante llego a su limite.' as mensaje;
		leave END_PROCEDURE;
    END IF;
    
    SELECT id INTO emp_id FROM empleado WHERE empleado.dpi = dpi;
    
    IF emp_id IS not NULL THEN
        SELECT 'El empleado no puede ser estar duplicado.' as mensaje;
		leave END_PROCEDURE;
    END IF;
	
    SELECT id INTO rest_id FROM restaurante WHERE id = idRestaurante;
    
    IF rest_id IS NULL THEN
        SELECT 'El restaurante no existe.' as mensaje;
		leave END_PROCEDURE;
    END IF;
    select id into v_puesto from puesto where puesto_id= id;
	IF v_puesto IS NULL THEN
        SELECT 'El puesto no existe.' as mensaje;
		leave END_PROCEDURE;
    END IF;
    
    -- Validar formato de correo
    IF correo REGEXP '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$' THEN
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
    
    
END END_PROCEDURE//

DELIMITER ;

drop procedure if exists RegistrarPuesto;
DELIMITER $$
CREATE PROCEDURE RegistrarPuesto(
    IN p_Nombre VARCHAR(30),
    IN p_Descripcion VARCHAR(100),
    IN p_Salario DECIMAL(10, 2)
)
END_PROCEDURE: BEGIN
	declare v_puesto VARCHAR(30);
    select nombre into v_puesto from puesto where p_nombre= nombre;
	IF v_puesto IS not NULL THEN
        SELECT 'El puesto no puede ser estar duplicado.' as mensaje;
		leave END_PROCEDURE;
    END IF;
    IF p_Salario < 0 THEN
                SELECT 'El salario no puede ser negativo.' as mensaje;
    ELSE
        INSERT INTO puesto (nombre, descripcion, salario) VALUES (p_Nombre, p_Descripcion, p_Salario);
        SELECT 'Registro insertado correctamente.' as mensaje;

    END IF;
END END_PROCEDURE$$
DELIMITER ;

drop procedure if exists RegistrarCliente;

DELIMITER $$
CREATE PROCEDURE RegistrarCliente(
    IN dpi_p        BIGINT,
    IN nombre_p     VARCHAR(30),
    IN apellidos_p  VARCHAR(30),
    IN fecha_nac_p  DATE,
    IN correo_p     VARCHAR(30),
    IN telefono_p   INT,
    IN nit_p        INT
)
END_PROCEDURE: BEGIN
    DECLARE correo_valido INT;
    Declare dpi_cli bigint;
    SELECT dpi INTO dpi_cli FROM cliente WHERE cliente.dpi = dpi_p;
    
    IF dpi_cli IS not NULL THEN
        SELECT 'El cliente no puede ser estar duplicado.' as mensaje;
		leave END_PROCEDURE;
    END IF;
    
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
END END_PROCEDURE$$
DELIMITER ;

drop procedure if exists RegistrarDireccion;


DELIMITER //

CREATE PROCEDURE RegistrarDireccion(
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




drop procedure if exists CrearOrden;

DELIMITER $$
CREATE PROCEDURE CrearOrden (
    IN dpi_cliente BIGINT,
    IN id_direccion_cliente NUMERIC,
    IN canal CHAR(1)
)
END_PROCEDURE: BEGIN
    DECLARE id_restaurante varchar(20);
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
		SELECT CONCAT('El cliente con DPI ', dpi_cliente, ' no existe o no es de este cliente.') AS mensaje;
        Leave END_PROCEDURE;
    END IF;
    
    
    SELECT direccion, municipio_id, zona
    INTO direccion_cliente, municipio_cliente, zona_cliente
    FROM direccion
    WHERE id = id_direccion_cliente and cliente_dpi = dpi_cliente;
    
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


drop procedure if exists AgregarItem;


DELIMITER //

CREATE PROCEDURE AgregarItem(
    IN IdOrden INT,
    IN TipoProducto CHAR(1),
    IN Producto INT,
    IN Cantidad INT,
    IN Observacion VARCHAR(100)
)
END_PROCEDURE: BEGIN
    DECLARE EstadoOrden VARCHAR(13);
    DECLARE ProductoId VARCHAR(20);
    
    IF Producto < 0 THEN
                SELECT 'El producto especificado no existe' as mensaje;
		Leave END_PROCEDURE;
    END IF;
    
    IF Cantidad < 0 THEN
                SELECT 'La cantidad debe ser positiva' as mensaje;
		Leave END_PROCEDURE;
    END IF;
    
    -- Obtener el estado actual de la orden
    SELECT estado INTO EstadoOrden FROM orden WHERE id = IdOrden;
    
    -- Validar que la orden esté en estado INICIADA o AGREGANDO
    IF EstadoOrden NOT IN ('INICIADA', 'AGREGANDO') OR EstadoOrden is null THEN
        SELECT 'No se puede agregar productos a una orden que ya ha sido finalizada o está en camino para ser entregada al cliente o inexistente o sin cobertura' as mensaje;
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

drop procedure if exists ConfirmarOrden;
DELIMITER $$
CREATE PROCEDURE ConfirmarOrden(
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
    declare emp_id int;
    declare forma varchar(10);
    
    
    
    
    SELECT id INTO emp_id FROM empleado WHERE empleado.id = p_IdRepartidor;
    
    IF emp_id IS NULL THEN
        SELECT 'El empleado no existe.' as mensaje;
		leave END_PROCEDURE;
    END IF;
    
    IF (p_FormaPago <> 'T' AND p_FormaPago <> 'E') THEN
		SELECT CONCAT('El Metodo de pago con valor ', p_FormaPago, ' no es permitido, debe ser E o T.') AS mensaje;
        Leave END_PROCEDURE;    
	END IF;
    
    -- Validar que la orden exista y su estado sea válido
    SELECT estado, municipio_id, nit
    INTO @estado, v_Municipio, v_NIT
    FROM orden join cliente join direccion on direccion.id = orden.direccion_id 
    WHERE orden.id = p_IdOrden and orden.cliente_dpi = cliente.dpi;
    
    IF v_NIT IS NULL THEN
        set v_NIT = 'CF';
    END IF;
    
    IF @estado IS NULL OR @estado NOT IN ('INICIADA', 'AGREGANDO') THEN
        select 'La orden no existe o no se puede confirmar en este momento.' as mensaje;
        leave END_PROCEDURE;
    END IF;
    
    -- Calcular el impuesto y total
    SELECT SUM(precio * cantidad) * 0.12 AS impuesto, SUM(precio * cantidad) AS total
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


drop procedure if exists FinalizarOrden;

DELIMITER $$
CREATE PROCEDURE FinalizarOrden(
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

#---------------------------------------------------Consultas---------------------------------------------------------------------

drop procedure if exists ListarRestaurantes;

DELIMITER $$
CREATE PROCEDURE ListarRestaurantes()
BEGIN
    SELECT r.id, r.direccion, r.zona, r.personal, 
        CASE r.parqueo WHEN true THEN 'Si' ELSE 'No' END as parqueo,
        m.nombre as municipio
    FROM restaurante r
    INNER JOIN municipio m ON r.municipio_id = m.id;
END $$
DELIMITER ;

drop procedure if exists ConsultarEmpleado;
DELIMITER //

CREATE PROCEDURE ConsultarEmpleado(IN idEmpleado INT)
BEGIN
    SELECT LPAD(e.id, 8, '0') as IdEmpleado,
           CONCAT(e.nombres, ' ', e.apellidos) as NombreCompleto,
           e.fecha_nac as FechaNacimiento,
           e.correo as Correo,
           e.telefono as Telefono,
           e.direccion as Direccion,
           e.dpi as NumeroDPI,
           p.nombre as NombrePuesto,
           e.fecha_inicio as FechaInicio,
           pu.salario as Salario
    FROM empleado e
    INNER JOIN puesto p ON e.puesto_id = p.id
    INNER JOIN restaurante r ON e.restaurante_id = r.id
    INNER JOIN puesto pu ON p.id = pu.id
    WHERE e.id = idEmpleado;
END //

DELIMITER ;

drop procedure if exists ConsultarPedidosCliente;
DELIMITER //

CREATE PROCEDURE ConsultarPedidosCliente(IN id_orden bigint)
BEGIN
    SELECT CONCAT(SUBSTRING(item.producto_id, 1, 1), '.', producto.nombre) AS Producto, 
           CASE SUBSTRING(item.producto_id, 1, 1)
                WHEN 'C' THEN 'Combo'
                WHEN 'E' THEN 'Extra'
                WHEN 'B' THEN 'Bebida'
                WHEN 'P' THEN 'Postre'
           END AS Tipo_Producto,
           producto.precio AS Precio, 
           item.cantidad AS Cantidad, 
           COALESCE(item.observacion, '') AS Observacion
    FROM item
    JOIN producto ON item.producto_id = producto.id
    WHERE item.orden_id = id_orden;
END //

DELIMITER ;

drop procedure if exists ConsultarHistorialOrdenes;
DELIMITER //
CREATE PROCEDURE ConsultarHistorialOrdenes(IN cliente_id BIGINT)
BEGIN
    declare v_impuesto decimal;
    declare v_Total decimal;
    
    SELECT SUM(precio * cantidad) * 0.12 AS impuesto, SUM(precio * cantidad) AS total
    INTO v_Impuesto, v_Total
    FROM item 
    join cliente
    join orden JOIN producto ON item.producto_id = producto.id
    WHERE item.orden_id = orden.id and cliente.dpi = orden.cliente_dpi;
    
    SELECT o.id AS IdOrden, o.fecha_inicio AS Fecha, v_Impuesto + v_Total AS MontoDeLaOrden, r.id AS Restaurante, CONCAT(e.nombres, ' ', e.apellidos) AS Repartidor, d.direccion AS DireccionEnviada,
        CASE o.canal
            WHEN 'L' THEN 'Llamada'
            WHEN 'A' THEN 'Aplicación'
        END AS Canal
    FROM orden AS o
    JOIN restaurante AS r ON o.restaurante_id = r.id
    JOIN empleado AS e ON o.empleado_id = e.id
    JOIN direccion AS d ON o.direccion_id = d.id
    WHERE o.cliente_dpi = cliente_id;
END //
DELIMITER ;


drop procedure if exists ConsultarDirecciones;

DELIMITER //
CREATE PROCEDURE ConsultarDirecciones(IN id_cliente BIGINT)
BEGIN
  SELECT direccion, municipio.nombre as municipio, zona
  FROM direccion
  INNER JOIN municipio ON direccion.municipio_id = municipio.id
  WHERE cliente_dpi = id_cliente;
END //

DELIMITER ;

drop procedure if exists MostrarOrdenes;
DELIMITER $$
CREATE PROCEDURE MostrarOrdenes(IN state INT)
BEGIN
  SELECT orden.id AS IdOrden, orden.estado AS Estado, orden.fecha_inicio AS Fecha, cliente.dpi AS `DPI cliente`, direccion.direccion AS Dirección,
    orden.restaurante_id AS Restaurante,
    CASE orden.canal
      WHEN 'L' THEN 'Llamada'
      WHEN 'A' THEN 'Aplicación'
      ELSE ''
    END AS Canal
  FROM orden
  INNER JOIN cliente ON orden.cliente_dpi = cliente.dpi
  INNER JOIN direccion ON orden.direccion_id = direccion.id
  WHERE CASE
      WHEN state = 1 THEN orden.estado = 'INICIADA'
      WHEN state = 2 THEN orden.estado = 'AGREGANDO'
      WHEN state = 3 THEN orden.estado = 'EN CAMINO'
      WHEN state = 4 THEN orden.estado = 'ENTREGADA'
      WHEN state = -1 THEN orden.estado = 'SIN COBERTURA'
      ELSE FALSE
    END;
END$$
DELIMITER ;

drop procedure if exists ConsultarFacturas;
DELIMITER //

CREATE PROCEDURE ConsultarFacturas(IN p_dia INT, IN p_mes INT, IN p_anio INT)
BEGIN
    SELECT f.serie AS 'Número de serie',
           f.monto AS 'Monto total de la factura',
           m.nombre AS 'Lugar',
           f.fecha AS 'Fecha y hora',
           f.orden_id AS 'IdOrden',
           COALESCE(f.nit, 'C/F') AS 'NIT',
           CASE f.forma_pago
               WHEN 'E' THEN 'Efectivo'
               WHEN 'T' THEN 'Tarjeta'
           END AS 'Forma de pago'
    FROM factura f
    INNER JOIN municipio m ON m.id = f.lugar
    WHERE DAY(f.fecha) = p_dia AND MONTH(f.fecha) = p_mes AND YEAR(f.fecha) = p_anio;
END//

DELIMITER ;


drop procedure if exists ConsultarTiempos;
DELIMITER //
CREATE PROCEDURE ConsultarTiempos(minutos INT)
BEGIN
    IF minutos < 0 THEN
        SELECT 'Error: El valor ingresado debe ser un número positivo';
    ELSE
        SELECT o.id, d.direccion, o.fecha_inicio, TIMESTAMPDIFF(MINUTE, o.fecha_inicio, o.fecha_entrega) AS tiempo_espera, CONCAT(e.nombres, e.apellidos) AS repartidor
        FROM orden o
        INNER JOIN direccion d ON o.direccion_id = d.id
        INNER JOIN empleado e ON o.empleado_id = e.id
        WHERE TIMESTAMPDIFF(MINUTE, o.fecha_inicio, o.fecha_entrega) >= minutos;
    END IF;
END //
DELIMITER ;

#----------------------------------------------Triggers Transacciones-------------------------------------------------------------




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

