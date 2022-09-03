use hades;

drop procedure if exists pa_GenerarCuotas;

delimiter //
create procedure pa_GenerarCuotas(
	in cedula varchar(10),
    in idPago int,
    in numeroMeses int)
begin
	declare _mensaje varchar (100);
	declare _cliente int;
    declare _pago int;
    declare _pagoRecargo int;
    declare _monto int;
    declare _x int;
    set _x = 0;
	set _mensaje = "hola";
    select Cliente.id into _cliente from Cliente inner join Persona on Cliente.id_persona = Persona.id where Persona.identificacion = cedula;
	select Pagos.id, Pagos.valorRecargo, Pagos.monto into _pago, _recargo, _monto from Pagos where id = idPago;
    
    if numeroMeses = 1 then
		insert into Cuota(fechaPago, fechaProximoPago, id_pagos, recargo, totalPagar, estado) values (
        null,
        date_add(curdate(), interval 1 month),
        _pago, );
    else
    	loop_label: LOOP
		IF _x = numeroMeses THEN
			LEAVE loop_label;
		END IF;
        

		SET _x = _x + 1;
		ITERATE loop_label;
		END LOOP;
    end if;
    

end //
delimiter :

call pa_GenerarCuotas('1111111111', 5, 2);