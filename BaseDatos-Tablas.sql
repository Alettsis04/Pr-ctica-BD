create database hades;

use hades;

create table auth( id int primary key auto_increment, accion char(1) not null, usuario char(20) not null, fecha timestamp not null, id_object integer, tabla varchar(20));

create table Persona (id int primary key auto_increment, nombre varchar(20), apellido varchar(20), tipoID enum ('cedula','pasaporte','otro'), identificacion varchar(20) unique, email varchar(50));

create table Provincia(id int primary key auto_increment, nombre varchar(50));

create table Compania(id int primary key auto_increment, nombre varchar(50), lugar varchar(50));

create table Cliente (id int primary key auto_increment, id_persona int, id_compania int,  foreign key (id_persona) references Persona (id) on update cascade on delete cascade, foreign key (id_compania) references Compania (id) on update cascade on delete cascade);

create table Empleado (id int primary key auto_increment, id_persona int, sueldo double, horario timestamp, foreign key (id_persona) references Persona(id) on update cascade on delete cascade);

create table Institucion(
 id int primary key auto_increment,
 nombre varchar(50),
 id_provincia int,
 foreign key (id_provincia) references Provincia(id) on update cascade on delete cascade);

create table Servicio(
 id int primary key auto_increment,
 valor double,
 tipo enum('Servicio Basico','Television satelital','Pago Colegios','Prestamo'),
 descripcion varchar(150),
 id_institucion int,
 foreign key (id_institucion) references Institucion(id) on update cascade on delete cascade);

create table Pagos(
 id int primary key auto_increment,
 tipoPago enum ('Parcial','Total'),
 totalCuotas double,
 lugar varchar (50),
 valorRecargo enum('1%','5%','10%'),
 estadoPago enum('porVencer','Vencido'),
 fecha datetime default now(),
 id_empleado int,
 id_servicio int,
 id_cliente int,
 foreign key (id_empleado) references Empleado(id) on update cascade on delete cascade,
 foreign key (id_servicio)  references Servicio(id) on update cascade on delete cascade,
 foreign key (id_cliente)  references Cliente(id) on update cascade on delete cascade);

create table Cuota(
 id int primary key auto_increment,
 fechaPago datetime,
 fechaProximoPago datetime,
 id_pagos int,
 Recargo double,
 totalPagar double,
 estado boolean default false,
 foreign key (id_pagos) references Pagos(id) on update cascade on delete cascade);



