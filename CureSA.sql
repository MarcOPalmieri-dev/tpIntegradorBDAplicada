--
---------------------------------------------------------------------------------------------------------------------
-----------------------------------                                        ------------------------------------------
----------------------------------            BASE DE DATOS APLICADA         ----------------------------------------
-----------------------------------                                        ------------------------------------------
---------------------------------------------------------------------------------------------------------------------
--    TRABAJO N� 3 Y 4                          ---------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
--    FECHA DE ENTREGA:                         ---------------------------------------------------------------------
--    NUMERO DE GRUPO:    15                    ---------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- INTEGRANTES                                  ---------------------------------------------------------------------

-- Palmieri Marco 45542385
-- Christian Rodr�guez 37947646
-- Facundo Toloza 40254191
-- Juan Alberto Bianchi 30475902

---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------




--CREACION DE BASE DE DATOS
create database CureSA
COLLATE Modern_Spanish_CI_AS
--Uso de este collate para admitir los acentos
go

use CureSA
go

--CREACI�N DE ESQUEMAS
CREATE SCHEMA Sistema; 
--Esquema para tablas
go 
CREATE SCHEMA Normalizacion; 
--Esquema para los stored procedure de carga de datos de archivos en las tablas
go 
CREATE SCHEMA ManejoDeDatos; 
--Esquema para los stored procedure para insertar, borrar y actualizar datos.
go



---------------CREACI�N DE LAS TABLAS CORRESPONDIENTES DEL SISTEMA,ENTIDADES Y RELACIONES.----------------------------------------------

CREATE TABLE Sistema.Domicilio
(
	id_domicilio INT IDENTITY(1,1) PRIMARY KEY,
	calle_y_numero VARCHAR(150),
	piso CHAR(3),
	departamento CHAR(3),
	codigo_postal CHAR(8),
	pais VARCHAR(15) DEFAULT('ARGENTINA'),
	provincia VARCHAR(30),
	localidad VARCHAR(50),
)
GO


create table Sistema.Paciente
(
	id_historia_clinica int identity (1,1) primary key,
	nombre varchar(30),
	apellido varchar(30),
	apellido_materno varchar(30),
	fecha_de_nacimiento date,
	tipo_documento char(10) not null,
	nro_documento char(9) not null,
	sexo_biologico char(10),
	genero char (10),
	nacionalidad varchar(20),
	foto_perfil varchar(30),
	telefono_fijo varchar(25),
	telefono_alternativo varchar(25),
	telefono_laboral varchar(25),
	mail varchar(40),
	fecha_registro smalldatetime,
	fecha_actualizacion smalldatetime,
	usuario_actualizacion varchar(30),
	id_domicilio INT,
	constraint chck_dni UNIQUE (tipo_documento, nro_documento),
	constraint fk_domicilio FOREIGN KEY (id_domicilio)
	references Sistema.Domicilio(id_domicilio)
)
go

create table Sistema.Usuario
(
	id_usuario int identity (1,1) primary key,
	contrase�a varchar(30) not null,
	fecha_creacion smalldatetime,
	id_historia_clinica int,
	foreign key (id_historia_clinica) references Sistema.paciente(id_historia_clinica),
)
go


create table Sistema.Estudio
(
	id_estudio int identity (1,1) primary key,
	fecha smalldatetime,
	nombre_estudio varchar(50),
	autorizado bit,
	documento_resultado varchar(30),
	imagen_resultado varchar(30),
	id_historia_clinica int,
	foreign key (id_historia_clinica) references Sistema.paciente(id_historia_clinica),
)
go


create table Sistema.Prestador
(
	id_prestador int identity (1,1) primary key,
	nombre_prestador varchar(30),
	plan_prestador varchar(30)
)
go

create table Sistema.Cobertura
(
	id_cobertura int identity (1,1) primary key,
	imagen_credencial varchar(30),
	nro_socio int unique not null,
	fecha_registro smalldatetime,
	id_historia_clinica int,
	id_prestador int,
	foreign key (id_historia_clinica) references sistema.paciente(id_historia_clinica),
	foreign key (id_prestador) references sistema.prestador(id_prestador),
)
go


create table Sistema.Estado_Turno 
( 
	id_estado_turno int identity (1,1) primary key, 
	nombre_estado char(10) not null,  
) 
go


create table Sistema.Tipo_Turno 
( 
	id_tipo_turno int identity (1,1) primary key, 
	nombre_tipo_turno char(10) not null,  
) 

go 


create table Sistema.Sede_Atencion 
( 
	id_sede int identity (1,1) primary key, 
	nombre_sede varchar(30) not null, 
	direccion_sede varchar(200) not null,  
) 
go 

create table Sistema.Especialidad 
( 
	id_especialidad int identity (1,1) primary key, 
	nombre_especialidad varchar(30) not null,  
) 
go 


create table Sistema.Medico
( 
	id_medico int identity (1,1) primary key, 
	nombre varchar(30) not null, 
	apellido varchar(30) not null, 
	numero_matricula int unique not null, 
	id_especialidad int not null references Sistema.Especialidad(id_especialidad), 
) 
go 


create table Sistema.DiasXsede 
( 
	id_sede int not null references Sistema.sede_atencion(id_sede), 
	id_medico int not null  references Sistema.medico(id_medico), 
	hora_inicio time not null, 
	dia date not null, 
	constraint pk_diasxsede primary key (id_sede,id_medico), 
) 
go 


create table Sistema.Reserva_Turno_Medico 
( 
	id_turno int identity (1,1) primary key, 
	fecha date not null, 
	hora time not null, 
	id_medico int not null references Sistema.Medico(id_medico), 
	id_direccion_atencion int not null references Sistema.Sede_Atencion(id_sede), 
	id_especialidad int not null references Sistema.Especialidad(id_especialidad), 
	id_estado_turno int not null references Sistema.Estado_Turno(id_estado_turno), 
	id_tipo_turno int not null references Sistema.Tipo_Turno(id_tipo_turno), 
	id_historia_clinica int not null references Sistema.Paciente(id_historia_clinica)
) 
go 

