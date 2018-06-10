use gwiazdy

IF  EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = 'HoteleBaza')
	BEGIN
	DROP DATABASE HoteleBaza;
	END
GO

CREATE DATABASE HoteleBaza;
GO

USE HoteleBaza;
GO

CREATE TABLE Pa�stwo (
  pa_id int identity(1,1) primary key,
  pa_pa�stwo char(45),
 ) 

CREATE TABLE Miasto (
  mi_id int identity(1,1) primary key,
  mi_miasto varchar(45),
  mi_pa_id int,

  foreign key (mi_pa_id) references Pa�stwo(pa_id) on delete cascade,
)

CREATE TABLE Standard_Hotelu(
  st_id int identity (1,1) primary key,
  st_rodzaj varchar(max),
  mno�nik numeric(5,2) 
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

CREATE TABLE Wy�ywienie(
  wy_id int identity (1,1) primary key,
  wy_typ varchar(max),
  wy_cena decimal(20,2),
  wy_dieta varchar(max)
)
  
CREATE TABLE Go��(
  go_id int identity (1,1) primary key,
  go_imie varchar(max),
  go_nazwisko varchar(max),
  go_pesel bigint unique,
  go_mail varchar(max),
)

CREATE TABLE Zam�wienie(
  za_id int identity (1,1) primary key,
  za_go_id int,
  za_ho_id int,
  za_po_id int,
  za_wy_id int,
  za_data_rezerwacji DATE
   
  foreign key (za_go_id) references Go��(go_id),
  foreign key (za_ho_id) references Hotele(ho_id) on delete cascade,
  foreign key (za_po_id) references Pokoje1(po_id),
  foreign key (za_wy_id) references Wy�ywienie(wy_id),
)

-- 1 --
-- napisz funkcj�, kt�ra jako argument pobiera kraj,
-- a zwaraca wszytskie hotele, ktore si� w nim znajduj�
CREATE FUNCTION podajHoteleWKraju(@kraj VARCHAR(max))
RETURNS table 
AS
RETURN( SELECT ho_hotel AS Hotel FROM Hotele WHERE ho_mi_id IN (
	SELECT mi_id FROM Miasto WHERE mi_pa_id IN (
		SELECT pa_id FROM Pa�stwo WHERE pa_pa�stwo = @kraj)))


drop function podajHoteleWKraju
select * from podajHoteleWKraju('W�ochy')

-- 2 -- 
-- napisz procedur�, kt�ra jako argument pobiera pesel go�cia,
-- a w zmiennej zewn�trznej zwraca ��czn� cen� za wy�ywienie i pok�j ostatniej jego rezerwacji
-- cene pokoju, trzeba przemno�y� przez mno�nik 

CREATE PROCEDURE pobierzKosztyGo�cia
@PESEL BIGINT,
@koszty DECIMAL(20,2) OUTPUT
AS 
BEGIN
DECLARE @mnoznik NUMERIC(5,2), @cenaWyzywienia DECIMAL(20,2), @cenaPokoju DECIMAL(20,2), @hotel INT, @pok�j INT, @wy�ywienie INT
SELECT TOP 1
	@hotel = za_ho_id,  
	@pok�j = za_po_id,
	@wy�ywienie = za_wy_id
FROM Zam�wienie 
WHERE za_go_id = (SELECT go_id FROM Go�� WHERE go_pesel = @PESEL)
ORDER BY za_data_rezerwacji DESC

SELECT @mnoznik = mno�nik FROM Standard_Hotelu WHERE st_id = (SELECT ho_st_id FROM Hotele WHERE ho_id = @hotel)
SELECT @cenaWyzywienia = wy_cena FROM Wy�ywienie WHERE wy_id = @wy�ywienie
SELECT @cenaPokoju = po_cena FROM Pokoje1 WHERE po_id = @pok�j 
SET @koszty = @cenaPokoju * @mnoznik + @cenaWyzywienia
END;

drop procedure pobierzKosztyGo�cia

GO
DECLARE @PESEL INT, @dataRezerwacji DATE, @koszty DECIMAL(20,2)
SET @PESEL = '999982372'
EXEC pobierzKosztyGo�cia @PESEL, @koszty output
SELECT @PESEL AS Go��, @koszty AS Koszty_wyjazdu

select * FROM Go��

-- 3 -- 
-- napisz triger, kt�ry po usuni�ciu go�cia, usunie jego zam�wienie
CREATE TRIGGER usunGoscia ON Go��
INSTEAD OF DELETE
AS
BEGIN
DECLARE @go�� INT 
SELECT @go�� = go_id FROM deleted
DELETE FROM Zam�wienie WHERE za_go_id = @go��
DELETE FROM Go�� WHERE go_id = @go��
END

select * from Go��
select * from Zam�wienie

DELETE FROM Go�� WHERE go_pesel = '123333453'

-- 4 --
-- napisz trigger, kt�ry po dodaniu zam�wienie na pok�j, 
-- usunie jeden pok�j z wolnych miejsc

CREATE TRIGGER usunWolnyPokoj ON Zam�wienie
AFTER INSERT
AS
BEGIN
DECLARE @hotel INT, @liczbaMiejsc INT
SELECT @hotel = za_ho_id FROM inserted
SELECT @liczbaMiejsc = ho_pokoje_wolne FROM Hotele WHERE ho_id = @hotel
UPDATE Hotele SET ho_pokoje_wolne = @liczbaMiejsc - 1 WHERE ho_id = @hotel
END

select * from Hotele
select * from Zam�wienie

-- 5 --
-- napisz procedur�, kt�ra jako argument pobiera imi� i nazwisko go�cia, 
-- a zwraca miasto i kraj, w kt�rych by� / b�dzie go��

CREATE PROCEDURE gdzieBy�B�dzieGo��
@imie VARCHAR(max),
@nazwisko VARCHAR(max),
@kraj VARCHAR(max) output,
@miasto VARCHAR(max) output
AS 
BEGIN
DECLARE @hotelId INT, @goscId INT, @miastoId INT, @krajId INT
SELECT @goscId = go_id FROM Go�� WHERE go_imie = @imie AND go_nazwisko = @nazwisko
SELECT @hotelId = za_ho_id FROM Zam�wienie WHERE za_go_id = @goscId
SELECT @miastoId = ho_mi_id FROM Hotele WHERE ho_id = @hotelId
SELECT @krajId = mi_pa_id FROM Miasto WHERE mi_id = @miastoId
SELECT @kraj = pa_pa�stwo FROM Pa�stwo WHERE pa_id = @krajId
SELECT @miasto = mi_miasto FROM Miasto WHERE mi_id = @miastoId
END;

GO
DECLARE @imie VARCHAR(max),@nazwisko VARCHAR(max), @kraj VARCHAR(max), @miasto VARCHAR(max)
SET @imie = 'Jacek'
SET @nazwisko = 'Morski'
EXEC gdzieBy�B�dzieGo�� @imie, @nazwisko, @kraj output, @miasto output
SELECT @miasto AS Miasto, @kraj AS Pa�stwo

-- 6 --
-- napisz funkcj�, kt�ra zwr�ci nazwisko go�cia, kt�ry wyda� najwi�cej w ostatniej rezerwacji

CREATE FUNCTION znajd�Najwi�kszyKoszt(@sth VARCHAR(max))
RETURNS VARCHAR(MAX) 
AS
BEGIN
DECLARE @najwiekszyKoszt DECIMAL(20,2), @koszty DECIMAL(20,2), @cnt INT, @nazwiskoMax VARCHAR(max), @pesel BIGINT, @nazwiskoTmp VARCHAR(max)

SELECT @cnt = count(go_id) FROM Go�� 
WHILE @cnt >= 0 
BEGIN
	SELECT @pesel = go_pesel, @nazwiskoTmp = go_nazwisko FROM Go�� WHERE go_id = @cnt
	EXEC pobierzKosztyGo�cia @pesel, @koszty output
	IF @koszty > @najwiekszyKoszt
	BEGIN
		SET @nazwiskoMax = @nazwiskoTmp
		SET @najwiekszyKoszt = @koszty
	END 

	SET @cnt = @cnt - 1;
END
	RETURN @nazwiskoMax
END

drop function znajd�Najwi�kszyKoszt

SELECT dbo.znajd�Najwi�kszyKoszt('')