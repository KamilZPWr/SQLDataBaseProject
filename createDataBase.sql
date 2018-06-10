IF  EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = 'HoteleBaza')
	BEGIN
	DROP DATABASE HoteleBaza;
	END
GO

CREATE DATABASE HoteleBaza;
GO

USE HoteleBaza;
GO

CREATE TABLE Pañstwo (
  pa_id int identity(1,1) primary key,
  pa_pañstwo char(45),
 ) 

CREATE TABLE Miasto (
  mi_id int identity(1,1) primary key,
  mi_miasto varchar(45),
  mi_pa_id int,

  foreign key (mi_pa_id) references Pañstwo(pa_id) on delete cascade,
)

CREATE TABLE Standard_Hotelu(
  st_id int identity (1,1) primary key,
  st_rodzaj varchar(max),
) 

CREATE TABLE Hotele (
  ho_id int identity(1,1) primary key,
  ho_mi_id int,
  ho_hotel varchar(max),
  ho_st_id int,
  ho_pokoje_wolne int,

  foreign key (ho_mi_id) references Miasto(mi_id) on delete cascade,
  foreign key (ho_st_id) references Standard_Hotelu(st_id),
) 

CREATE TABLE Pokoje1 (
  po_id int identity(1,1) primary key,
  po_rodzaj  int,
  po_cena decimal(20,2),
  po_standard varchar(max),
) 

CREATE TABLE Wy¿ywienie(
  wy_id int identity (1,1) primary key,
  wy_typ varchar(max),
  wy_cena decimal(20,2),
  wy_dieta varchar(max)
)
  
CREATE TABLE Goœæ(
  go_id int identity (1,1) primary key,
  go_imie varchar(max),
  go_nazwisko varchar(max),
  go_pesel bigint unique,
  go_mail varchar(max),
)

CREATE TABLE Zamówienie(
  za_id int identity (1,1) primary key,
  za_go_id int,
  za_ho_id int,
  za_po_id int,
  za_wy_id int,
   
  foreign key (za_go_id) references Goœæ(go_id),
  foreign key (za_ho_id) references Hotele(ho_id) on delete cascade,
  foreign key (za_po_id) references Pokoje1(po_id),
  foreign key (za_wy_id) references Wy¿ywienie(wy_id),
)