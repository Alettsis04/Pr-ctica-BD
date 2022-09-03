drop database hades;

create database hades;

use hades;

CREATE TABLE data_log (
    id_log   INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  action varchar(20),
  user varchar(50),
  id int,
  tabla varchar (20),
    timestamp   TIMESTAMP,
  columna varchar (20),
    dataOLD VARCHAR(255) NOT NULL,
  dataNEW  DECIMAL(5,2) NOT NULL
);

create table Persona (
id int primary key auto_increment,
nombre varchar(20),
apellido varchar(20),
tipoID enum ('cedula','pasaporte','otro'),
identificacion varchar(20) unique,
email varchar(50)
);

create table Provincia(
 id int primary key auto_increment,
nombre varchar(50)
);

create table Compania(
 id int primary key auto_increment,
nombre varchar(50),
lugar varchar(50)
);

create table Cliente (
id int primary key auto_increment,
id_persona int,
FOREIGN KEY (id_persona) references Persona (id) on update cascade on delete cascade
);

create table Empleado (
id int primary key auto_increment,
id_persona int,
sueldo double,
id_compania int,
FOREIGN KEY (id_persona) references Persona(id) on update cascade on delete cascade,
FOREIGN KEY (id_compania) references Compania(id) on update cascade on delete cascade);

create table Institucion(
 id int primary key auto_increment,
 nombre varchar(50),
 id_provincia int,
 FOREIGN KEY (id_provincia) references Provincia(id) on update cascade on delete cascade
 );

create table Servicio(
 id int primary key auto_increment,
 valor double,
 tipo enum('Servicio Basico','Television satelital','Pago Colegios','Prestamo'),
 descripcion varchar(150),
 id_institucion int,
 FOREIGN KEY (id_institucion) references Institucion(id) on update cascade on delete cascade
 );

create table Pagos(
 id int primary key auto_increment,
 tipoPago enum ('Parcial','Total'),
 totalCuotas double,
 lugar varchar (50),
 valorRecargo enum('1%','5%','10%'),
 estadoPago enum('porVencer','Vencido'),
 fecha date,
 id_empleado int,
 id_servicio int,
 id_cliente int,
 FOREIGN KEY (id_empleado) references Empleado(id) on update cascade on delete cascade,
 FOREIGN KEY (id_servicio) references Servicio(id) on update cascade on delete cascade,
 FOREIGN KEY (id_cliente) references Cliente(id) on update cascade on delete cascade
 );

create table Cuota(
 id int primary key auto_increment,
 fechaPago date default null,
 fechaProximoPago date default null,
 id_pagos int,  
 recargo double,
 totalPagar double,
 estado boolean default false,
 FOREIGN KEY (id_pagos) references Pagos(id) on update cascade on delete cascade
 );
 
create table RegistroPagos(
  id int primary key auto_increment,
  nombreCliente varchar (50),
  identificacionCliente varchar (10),
  id_pago int,
  fecha date,
  FOREIGN KEY (id_pago) references Pagos(id) on update cascade on delete cascade
);

create table Mensajeria(
  id int primary key auto_increment,
  emailCliente varchar (50),
  id_pago int,
  mensaje varchar (100),
  FOREIGN KEY (id_pago) references Pagos(id) on update cascade on delete cascade
);

DELIMITER $$
CREATE TRIGGER mensajeria_Insert
AFTER Insert ON Pagos
FOR EACH ROW
BEGIN
declare _cliente int;
declare _email varchar(50);
declare _tipo varchar (50);
declare _mensaje varchar (100);
  if (NEW.tipoPago = 'Total') THEN
  select id_cliente into _cliente from Pagos where id = new.id;
  select email into _email from Cliente inner join Persona on Cliente.id_persona = Persona.id where Cliente.id = _cliente;
  select tipo into _tipo from Pagos inner join Servicio on Pagos.id_servicio = Servicio.id where Pagos.id = new.id;
  where Pagos.id = new.id;
  set _mensaje = 'Se ha realizado el pago exitosamente';
  insert into Mensajeria (emailCliente, id_pago, mensaje) values (_email, new.id, _mensaje);
  end if;
END$$

DELIMITER $$
CREATE TRIGGER registrar_pagos_Update
AFTER UPDATE ON Pagos
FOR EACH ROW
BEGIN
declare _cliente int;
declare _nombre varchar(50);
declare _identificacion varchar (10);
declare _fecha date;
  if (NEW.tipoPago = 'Total') THEN
  select id_cliente into _cliente from Pagos where id = new.id;
  select nombre into _nombre from Cliente inner join Persona on Cliente.id_persona = Persona.id where Cliente.id = _cliente;
  select identificacion into _identificacion from Cliente inner join Persona on Cliente.id_persona = Persona.id where Cliente.id = _cliente;
  set _fecha = Date(now());
  insert into RegistroPagos (nombreCliente, identificacionCliente, id_pago, fecha) values (_nombre, _identificacion, new.id, _fecha);
  end if;