--Creaci�n de la tabla 'Autorizacion_Estudio' para importar los datos del JSON.
CREATE TABLE Sistema.Autorizacion_Estudio ( 
    ID_Estudio INT IDENTITY(1,1) PRIMARY KEY, 
    Area NVARCHAR(20), 
    Estudio NVARCHAR(100), 
    Prestador NVARCHAR(20), 
    PlanPaciente NVARCHAR(100), 
    PorcentajeCobertura INT, 
    Costo int, 
    RequiereAutorizacion BIT 
); 
GO


/*CREAMOS TABLAS TEMPORALES LLAMADAS "MAESTRAS" PARA REALIZAR UNA CARGA DIRECTA DE LOS DATOS DE LOS ARCHIVOS, 
PARA POSTERIORMENTE HACER EL PREPROCESADO CORRESPONIDENTE PARA LA LIMPIEZA DE LOS DATOS Y AS� PODER CARGARLOS EN LAS TABLAS DE LA BASE DE DATOS*/


CREATE TABLE #Maestra_pacientes (
	nombre varchar(30) COLLATE Modern_Spanish_CI_AS,
	apellido varchar(30) COLLATE Modern_Spanish_CI_AS,
	fecha_de_nacimiento date,
	tipo_documento char(10) COLLATE Modern_Spanish_CI_AS,
	nro_documento char(9) COLLATE Modern_Spanish_CI_AS,
	sexo_biologico char(10) COLLATE Modern_Spanish_CI_AS,
	genero char(10) COLLATE Modern_Spanish_CI_AS,
	telefono_fijo varchar(25) COLLATE Modern_Spanish_CI_AS,
	nacionalidad varchar(20) COLLATE Modern_Spanish_CI_AS,
	mail varchar(40) COLLATE Modern_Spanish_CI_AS,
	calle_y_numero varchar(100) COLLATE Modern_Spanish_CI_AS,
	localidad varchar(50) COLLATE Modern_Spanish_CI_AS,
	provincia varchar(30) COLLATE Modern_Spanish_CI_AS
)
GO

CREATE TABLE #Maestra_prestador (
	nombre_prestador varchar(30) COLLATE Modern_Spanish_CI_AS,
	plan_prestador varchar(30) COLLATE Modern_Spanish_CI_AS,
	vacio char(1) DEFAULT NULL
	-- (*1) Referencia de correci�n de error
)
GO


CREATE TABLE #Maestra_sedes (
	sede VARCHAR(30) COLLATE Modern_Spanish_CI_AS,
	direccion varchar(100) COLLATE Modern_Spanish_CI_AS,
	localidad varchar(50) COLLATE Modern_Spanish_CI_AS,
	provincia varchar(30) COLLATE Modern_Spanish_CI_AS,
)
GO


CREATE TABLE #Maestra_medicos(
nombre varchar(30) COLLATE Modern_Spanish_CI_AS,
apellidos varchar(30) COLLATE Modern_Spanish_CI_AS,
especialidad varchar(30) COLLATE Modern_Spanish_CI_AS,
numero_colegiado int
)
GO



--SENTENCIAS PARA INSERTAR LAS OPCIONES DE LAS TABLAS "ESTADO_TURNO" Y "TIPO_TURNO"
insert into Sistema.Estado_Turno (nombre_estado) values ('Atendido'), ('Pendiente'),('Ausente'),('Cancelado')

insert into Sistema.Tipo_Turno (nombre_tipo_turno) values ('Presencial'), ('Virtual')

GO


---------------------------CREACI�N DE STORED PROCEDURES PARA CARGAR LOS ARCHIVOS----------------------------------------------------------------

--SP para importar los archivos CSV
CREATE OR ALTER PROCEDURE Sistema.importarCSV 
@RutaArchivo VARCHAR(255),									-- La ruta completa del archivo CSV
@TablaDestino VARCHAR(50)									-- El nombre de la tabla de destino en tu base de datos
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE name LIKE  @TablaDestino + '[_]%')
    BEGIN
        PRINT N'[ERROR] - La tabla de destino no existe en la base de datos.';
        RETURN
    END
	BEGIN TRY												-- Inicio bloque try / catch para realizar la carga en la tabla temporal
		BEGIN TRANSACTION
			SET NOCOUNT ON;
			DECLARE @SQL VARCHAR(500);
			SET @SQL = 'BULK INSERT ' + @TablaDestino + '
						FROM ''' + @RutaArchivo + '''
						WITH (
							FIELDTERMINATOR = '';'',
							ROWTERMINATOR = ''\n'',
							FIRSTROW = 2,
							CODEPAGE = ''65001''				-- C�digo de p�gina de UTF-8
						);';
			EXEC (@SQL);
			PRINT('Carga de tabla temporal lista.');
			COMMIT
	END TRY
	BEGIN CATCH
		PRINT(N'[ERROR] - NO SE PUDO CARGAR LA TABLA!!!');
		PRINT ERROR_LINE() + ERROR_MESSAGE();
		ROLLBACK
	END CATCH
	SET NOCOUNT OFF;
END
GO


--SP para cargar datos en Tabla Prestador
CREATE OR ALTER PROCEDURE Normalizacion.cargarTablaPrestador AS
BEGIN
	EXEC Sistema.importarCSV 'C:\importar\Prestador.csv', '#Maestra_prestador' --RUTA ARCHIVO CSV
	BEGIN TRY
		SET NOCOUNT ON;
		BEGIN TRANSACTION
			DECLARE @RowCount INT;
			INSERT INTO Sistema.Prestador ( nombre_prestador, plan_prestador )
			(SELECT nombre_prestador, plan_prestador
			FROM #Maestra_prestador m 
			WHERE NOT EXISTS (
				SELECT 1 FROM Sistema.Prestador p
   			    WHERE p.nombre_prestador = m.nombre_prestador
			    AND p.plan_prestador = m.plan_prestador
				)
			);
			SET @RowCount = @@ROWCOUNT;
			PRINT 'Se han insertado ' + CAST(@RowCount AS VARCHAR) + ' nuevos prestadores.'
			PRINT 'Se ha completado la carga de datos de la siguiente tabla: - ''Sistema.Prestador'' -.'
			COMMIT
	END TRY
	BEGIN CATCH
		PRINT(N'[ERROR] - NO SE HAN PODIDO CARGAR DATOS A Sistema.Prestador');
		PRINT ERROR_LINE() + ERROR_MESSAGE();
		ROLLBACK
	END CATCH
	DROP TABLE #Maestra_prestador
	SET NOCOUNT OFF;
