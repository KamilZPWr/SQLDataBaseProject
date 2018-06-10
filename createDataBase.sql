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
  mno¿nik numeric(5,2) 
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
  za_data_rezerwacji DATE
   
  foreign key (za_go_id) references Goœæ(go_id),
  foreign key (za_ho_id) references Hotele(ho_id) on delete cascade,
  foreign key (za_po_id) references Pokoje1(po_id),
  foreign key (za_wy_id) references Wy¿ywienie(wy_id),
)

-- 1 --
-- napisz funkcjê, która jako argument pobiera kraj,
-- a zwaraca wszytskie hotele, ktore siê w nim znajduj¹
CREATE FUNCTION podajHoteleWKraju(@kraj VARCHAR(max))
RETURNS table 
AS
RETURN( SELECT ho_hotel AS Hotel FROM Hotele WHERE ho_mi_id IN (
	SELECT mi_id FROM Miasto WHERE mi_pa_id IN (
		SELECT pa_id FROM Pañstwo WHERE pa_pañstwo = @kraj)))


drop function podajHoteleWKraju
select * from podajHoteleWKraju('W³ochy')

-- 2 -- 
-- napisz procedurê, która jako argument pobiera pesel goœcia,
-- a w zmiennej zewnêtrznej zwraca ³¹czn¹ cenê za wy¿ywienie i pokój ostatniej jego rezerwacji
-- cene pokoju, trzeba przemno¿yæ przez mno¿nik 

CREATE PROCEDURE pobierzKosztyGoœcia
@PESEL BIGINT,
@koszty DECIMAL(20,2) OUTPUT
AS 
BEGIN
DECLARE @mnoznik NUMERIC(5,2), @cenaWyzywienia DECIMAL(20,2), @cenaPokoju DECIMAL(20,2), @hotel INT, @pokój INT, @wy¿ywienie INT
SELECT TOP 1
	@hotel = za_ho_id,  
	@pokój = za_po_id,
	@wy¿ywienie = za_wy_id
FROM Zamówienie 
WHERE za_go_id = (SELECT go_id FROM Goœæ WHERE go_pesel = @PESEL)
ORDER BY za_data_rezerwacji DESC

SELECT @mnoznik = mno¿nik FROM Standard_Hotelu WHERE st_id = (SELECT ho_st_id FROM Hotele WHERE ho_id = @hotel)
SELECT @cenaWyzywienia = wy_cena FROM Wy¿ywienie WHERE wy_id = @wy¿ywienie
SELECT @cenaPokoju = po_cena FROM Pokoje1 WHERE po_id = @pokój 
SET @koszty = @cenaPokoju * @mnoznik + @cenaWyzywienia
END;

drop procedure pobierzKosztyGoœcia

GO
DECLARE @PESEL INT, @dataRezerwacji DATE, @koszty DECIMAL(20,2)
SET @PESEL = '999982372'
EXEC pobierzKosztyGoœcia @PESEL, @koszty output
SELECT @PESEL AS Goœæ, @koszty AS Koszty_wyjazdu

select * FROM Goœæ

-- 3 -- 
-- napisz triger, który po usuniêciu goœcia, usunie jego zamówienie
CREATE TRIGGER usunGoscia ON Goœæ
INSTEAD OF DELETE
AS
BEGIN
DECLARE @goœæ INT 
SELECT @goœæ = go_id FROM deleted
DELETE FROM Zamówienie WHERE za_go_id = @goœæ
DELETE FROM Goœæ WHERE go_id = @goœæ
END

select * from Goœæ
select * from Zamówienie

DELETE FROM Goœæ WHERE go_pesel = '123333453'

-- 4 --
-- napisz trigger, który po dodaniu zamówienie na pokój, 
-- usunie jeden pokój z wolnych miejsc

CREATE TRIGGER usunWolnyPokoj ON Zamówienie
AFTER INSERT
AS
BEGIN
DECLARE @hotel INT, @liczbaMiejsc INT
SELECT @hotel = za_ho_id FROM inserted
SELECT @liczbaMiejsc = ho_pokoje_wolne FROM Hotele WHERE ho_id = @hotel
UPDATE Hotele SET ho_pokoje_wolne = @liczbaMiejsc - 1 WHERE ho_id = @hotel
END

select * from Hotele
select * from Zamówienie

-- 5 --
-- napisz procedurê, która jako argument pobiera imiê i nazwisko goœcia, 
-- a zwraca miasto i kraj, w których by³ / bêdzie goœæ

CREATE PROCEDURE gdzieBy³BêdzieGoœæ
@imie VARCHAR(max),
@nazwisko VARCHAR(max),
@kraj VARCHAR(max) output,
@miasto VARCHAR(max) output
AS 
BEGIN
DECLARE @hotelId INT, @goscId INT, @miastoId INT, @krajId INT
SELECT @goscId = go_id FROM Goœæ WHERE go_imie = @imie AND go_nazwisko = @nazwisko
SELECT @hotelId = za_ho_id FROM Zamówienie WHERE za_go_id = @goscId
SELECT @miastoId = ho_mi_id FROM Hotele WHERE ho_id = @hotelId
SELECT @krajId = mi_pa_id FROM Miasto WHERE mi_id = @miastoId
SELECT @kraj = pa_pañstwo FROM Pañstwo WHERE pa_id = @krajId
SELECT @miasto = mi_miasto FROM Miasto WHERE mi_id = @miastoId
END;

GO
DECLARE @imie VARCHAR(max),@nazwisko VARCHAR(max), @kraj VARCHAR(max), @miasto VARCHAR(max)
SET @imie = 'Jacek'
SET @nazwisko = 'Morski'
EXEC gdzieBy³BêdzieGoœæ @imie, @nazwisko, @kraj output, @miasto output
SELECT @miasto AS Miasto, @kraj AS Pañstwo

-- 6 --
-- napisz funkcjê, która zwróci nazwisko goœcia, który wyda³ najwiêcej w ostatniej rezerwacji

CREATE FUNCTION znajdŸNajwiêkszyKoszt(@sth VARCHAR(max))
RETURNS VARCHAR(MAX) 
AS
BEGIN
DECLARE @najwiekszyKoszt DECIMAL(20,2), @koszty DECIMAL(20,2), @cnt INT, @nazwiskoMax VARCHAR(max), @pesel BIGINT, @nazwiskoTmp VARCHAR(max)

SELECT @cnt = count(go_id) FROM Goœæ 
WHILE @cnt >= 0 
BEGIN
	SELECT @pesel = go_pesel, @nazwiskoTmp = go_nazwisko FROM Goœæ WHERE go_id = @cnt
	EXEC pobierzKosztyGoœcia @pesel, @koszty output
	IF @koszty > @najwiekszyKoszt
	BEGIN
		SET @nazwiskoMax = @nazwiskoTmp
		SET @najwiekszyKoszt = @koszty
	END 

	SET @cnt = @cnt - 1;
END
	RETURN @nazwiskoMax
END

drop function znajdŸNajwiêkszyKoszt

SELECT dbo.znajdŸNajwiêkszyKoszt('')