END$$


DELIMITER $$
CREATE TRIGGER registrar_pagos_Insert
AFTER Insert ON Pagos
FOR EACH ROW
BEGIN
declare _cliente int;
declare _nombre varchar(50);
declare _identificacion varchar (10);
declare _fecha date;
  if (NEW.tipoPago = 'Total') THEN
  select id_cliente into _cliente from Pagos where id = new.id;
  select nombre into _nombre from Cliente inner join Persona on Cliente.id_persona = Persona.id where Cliente.id = _cliente;
  select identificacion into _identificacion from Cliente inner join Persona on Cliente.id_persona = Persona.id where Cliente.id = _cliente;
  set _fecha = Date(now());
  insert into RegistroPagos (nombreCliente, identificacionCliente, id_pago, fecha) values (_nombre, _identificacion, new.id, _fecha);
  end if;
END$$


DELIMITER $$
CREATE TRIGGER generar_cuotas
AFTER INSERT ON Pagos
FOR EACH ROW
BEGIN
  declare total int default 1;
  declare id_pago int;
  declare cont int default 0;
  declare _recargo double;
  declare total_Pagar double;
  declare Vrecargo varchar(50);
 
  IF (NEW.tipoPago = 'Parcial') THEN
 
  select id into id_pago from Pagos order by id desc limit 1;
  select totalCuotas into total from Pagos where id = id_pago;
  select valor into total_Pagar from Pagos inner join Servicio on Pagos.id_servicio = Servicio.id
  where Pagos.id = id_pago;
  select valorRecargo into Vrecargo from Pagos where id = id_pago;
  if (Vrecargo = '1%')then
    set _recargo = 0.01;
  ELSEIF (Vrecargo = '5%')then
    set _recargo = 0.05;
  else
    set _recargo = 0.10;
  end if;
  set total_Pagar = total_Pagar/total;
  while cont < total do
    insert into Cuota (id_pagos,recargo,totalPagar) values (id_pago, _recargo, total_Pagar);
    set cont = cont+1;
  end while;
  END IF ;
END$$


delimiter $$
  CREATE TRIGGER log_Persona AFTER update ON Persona
  FOR EACH ROW
  BEGIN
  if old.nombre <> new.nombre then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Persona',NOW(),'nombre',OLD.nombre,NEW.nombre);
  elseif old.apellido <> new.apellido then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Persona',NOW(),'apellido',OLD.apellido,NEW.apellido);
  elseif old.tipoID <> new.tipoID then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Persona',NOW(),'tipoID',OLD.tipoID,NEW.tipoID);
  elseif old.identificacion <> new.identificacion then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Persona',NOW(),'identificacion',OLD.identificacion,NEW.identificacion);
  else
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Persona',NOW(),'email',OLD.email,NEW.email);
  end if;
  END$$

delimiter $$
  CREATE TRIGGER log_Provincia AFTER update ON Provincia
  FOR EACH ROW
  BEGIN
  if old.nombre <> new.nombre then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Provincia',NOW(),'nombre',OLD.nombre,NEW.nombre);
  end if;
  END$$

delimiter $$
  CREATE TRIGGER log_Compania AFTER update ON Compania
  FOR EACH ROW
  BEGIN
  if old.nombre <> new.nombre then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Compania',NOW(),'nombre',OLD.nombre,NEW.nombre);
  else
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Compania',NOW(),'lugar',OLD.lugar,NEW.lugar);
  end if;
  END$$

delimiter $$
  CREATE TRIGGER log_Empleado AFTER update ON Empleado
  FOR EACH ROW
  BEGIN
  if old.sueldo <> new.sueldo then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Empleado',NOW(),'sueldo',OLD.sueldo,NEW.sueldo);
  else
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Empleado',NOW(),'id_compania',OLD.id_compania,NEW.id_compania);
  end if;
  END$$

delimiter $$
  CREATE TRIGGER log_Institucion AFTER update ON Institucion
  FOR EACH ROW
  BEGIN
  if old.nombre <> new.nombre then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Institucion',NOW(),'nombre',OLD.nombre,NEW.nombre);
  else
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Empleado',NOW(),'id_provincia',OLD.id_provincia,NEW.id_provincia);
  end if;
  END$$

delimiter $$
  CREATE TRIGGER log_Servicio AFTER update ON Servicio
  FOR EACH ROW
  BEGIN
  if old.valor <> new.valor then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Servicio',NOW(),'valor',OLD.valor,NEW.valor);
  elseif old.tipo <> new.tipo then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Servicio',NOW(),'tipo',OLD.tipo,NEW.tipo);
  elseif old.descripcion <> new.descripcion then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Servicio',NOW(),'descripcion',OLD.descripcion,NEW.descripcion);
  else
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Servicio',NOW(),'id_institucion',OLD.id_institucion,NEW.id_institucion);
  end if;
  END$$