END
GO

--SP para cargar datos en Tabla Sedes
CREATE OR ALTER PROCEDURE Normalizacion.cargarTablaSedes AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON;
		BEGIN TRANSACTION
			EXEC Sistema.importarCSV 'C:\importar\Sedes.csv', '#Maestra_sedes' --RUTA ARCHIVO CSV
			DECLARE @RowCount INT;
			INSERT INTO Sistema.Sede_Atencion ( nombre_sede, direccion_sede )
			-- (*2) Referencia de correci�n de error
			(SELECT sede, CONCAT(direccion, ' - ', localidad, ' - ', provincia)
			FROM #Maestra_sedes m 
			WHERE NOT EXISTS (
				SELECT 1 FROM Sistema.Sede_Atencion s
   			    WHERE s.direccion_sede = CONCAT(direccion, ' - ', localidad, ' - ', provincia)
				)
			);
			SET @RowCount = @@ROWCOUNT;
			PRINT 'Se han insertado ' + CAST(@RowCount AS VARCHAR) + ' nuevas sedes.'
			PRINT 'Se ha completado la carga de datos de la siguiente tabla: - ''Sistema.Sede_Atencion'' -.' 
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		PRINT(N'[ERROR] - NO SE HAN PODIDO CARGAR DATOS A Sistema.Sedes');
		PRINT ERROR_LINE() + ERROR_MESSAGE();
	END CATCH
	DROP TABLE #Maestra_sedes
	SET NOCOUNT OFF;
END
GO

--SP para cargar datos en Tabla Especialidad y Medico
CREATE OR ALTER PROCEDURE Normalizacion.cargarMedicos_Especialidad AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON;
		BEGIN TRANSACTION
			EXEC Sistema.importarCSV 'C:\importar\Medicos.csv', '#Maestra_medicos' --RUTA ARCHIVO CSV

			--Inserto en Especialidad
			INSERT INTO Sistema.Especialidad ( nombre_especialidad )
			(
			SELECT DISTINCT especialidad FROM #Maestra_medicos m
			WHERE NOT EXISTS(
			SELECT 1 FROM Sistema.Especialidad s 
				WHERE s.nombre_especialidad = m.especialidad)
			);
			-- (*3) Referencia de correci�n de error

			DECLARE @RowCount INT;
			SET @RowCount = @@ROWCOUNT;
			PRINT 'Se han insertado ' + CAST(@RowCount AS VARCHAR) + ' nuevas especialidades.'
			PRINT 'Se ha completado la carga de datos de la siguiente tabla: - ''Sistema.Especialidad'' -.' 

			--Inserto o modifico en Medico
			INSERT INTO Sistema.Medico (nombre, apellido, numero_matricula, id_especialidad)
			SELECT m.nombre, m.apellidos, m.numero_colegiado, e.id_especialidad
			FROM #Maestra_medicos m
			INNER JOIN Sistema.Especialidad e ON m.especialidad = e.nombre_especialidad
			WHERE NOT EXISTS (
				SELECT 1
				FROM Sistema.Medico s
				WHERE s.numero_matricula = m.numero_colegiado
			);


			SET @RowCount = @@ROWCOUNT;
			PRINT 'Se han afectado ' + CAST(@RowCount AS VARCHAR) + ' registros.'
			PRINT 'Se ha completado la carga de datos de la siguiente tabla: - ''Sistema.Medico'' -.' 
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		PRINT(N'[ERROR] - NO SE HAN PODIDO CARGAR DATOS A Sistema.Medico');
		PRINT ERROR_LINE() + ERROR_MESSAGE();
	END CATCH
	DROP TABLE #Maestra_medicos
	SET NOCOUNT OFF;
END
GO

--SP para cargar datos en Tabla Domicilio y Paciente
CREATE OR ALTER PROCEDURE Normalizacion.cargarPacientes_Domicilio AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON;
		BEGIN TRANSACTION
			EXEC Sistema.importarCSV 'C:\importar\Pacientes.csv', '#Maestra_pacientes' --RUTA ARCHIVO CSV

			--Inserto en Domicilio
			INSERT INTO Sistema.Domicilio( calle_y_numero, provincia, localidad)
			-- (*4) Referencia de correci�n de error
			(SELECT DISTINCT calle_y_numero, provincia, localidad
			FROM #Maestra_pacientes m
			WHERE NOT EXISTS(
				SELECT 1 FROM Sistema.Domicilio s 
				WHERE s.calle_y_numero = m.calle_y_numero
				AND s.localidad = m.localidad
				AND s.provincia = m.provincia)
			);

			DECLARE @RowCount INT;
			SET @RowCount = @@ROWCOUNT;
			PRINT 'Se han insertado ' + CAST(@RowCount AS VARCHAR) + ' nuevos domicilios.'
			PRINT 'Se ha completado la carga de datos de la siguiente tabla: - ''Sistema.Domicilio'' -.'


			--Inserto o modifico en Pacientes
			INSERT INTO Sistema.Paciente(nombre, apellido, fecha_de_nacimiento, tipo_documento,
			nro_documento, sexo_biologico, genero, nacionalidad, telefono_fijo, mail, id_domicilio)
			SELECT nombre, apellido, fecha_de_nacimiento, tipo_documento,
			nro_documento, sexo_biologico, genero, nacionalidad, telefono_fijo, mail, d.id_domicilio
			FROM #Maestra_pacientes m
			INNER JOIN Sistema.Domicilio d ON m.calle_y_numero = d.calle_y_numero
			AND m.localidad = d.localidad
			AND m.provincia = d.provincia
			WHERE NOT EXISTS (
				SELECT 1
				FROM Sistema.Paciente s
				WHERE s.tipo_documento = m.tipo_documento
				AND s.nro_documento = m.nro_documento
			);

			--(A�ADIDO) Inserci�n de Pacientes en el sistema de usuarios
			insert into Sistema.Usuario (contrase�a,fecha_creacion,id_historia_clinica)
			select nro_documento,GETDATE(),id_historia_clinica
			from Sistema.Paciente

			SET @RowCount = @@ROWCOUNT;
			PRINT 'Se han insertado ' + CAST(@RowCount AS VARCHAR) + ' pacientes.'
			PRINT 'Se ha completado la carga de datos de la siguiente tabla: - ''Sistema.Paciente'' -.' 

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		PRINT(N'[ERROR] - NO SE HAN PODIDO COMPLETAR LA CARGA DE DATOS');
		PRINT ERROR_LINE() + ERROR_MESSAGE();
	END CATCH
	DROP TABLE #Maestra_pacientes
	SET NOCOUNT OFF;