delimiter $$
  CREATE TRIGGER log_Pagos AFTER update ON Pagos
  FOR EACH ROW
  BEGIN
  if old.tipoPago <> new.tipoPago then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Pagos',NOW(),'tipoPago',OLD.tipoPago,NEW.tipoPago);
  elseif old.totalCuotas <> new.totalCuotas then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Pagos',NOW(),'totalCuotas',OLD.totalCuotas,NEW.totalCuotas);
  elseif old.lugar <> new.lugar then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Pagos',NOW(),'lugar',OLD.lugar,NEW.lugar);
  elseif old.valorRecargo <> new.valorRecargo then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Pagos',NOW(),'valorRecargo',OLD.valorRecargo,NEW.valorRecargo);
  elseif old.estadoPago <> new.estadoPago then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Pagos',NOW(),'estadoPago',OLD.estadoPago,NEW.estadoPago);
  elseif old.fecha <> new.fecha then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Pagos',NOW(),'fecha',OLD.fecha,NEW.fecha);
  elseif old.id_empleado <> new.id_empleado then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Pagos',NOW(),'id_empleado',OLD.id_empleado,NEW.id_empleado);
  elseif old.id_cliente <> new.id_cliente then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Pagos',NOW(),'id_cliente',OLD.id_cliente,NEW.id_cliente);
  else
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Pagos',NOW(),'id_servicio',OLD.id_servicio,NEW.id_servicio);
  end if;
  END$$

delimiter $$
  CREATE TRIGGER log_Cuota AFTER update ON Cuota
  FOR EACH ROW
  BEGIN
  if old.fechaPago <> new.fechaPago then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Cuota',NOW(),'fechaPago',OLD.fechaPago,NEW.fechaPago);
  elseif old.fechaProximoPago <> new.fechaProximoPago then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Cuota',NOW(),'fechaProximoPago',OLD.fechaProximoPago,NEW.fechaProximoPago);
  elseif old.recargo <> new.recargo then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Cuota',NOW(),'recargo',OLD.recargo,NEW.recargo);
  elseif old.totalPagar <> new.totalPagar then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Cuota',NOW(),'totalPagar',OLD.totalPagar,NEW.totalPagar);
  elseif old.estado <> new.estado then
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Cuota',NOW(),'estado',OLD.estado,NEW.estado);
  else
  INSERT INTO data_log (action,user,id,tabla,timestamp,columna,dataOLD,dataNEW)
    VALUES('update',user(),NEW.id,'Cuota',NOW(),'id_pagos',OLD.id_pagos,NEW.id_pagos);
  end if;
  END$$

insert into Persona (nombre,apellido,tipoID,identificacion,email) values ('11111','11111','cedula','1111111111','11111@111111.com');
insert into Persona (nombre,apellido,tipoID,identificacion,email) values ('22222','22222','cedula','2222222222','22222@22222.com');
insert into Persona (nombre,apellido,tipoID,identificacion,email) values ('33333','33333','cedula','3333333333','33333@33333.com');
insert into Persona (nombre,apellido,tipoID,identificacion,email) values ('44444','44444','cedula','4444444444','44444@44444.com');
insert into Persona (nombre,apellido,tipoID,identificacion,email) values ('55555','55555','cedula','5555555555','55555@55555.com');


insert into Provincia (nombre) values ('provincia1');
insert into Provincia (nombre) values ('provincia2');
insert into Provincia (nombre) values ('provincia3');


insert into Compania (nombre,lugar) values ('compania1','lugar1');
insert into Compania (nombre,lugar) values ('compania2','lugar2');
insert into Compania (nombre,lugar) values ('compania3','lugar3');


insert into Cliente (id_persona) values (1);
insert into Cliente (id_persona) values (3);
insert into Cliente (id_persona) values (4);


insert into Empleado (id_persona,sueldo,id_compania) values (2,111.00,1);
insert into Empleado (id_persona,sueldo,id_compania) values (5,222.00,2);


insert into Institucion (nombre, id_provincia) values ('institucion1',1);
insert into Institucion (nombre, id_provincia) values ('institucion2',2);


insert into Servicio (valor,tipo,descripcion,id_institucion) values (100,'Servicio Basico','Luz',1);
insert into Servicio (valor,tipo,descripcion,id_institucion) values (200,'Television Satelital','22222222222',1);
insert into Servicio (valor,tipo,descripcion,id_institucion) values (300,'Pago Colegios','3333333333',2);
insert into Servicio (valor,tipo,descripcion,id_institucion) values (400,'Prestamo','44444444444',2);


insert into Pagos
(tipoPago,totalCuotas,lugar,valorRecargo,estadoPago,fecha,id_empleado,id_servicio,id_cliente)
values ('Total',0,'lugar1', '1%','Vencido',Date(now()),1,1,1);
insert into Pagos
(tipoPago,totalCuotas,lugar,valorRecargo,estadoPago,fecha,id_empleado,id_servicio,id_cliente)
values ('Parcial',4,'lugar1', '1%','porVencer',Date(now()),1,2,2);