END
GO

--Ejecuci�n de los SP
EXEC Normalizacion.cargarTablaPrestador;
GO
EXEC Normalizacion.cargarTablaSedes
GO
EXEC Normalizacion.cargarMedicos_Especialidad
GO
EXEC Normalizacion.cargarPacientes_Domicilio
GO

--Realizamos los select para comprobar las tablas con datos cargados
--(PRUEBA)
select * from Sistema.Paciente
select * from Sistema.Usuario


select * from Sistema.Medico
select * from Sistema.Paciente
select * from Sistema.Prestador
select * from Sistema.Domicilio
select * from Sistema.Especialidad
select * from Sistema.Tipo_Turno
select * from Sistema.Sede_Atencion
select * from Sistema.Autorizacion_Estudio
select * from Sistema.Estado_Turno
GO


----------PROCEDURES PARA MANEJAR LA INSERCI�N,MODIFICADO Y BORRADO DE LOS DATOS DE LAS TABLAS----------------------------------------

--MANEJO DE DATOS PARA PACIENTES

--Genero un procedure para insertar un nuevo paciente con su domicilio

CREATE OR ALTER PROCEDURE ManejoDeDatos.InsertarPacienteConDomicilio
(
    @nombre VARCHAR(30),
    @apellido VARCHAR(30),
    @apellido_materno VARCHAR(30),
    @fecha_de_nacimiento DATE,
    @tipo_documento CHAR(10),
    @nro_documento CHAR(9),
    @sexo_biologico CHAR(10),
    @genero CHAR(10),
    @nacionalidad VARCHAR(20),
    @foto_perfil VARCHAR(30),
    @telefono_fijo VARCHAR(25),
    @telefono_alternativo VARCHAR(25),
    @telefono_laboral VARCHAR(25),
    @mail VARCHAR(40),
    @calle_y_numero VARCHAR(150),
    @piso CHAR(3),
    @departamento CHAR(3),
    @codigo_postal CHAR(8),
    @pais VARCHAR(15),
    @provincia VARCHAR(30),
    @localidad VARCHAR(50)
)
AS
BEGIN
    DECLARE @id_domicilio INT
	DECLARE @id_hclinica int

	BEGIN TRY
		BEGIN TRANSACTION
			SET NOCOUNT ON;
			DECLARE @RowCount INT;

			-- Insertar primero en la tabla Sistema.Domicilio
			INSERT INTO Sistema.Domicilio
			(
				calle_y_numero, piso, departamento, codigo_postal, pais, provincia, localidad
			)
			SELECT @calle_y_numero, @piso, @departamento, @codigo_postal, @pais, @provincia, @localidad
			WHERE NOT EXISTS
			( SELECT 1 FROM Sistema.Domicilio WHERE calle_y_numero = @calle_y_numero
			  AND piso = @piso
			  AND departamento = @departamento AND codigo_postal = @codigo_postal
			  AND pais = @pais AND provincia = provincia AND localidad = @localidad
			)
							

			SET @RowCount = @@ROWCOUNT;
			IF @RowCount = 0
			BEGIN
				PRINT 'Domicilio ya registrado, no se insertar� uno nuevo.'
				SET @id_domicilio = ( SELECT id_domicilio FROM Sistema.Domicilio WHERE calle_y_numero = @calle_y_numero
									  AND piso = @piso AND departamento = @departamento AND codigo_postal = @codigo_postal
									  AND pais = @pais AND provincia = provincia AND localidad = @localidad )
			END
			ELSE BEGIN
				PRINT 'Se ha insertado ' + CAST(@RowCount AS VARCHAR) + ' domicilio.'
				PRINT 'Se ha completado la inserci�n de datos de la siguiente tabla: - ''Sistema.Domicilio'' -.' 
				-- Obtener el ID reci�n insertado en Sistema.Domicilio
				SET @id_domicilio = SCOPE_IDENTITY()
			END
			

			-- Insertar en la tabla Sistema.Paciente utilizando el ID de domicilio obtenido
			INSERT INTO Sistema.Paciente
			(
				nombre, apellido, apellido_materno, fecha_de_nacimiento, tipo_documento,
				nro_documento, sexo_biologico, genero, nacionalidad, foto_perfil,
				telefono_fijo, telefono_alternativo, telefono_laboral, mail,
				fecha_registro, fecha_actualizacion, usuario_actualizacion, id_domicilio
			)
			VALUES
			(
				@nombre, @apellido, @apellido_materno, @fecha_de_nacimiento, @tipo_documento,
				@nro_documento, @sexo_biologico, @genero, @nacionalidad, @foto_perfil,
				@telefono_fijo, @telefono_alternativo, @telefono_laboral, @mail,
				GETDATE(), GETDATE(), '', @id_domicilio
			)

			SET @RowCount = @@ROWCOUNT;
			PRINT 'Se ha insertado ' + CAST(@RowCount AS VARCHAR) + ' paciente.'
			PRINT 'Se ha completado la inserci�n de datos de la siguiente tabla: - ''Sistema.Paciente'' -.'

			-----PROPUESTA PARA NO USAR CURSORES (MODIFICADO)
			set @id_hclinica = SCOPE_IDENTITY()

			insert into Sistema.Usuario (contrase�a,fecha_creacion,id_historia_clinica) values (@nro_documento,GETDATE(),@id_hclinica)

			SET @RowCount = @@ROWCOUNT;
			PRINT 'Se ha insertado ' + CAST(@RowCount AS VARCHAR) + ' usuario.'
			PRINT 'Se ha completado la carga de datos de la siguiente tabla: - ''Sistema.Usuario'' -.' 
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		PRINT(N'[ERROR] - NO SE HAN PODIDO COMPLETAR LA INSERCION DEL PACIENTE / USUARIO Y SU DOMICILIO');
		PRINT ERROR_LINE() + ERROR_MESSAGE();
	END CATCH
	SET NOCOUNT OFF
END
GO



	--Ejemplo de insercion
	EXEC ManejoDeDatos.InsertarPacienteConDomicilio
    @nombre = 'Juan',
    @apellido = 'P�rez',
    @apellido_materno = 'G�mez',
    @fecha_de_nacimiento = '1988-03-15',
    @tipo_documento = 'DNI',
    @nro_documento = '98765431',
    @sexo_biologico = 'Masculino',
    @genero = 'Hombre',
    @nacionalidad = 'Argentino',
    @foto_perfil = 'juan.jpg',
    @telefono_fijo = '011-2222-3333',
    @telefono_alternativo = '011-4444-5555',
    @telefono_laboral = '011-6666-7777',
    @mail = 'juan.perez@example.com',
    @calle_y_numero = 'Calle Principal 100',
    @piso = '1',
    @departamento = 'A',
    @codigo_postal = '12345',
    @pais = 'Argentina',
    @provincia = 'Buenos Aires',
    @localidad = 'La Plata'
GO

--Realizamos los select correspondientes.
select * from Sistema.Paciente
select * from Sistema.Domicilio
select * from Sistema.Usuario
GO	
--Genero un procedure para modificar algunos datos de los pacientes, en este caso solo dejo modificar los telefonos,el mail y el domicilio.

CREATE OR ALTER PROCEDURE ManejoDeDatos.ModificarDatosPaciente
(
    @id_historia_clinica INT,
    @telefono_fijo VARCHAR(25) = NULL,
    @telefono_alternativo VARCHAR(25) = NULL,
    @telefono_laboral VARCHAR(25) = NULL,
    @mail VARCHAR(40) = NULL,
    @calle_y_numero VARCHAR(150) = NULL,
    @piso CHAR(3) = NULL,
    @departamento CHAR(3) = NULL,
    @codigo_postal CHAR(8) = NULL,
    @pais VARCHAR(15) = NULL,
    @provincia VARCHAR(30) = NULL,
    @localidad VARCHAR(50) = NULL
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			SET NOCOUNT ON
			-- Actualizar el domicilio solo si se proporcionan valores
			IF @calle_y_numero IS NOT NULL
			BEGIN
				-- Verificar si el domicilio ya existe en la tabla Sistema.Domicilio
				DECLARE @id_domicilio INT
				SELECT @id_domicilio = id_domicilio
				FROM Sistema.Domicilio
				WHERE
					calle_y_numero = ISNULL(@calle_y_numero, calle_y_numero)
					AND piso = ISNULL(@piso, piso)
					AND departamento = ISNULL(@departamento, departamento)
					AND codigo_postal = ISNULL(@codigo_postal, codigo_postal)
					AND pais = ISNULL(@pais, pais)
					AND provincia = ISNULL(@provincia, provincia)
					AND localidad = ISNULL(@localidad, localidad)

				-- Si el domicilio no existe, insertarlo en la tabla Sistema.Domicilio
				IF @id_domicilio IS NULL
				BEGIN
					INSERT INTO Sistema.Domicilio
					(
						calle_y_numero, piso, departamento, codigo_postal, pais, provincia, localidad
					)
					VALUES
					(
						@calle_y_numero, @piso, @departamento, @codigo_postal, @pais, @provincia, @localidad
					)

					-- Obtener el ID reci�n insertado en Sistema.Domicilio
					SELECT @id_domicilio = SCOPE_IDENTITY()
				END

				-- Actualizar el ID de domicilio en la tabla Sistema.Paciente
				UPDATE Sistema.Paciente
				SET
					id_domicilio = @id_domicilio
				WHERE
					id_historia_clinica = @id_historia_clinica
			END

			-- Actualizar los campos de tel�fono y correo electr�nico del paciente
			UPDATE Sistema.Paciente
			SET
				telefono_fijo = ISNULL(@telefono_fijo, telefono_fijo),
				telefono_alternativo = ISNULL(@telefono_alternativo, telefono_alternativo),
				telefono_laboral = ISNULL(@telefono_laboral, telefono_laboral),
				mail = ISNULL(@mail, mail)
			WHERE
				id_historia_clinica = @id_historia_clinica
		COMMIT TRANSACTION
		PRINT 'Se ha completado la actualizaci�n de las siguientes tablas: - ''Sistema.Paciente'' - - ''Sistema.Domicilio'' -.';
	END TRY
	BEGIN CATCH 
		ROLLBACK TRANSACTION
		PRINT(N'[ERROR] - NO SE HAN PODIDO COMPLETAR LA ACTUALIZACION DEL PACIENTE / USUARIO Y SU DOMICILIO');
		PRINT ERROR_LINE() + ERROR_MESSAGE();
	END CATCH
	SET NOCOUNT OFF
END
GO


--Ejemplo para modificar los datos del Paciente antes insertados

EXEC ManejoDeDatos.ModificarDatosPaciente
@id_historia_clinica = 1,   --Aca indico el numero de la historia clinica del paciente a modificar
@telefono_fijo = '011-8888-8888', -- Nuevo n�mero de tel�fono fijo
@mail = 'juan.perez.nuevo@yahoo.com', -- Nuevo correo electr�nico
@calle_y_numero = 'Nueva Calle 200', -- Nuevo domicilio
@piso = '2',
@departamento = 'B',
@codigo_postal = '54321',
@pais = 'Argentina',
@provincia = 'Buenos Aires',
@localidad = 'La Plata'
GO

select * from Sistema.Paciente 
select * from Sistema.Domicilio
GO


--Procedure para eliminar pacientes

CREATE OR ALTER PROCEDURE ManejoDeDatos.EliminarPaciente
(
    @id_historia_clinica INT
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			SET NOCOUNT ON
			DECLARE @RowCount INT;
			--Elimino el usuario (MODFICIADO)
			delete from sistema.Usuario WHERE id_historia_clinica = @id_historia_clinica
			SET @RowCount = @@ROWCOUNT;
			IF @RowCount > 0
				PRINT 'Se ha completado la eliminacion del registro de la siguiente tabla: - ''Sistema.Usuario'' -.'

			-- Eliminar al paciente de la tabla Sistema.Paciente
			DELETE FROM Sistema.Paciente
			WHERE id_historia_clinica = @id_historia_clinica
			SET @RowCount = @@ROWCOUNT;
			IF @RowCount > 0
				PRINT 'Se ha completado la eliminacion del registro de la siguiente tabla: - ''Sistema.Paciente'' -.'

			-- Elimino el domicilio si ya no est� asociado a ning�n paciente
			DELETE FROM Sistema.Domicilio
			WHERE id_domicilio NOT IN (SELECT id_domicilio FROM Sistema.Paciente)
			SET @RowCount = @@ROWCOUNT;
			IF @RowCount > 0
				PRINT 'Se ha completado la eliminacion del registro de la siguiente tabla: - ''Sistema.Domicilio'' -.'
			
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		PRINT(N'[ERROR] - NO SE HAN PODIDO COMPLETAR LA ELIMINACION DEL PACIENTE / USUARIO Y SU DOMICILIO');
		PRINT ERROR_LINE() + ERROR_MESSAGE();
	END CATCH
	SET NOCOUNT OFF
END
GO

	--Ejemplo de ejecucion 

EXEC ManejoDeDatos.EliminarPaciente
@id_historia_clinica = 5   --Aca indico el numero de la historia clinica del paciente a modificar
GO
select * from Sistema.Usuario
select * from Sistema.Paciente 
select * from Sistema.Domicilio
GO

--MANEJO DE DATOS PARA USUARIOS

select * from Sistema.Usuario
select * from Sistema.Paciente
GO
--Genero procedure para cambiar la contrase�a del Usuario 

CREATE OR ALTER PROCEDURE ManejoDeDatos.CambiarContrase�aUsuario
(
    @id_usuario INT,
    @nueva_contrase�a VARCHAR(30)
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			SET NOCOUNT ON
			DECLARE @RowCount INT;
			-- Actualizar la contrase�a del usuario
			UPDATE Sistema.Usuario
			SET
				contrase�a = @nueva_contrase�a
			WHERE
				id_usuario = @id_usuario

			SET @RowCount = @@ROWCOUNT;
			IF @RowCount > 0
				PRINT 'Se ha completado la actualizaci�n en la contrase�a en la siguiente tabla: - ''Sistema.Usuario'' -.'
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		PRINT(N'[ERROR] - NO SE HAN PODIDO COMPLETAR LA MODIFICACI�N DE LA CONTRASE�A');
		PRINT ERROR_LINE() + ERROR_MESSAGE();
	END CATCH
	SET NOCOUNT OFF
END
GO

--- Ejemplo de ejecucion para el cambio de contrase�a del usuario
	
	
EXEC ManejoDeDatos.CambiarContrase�aUsuario
@id_usuario = 1, -- ID del usuario que quiere modificar la contrase�a
@nueva_contrase�a = 'contrase�a' -- Nueva contrase�a
GO

select * from Sistema.Usuario
GO
	


--Genero procedure para agregar prestadores

CREATE OR ALTER PROCEDURE ManejoDeDatos.InsertarPrestador
(
    @nombre_prestador VARCHAR(30),
    @plan_prestador VARCHAR(30)
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			SET NOCOUNT ON;
			DECLARE @RowCount INT;

			INSERT INTO Sistema.Prestador (nombre_prestador, plan_prestador)
			SELECT @nombre_prestador, @plan_prestador 
			WHERE NOT EXISTS 
			( SELECT 1 FROM Sistema.Prestador WHERE @nombre_prestador = nombre_prestador
			  AND @plan_prestador = plan_prestador )

			SET @RowCount = @@ROWCOUNT;
			IF @RowCount > 0 
				PRINT 'Se ha completado la inserci�n en la siguiente tabla: - ''Sistema.Prestador'' -.'
			ELSE
				PRINT 'El prestador ya se encuentra ingresado en el sistema.'
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		PRINT(N'[ERROR] - NO SE HAN PODIDO COMPLETAR LA INSERCI�N DEL PRESTADOR');
		PRINT ERROR_LINE() + ERROR_MESSAGE();
	END CATCH
	SET NOCOUNT OFF
END
GO


-- Ejemplo para insertar un nuevo prestador
EXEC ManejoDeDatos.InsertarPrestador
@nombre_prestador = 'Nombre Prestador',
@plan_prestador = 'Plan'
GO


select * from Sistema.Prestador
GO


--Procedure para eliminar Prestadores
CREATE OR ALTER PROCEDURE ManejoDeDatos.EliminarPrestador
(
    @nombre_prestador VARCHAR(30) = NULL,
    @plan_prestador VARCHAR(30) = NULL,
	@id_prestador int = NULL
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			SET NOCOUNT ON;
			DECLARE @RowCount INT;

			DELETE FROM Sistema.Prestador
			WHERE nombre_prestador = @nombre_prestador and plan_prestador = @plan_prestador
			or id_prestador = @id_prestador

			SET @RowCount = @@ROWCOUNT;
			IF @RowCount > 0 
				PRINT 'Se ha completado la eliminaci�n en la siguiente tabla: - ''Sistema.Prestador'' -.'
			ELSE
				PRINT 'El prestador no se encuentra ingresado en el sistema.'
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		PRINT(N'[ERROR] - NO SE HAN PODIDO COMPLETAR LA ELIMINACI�N DEL PRESTADOR');
		PRINT ERROR_LINE() + ERROR_MESSAGE();
	END CATCH
	SET NOCOUNT OFF
END
GO

EXEC ManejoDeDatos.EliminarPrestador
@id_prestador = 21
GO


--Genero un procedure para Especialidades Medicas
CREATE OR ALTER PROCEDURE ManejoDeDatos.AgregarEspecialidad
(
    @nombre_especialidad VARCHAR(30)
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			SET NOCOUNT ON;
			DECLARE @RowCount INT;

			INSERT INTO Sistema.Especialidad (nombre_especialidad)
			SELECT @nombre_especialidad WHERE NOT EXISTS
			( SELECT 1 FROM Sistema.Especialidad WHERE @nombre_especialidad = nombre_especialidad )

			SET @RowCount = @@ROWCOUNT;
			IF @RowCount > 0 
				PRINT 'Se ha completado la inserci�n en la siguiente tabla: - ''Sistema.Especialidad'' -.'
			ELSE
				PRINT 'La especialidad ya se encuentra ingresada en el sistema.'
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		PRINT(N'[ERROR] - NO SE HAN PODIDO COMPLETAR LA INSERCI�N DE LA ESPECIALIDAD');
		PRINT ERROR_LINE() + ERROR_MESSAGE();
	END CATCH
	SET NOCOUNT OFF
END
GO

--Ejemplo 

EXEC ManejoDeDatos.AgregarEspecialidad
    @nombre_especialidad = 'CARDIOLOG�A'  -- nombre de la especialidad
GO

select * from Sistema.Especialidad
GO


--Genero procedure para eliminar especialidades medicas

CREATE OR ALTER PROCEDURE ManejoDeDatos.EliminarEspecialidad
(
    @id_especialidad INT
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			SET NOCOUNT ON;
			DECLARE @RowCount INT;

			DELETE FROM Sistema.Especialidad
			WHERE id_especialidad = @id_especialidad

			SET @RowCount = @@ROWCOUNT;
			IF @RowCount > 0 
				PRINT 'Se ha completado la eliminaci�n en la siguiente tabla: - ''Sistema.Especialidad'' -.'
			ELSE
				PRINT 'La especialidad no se encuentra ingresada en el sistema.'
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		PRINT(N'[ERROR] - NO SE HAN PODIDO COMPLETAR LA ELIMINACI�N DE LA ESPECIALIDAD');
		PRINT ERROR_LINE() + ERROR_MESSAGE();
	END CATCH
	SET NOCOUNT OFF
END
GO
	--Ejemplo de ejecucion

EXEC ManejoDeDatos.EliminarEspecialidad
    @id_especialidad = 18
GO

select * from Sistema.Especialidad
GO


--Genero un procedure para insertar Medicos

CREATE OR ALTER PROCEDURE ManejoDeDatos.InsertarMedico
(
    @nombre VARCHAR(30),
    @apellido VARCHAR(30),
    @numero_matricula INT,
    @id_especialidad INT
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			SET NOCOUNT ON;
			DECLARE @RowCount INT;

			INSERT INTO Sistema.Medico (nombre, apellido, numero_matricula, id_especialidad)
			SELECT @nombre, @apellido, @numero_matricula, @id_especialidad WHERE NOT EXISTS
			( SELECT 1 FROM Sistema.Medico WHERE @numero_matricula = numero_matricula )

			SET @RowCount = @@ROWCOUNT;
			IF @RowCount > 0 
				PRINT 'Se ha completado la inserci�n en la siguiente tabla: - ''Sistema.Medico'' -.'
			ELSE
				PRINT 'Ya existe un medico con ese numero de matr�cula. Por favor verifique los datos y en caso de corresponder, realice un update.'
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		PRINT(N'[ERROR] - NO SE HAN PODIDO COMPLETAR LA INSERCI�N DEL MEDICO');
		PRINT ERROR_LINE() + ERROR_MESSAGE();
	END CATCH
	SET NOCOUNT OFF
END
GO


-- Ejemplo de ejecucion para insertar un nuevo m�dico
EXEC ManejoDeDatos.InsertarMedico
@nombre = 'Juan',
@apellido = 'P�rez',
@numero_matricula = 12345,
@id_especialidad = 1  -- ID de la especialidad
GO

SELECT * FROM Sistema.Medico
GO


--Genero un procedure para modificar Medicos

CREATE OR ALTER PROCEDURE ManejoDeDatos.ModificarMedico
(
	@id INT,
    @nombre VARCHAR(30),
    @apellido VARCHAR(30),
    @numero_matricula INT,
    @id_especialidad INT
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			SET NOCOUNT ON;
			DECLARE @RowCount INT;

			UPDATE Sistema.Medico 
			SET nombre = @nombre, apellido = @apellido, 
			numero_matricula = @numero_matricula, id_especialidad = @id_especialidad
			WHERE @id = id_medico;

			SET @RowCount = @@ROWCOUNT;
			IF @RowCount > 0 
				PRINT 'Se ha completado la modificaci�n en la siguiente tabla: - ''Sistema.Medico'' -.'
			ELSE
				PRINT 'No existe un medico con ese numero de matr�cula. Por favor verifique los datos.'
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		PRINT(N'[ERROR] - NO SE HAN PODIDO COMPLETAR LA INSERCI�N DEL MEDICO');
		PRINT ERROR_LINE() + ERROR_MESSAGE();
	END CATCH
	SET NOCOUNT OFF
END
GO


-- Ejemplo de ejecucion para modificar un nuevo m�dico
EXEC ManejoDeDatos.ModificarMedico
@id = 2,
@nombre = 'Juan',
@apellido = 'P�rez',
@numero_matricula = 123456,
@id_especialidad = 1  -- ID de la especialidad
GO

SELECT * FROM Sistema.Medico
GO


--Genero un procedure para eliminar Medicos

CREATE OR ALTER PROCEDURE ManejoDeDatos.EliminarMedico
(
    @id_medico INT
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			SET NOCOUNT ON;
			DECLARE @RowCount INT;

			DELETE FROM Sistema.Medico
			WHERE id_medico = @id_medico

			SET @RowCount = @@ROWCOUNT;
			IF @RowCount > 0 
				PRINT 'Se ha completado la eliminaci�n en la siguiente tabla: - ''Sistema.Medico'' -.'
			ELSE
				PRINT 'El medico no se encuentra ingresado en el sistema.'
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		PRINT(N'[ERROR] - NO SE HAN PODIDO COMPLETAR LA ELIMINACI�N DEL MEDICO');
		PRINT ERROR_LINE() + ERROR_MESSAGE();
	END CATCH
	SET NOCOUNT OFF
END
GO

-- Ejemplo de eliminar un m�dico por su ID
	
EXEC ManejoDeDatos.EliminarMedico
 @id_medico = 2  -- ID del m�dico a eliminar
GO

SELECT * FROM Sistema.Medico
GO



--------------------CREACI�N DE SP PARA GENERAR ARCHIVO XML CON LOS TURNOS DE LAS FECHAS SELECCIONADAS-------------------------------
CREATE or ALTER PROCEDURE Sistema.generarArchivoXml @fecha_inicio date, @fecha_fin date 
AS BEGIN 

    select Turno.id_turno as ID, 
	Paciente.apellido 'Paciente/Apellido',Paciente.nombre as 'Paciente/Nombre',Paciente.nro_documento as 'Paciente/DNI', 
	Medico.apellido as 'Medico/Apellido',Medico.nombre as 'Medico/Nombre',Medico.numero_matricula as 'Medico/Matricula', 
	Turno.fecha as 'Turno/Fecha',Turno.hora as 'Turno/Hora', 
	Especialidad.nombre_especialidad as Especialidad 
	from Sistema.reserva_turno_medico Turno 
	inner join Sistema.Paciente Paciente on Turno.id_historia_clinica = Paciente.id_historia_clinica 
	inner join Sistema.Medico Medico on Turno.id_medico = Medico.id_medico 
	inner join Sistema.Especialidad Especialidad on Turno.id_especialidad = Especialidad.id_especialidad 
	where Turno.id_estado_turno = 1 and Turno.fecha between @fecha_inicio and @fecha_fin  
	for xml path ('Turno'), root('Turnos'), ELEMENTS 
END 
GO

--Ejecuci�n de prueba
exec Sistema.generarArchivoXml @fecha_inicio = '2023-10-01', @fecha_fin = '2023-10-08';
GO

-----------------------IMPORTACI�N DE LOS DATOS DEL ARCHIVO 'CONFIGURACION.JSON'-------------------------------------------

--Creaci�n del SP para importar los datos del JSON. 
CREATE OR ALTER PROCEDURE Sistema.InsertarDatosDesdeJSON 
AS 
BEGIN 
    BEGIN TRY 
        DECLARE @json NVARCHAR(MAX) 
        BEGIN TRANSACTION; 

		CREATE TABLE #datosJSON (COL NVARCHAR(MAX))
	
		DECLARE @BULK_INSERT_QUERY AS NVARCHAR(MAX) 
		, @ilog AS VARCHAR(250)
		, @registrosAniadidos as SMALLINT;
	
		-- Insertar valores del csv en la tabla temporal
		SET @BULK_INSERT_QUERY = N'BULK INSERT #datosJSON FROM ''C:\importar\Centro_Autorizaciones.Estudios clinicos.json'' WITH ( CODEPAGE = ''65001'')'

		-- Importar datos a la tabla temporal
		EXEC sp_sqlexec @BULK_INSERT_QUERY;

		-- Insertar datos transformados a la tabla correspondiente.
		WITH datos (area,estudio,prestador,pl,cob,costo,autor) as (
		SELECT area, estudio, UPPER(prestador)
			,	TRIM(CASE
					WHEN CHARINDEX(UPPER(prestador),UPPER([Plan]),0) = 0 THEN [plan]
					ELSE SUBSTRING([plan],0,CHARINDEX(UPPER(prestador),UPPER([Plan]),0)) + SUBSTRING([plan],CHARINDEX(UPPER(prestador),UPPER([Plan]),0)+LEN(prestador) + 1,50)
				END)
			,	cob, costo, autor
		FROM #datosJSON
		CROSS APPLY OPENJSON(COL) with(
			AREA  VARCHAR(50) '$.Area',
			ESTUDIO NVARCHAR(100) '$.Estudio',
			PRESTADOR NVARCHAR(50) '$.Prestador',
			[PLAN] VARCHAR(50) '$.Plan',
			COB INT '$."Porcentaje Cobertura"',
			COSTO INT '$.Costo',
			autor BIT '$."Requiere autorizacion"'
		) as book 
		WHERE AREA IS NOT NULL)
        INSERT INTO Sistema.Autorizacion_Estudio (Area, Estudio, Prestador, PlanPaciente, PorcentajeCobertura, Costo, RequiereAutorizacion) 
        SELECT area, estudio, prestador, pl, cob, costo, autor
		FROM datos; 
        COMMIT; 
    END TRY 
    BEGIN CATCH 
        ROLLBACK; 
		PRINT(N'[ERROR] - NO SE HAN PODIDO COMPLETAR LA CARGA DE DATOS'); 
		PRINT ERROR_LINE() + ERROR_MESSAGE(); 
        THROW; 
    END CATCH; 
END; 

GO

--Ejecuci�n de prueba 
exec Sistema.InsertarDatosDesdeJSON
GO