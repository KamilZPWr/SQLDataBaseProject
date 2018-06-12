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

CREATE TABLE Państwo (
  pa_id int identity(1,1) primary key,
  pa_państwo char(45),
 ) 

CREATE TABLE Miasto (
  mi_id int identity(1,1) primary key,
  mi_miasto varchar(45),
  mi_pa_id int,

  foreign key (mi_pa_id) references Państwo(pa_id) on delete cascade,
)

CREATE TABLE Standard_Hotelu(
  st_id int identity (1,1) primary key,
  st_rodzaj varchar(max),
  mnożnik numeric(5,2) 
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

CREATE TABLE Wyżywienie(
  wy_id int identity (1,1) primary key,
  wy_typ varchar(max),
  wy_cena decimal(20,2),
  wy_dieta varchar(max)
)
  
CREATE TABLE Gość(
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
   
  foreign key (za_go_id) references Gość(go_id),
  foreign key (za_ho_id) references Hotele(ho_id) on delete cascade,
  foreign key (za_po_id) references Pokoje1(po_id),
  foreign key (za_wy_id) references Wyżywienie(wy_id),
)

-- 1 --
-- napisz funkcję, która jako argument pobiera kraj,
-- a zwaraca wszytskie hotele, ktore się w nim znajdują
CREATE FUNCTION podajHoteleWKraju(@kraj VARCHAR(max))
RETURNS table 
AS
RETURN( SELECT ho_hotel AS Hotel FROM Hotele WHERE ho_mi_id IN (
	SELECT mi_id FROM Miasto WHERE mi_pa_id IN (
		SELECT pa_id FROM Państwo WHERE pa_państwo = @kraj)))


drop function podajHoteleWKraju
select * from podajHoteleWKraju('Włochy')

-- 2 -- 
-- napisz funkcję, która jako argument pobiera pesel gościa,
-- a w zmiennej zewnętrznej zwraca łączną cenę za wyżywienie i pokój ostatniej jego rezerwacji
-- cene pokoju, trzeba przemnożyć przez mnożnik 

CREATE FUNCTION pobierzKosztyGoscia (@PESEL BIGINT)
RETURNS DECIMAL(20,2)
BEGIN
DECLARE @mnoznik NUMERIC(5,2), @cenaWyzywienia DECIMAL(20,2), @cenaPokoju DECIMAL(20,2), @hotel INT, @pokój INT, @wyżywienie INT
SELECT TOP 1
	@hotel = za_ho_id,  
	@pokój = za_po_id,
	@wyżywienie = za_wy_id
FROM Zamówienie 
WHERE za_go_id = (SELECT go_id FROM Gość WHERE go_pesel = @PESEL)
ORDER BY za_data_rezerwacji DESC

SELECT @mnoznik = mnożnik FROM Standard_Hotelu WHERE st_id = (SELECT ho_st_id FROM Hotele WHERE ho_id = @hotel)
SELECT @cenaWyzywienia = wy_cena FROM Wyżywienie WHERE wy_id = @wyżywienie
SELECT @cenaPokoju = po_cena FROM Pokoje1 WHERE po_id = @pokój 
RETURN @cenaPokoju * @mnoznik + @cenaWyzywienia
END;

drop function pobierzKosztyGoscia

SELECT dbo.pobierzKosztyGoscia(999982372)

GO
DECLARE @PESEL INT, @dataRezerwacji DATE, @koszty DECIMAL(20,2)
SET @PESEL = '999982372'
EXEC pobierzKosztyGościa @PESEL, @koszty output
SELECT @PESEL AS Gość, @koszty AS Koszty_wyjazdu

select * FROM Gość

-- 3 -- 
-- napisz triger, który po usunięciu gościa, usunie jego zamówienie
CREATE TRIGGER usunGoscia ON Gość
INSTEAD OF DELETE
AS
BEGIN
DECLARE @gość INT 
SELECT @gość = go_id FROM deleted
DELETE FROM Zamówienie WHERE za_go_id = @gość
DELETE FROM Gość WHERE go_id = @gość
END

select * from Gość
select * from Zamówienie

DELETE FROM Gość WHERE go_pesel = '123333453'

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
-- napisz procedurę, która jako argument pobiera imię i nazwisko gościa, 
-- a zwraca miasto i kraj, w których był / będzie gość

CREATE PROCEDURE gdzieByłBędzieGość
@imie VARCHAR(max),
@nazwisko VARCHAR(max),
@kraj VARCHAR(max) output,
@miasto VARCHAR(max) output
AS 
BEGIN
DECLARE @hotelId INT, @goscId INT, @miastoId INT, @krajId INT
SELECT @goscId = go_id FROM Gość WHERE go_imie = @imie AND go_nazwisko = @nazwisko
SELECT @hotelId = za_ho_id FROM Zamówienie WHERE za_go_id = @goscId
SELECT @miastoId = ho_mi_id FROM Hotele WHERE ho_id = @hotelId
SELECT @krajId = mi_pa_id FROM Miasto WHERE mi_id = @miastoId
SELECT @kraj = pa_państwo FROM Państwo WHERE pa_id = @krajId
SELECT @miasto = mi_miasto FROM Miasto WHERE mi_id = @miastoId
END;

GO
DECLARE @imie VARCHAR(max),@nazwisko VARCHAR(max), @kraj VARCHAR(max), @miasto VARCHAR(max)
SET @imie = 'Jacek'
SET @nazwisko = 'Morski'
EXEC gdzieByłBędzieGość @imie, @nazwisko, @kraj output, @miasto output
SELECT @miasto AS Miasto, @kraj AS Państwo

-- 6 --
-- napisz funkcję, która zwróci nazwisko gościa, który wydał najwięcej w ostatniej rezerwacji

CREATE FUNCTION znajdźNajwiększyKoszt()
RETURNS VARCHAR(MAX) 
AS
BEGIN
DECLARE @najwiekszyKoszt DECIMAL(20,2) = 0, @koszty DECIMAL(20,2), @cnt INT, @nazwiskoMax VARCHAR(max), @pesel BIGINT, @nazwiskoTmp VARCHAR(max)

SELECT @cnt = count(go_id) FROM Gość 
WHILE @cnt >= 0 
BEGIN
	SELECT @pesel = go_pesel, @nazwiskoTmp = go_nazwisko FROM Gość WHERE go_id = @cnt
	SELECT @koszty = dbo.pobierzKosztyGoscia(@pesel)
	IF @koszty > @najwiekszyKoszt
	BEGIN
		SET @nazwiskoMax = @nazwiskoTmp
		SET @najwiekszyKoszt = @koszty
	END 

	SET @cnt = @cnt - 1;
END
	RETURN @nazwiskoMax
END

drop function znajdźNajwiększyKoszt

<<<<<<< HEAD
SELECT dbo.znajd�Najwi�kszyKoszt() AS Go��CoNajwi�cejZap�aci�

-- 7 --
-- Napisz widok ktory pokazuje wszystkich go�ci oraz ich standard pokoju w hotelu

CREATE VIEW standardPokojuGosci AS(
SELECT go_imie AS Imi�, go_nazwisko AS Nazwisko, st_rodzaj AS StandardPokoju FROM Go�� LEFT JOIN 
	Zam�wienie ON Go��.go_id = Zam�wienie.za_go_id LEFT JOIN 
		Hotele ON Zam�wienie.za_ho_id = Hotele.ho_id LEFT JOIN
			Standard_Hotelu ON Hotele.ho_st_id = Standard_Hotelu.st_id)

SELECT * FROM standardPokojuGosci

-- 8 --
-- napisz funkcje, kt�ra jako parametr przyjmuje nazwe hotelu, a zwraca wszystkie zam�wienia do niego

CREATE FUNCTION zamowieniaHotelu(@hotelNazwa VARCHAR(max))
RETURNS TABLE 
AS
RETURN (SELECT ho_hotel AS Hotel, po_rodzaj AS Pok�j, za_id AS NumerZam�wienia FROM Hotele LEFT JOIN 
	Zam�wienie ON Hotele.ho_id = Zam�wienie.za_ho_id INNER JOIN
	Pokoje1 ON Zam�wienie.za_po_id = Pokoje1.po_id WHERE ho_hotel = @hotelNazwa)

drop function zamowieniaHotelu

SELECT * FROM zamowieniaHotelu('Suite Hotel')

-- 9 -- 
-- napisz widok, kt�ry pokazuje wszystkich go�ci kt�rzy nie jedza mi�sa

CREATE VIEW pokazKlientowBezMiesa AS(
SELECT DISTINCT go_imie AS Imi�, go_nazwisko AS Nazwisko FROM Go�� LEFT JOIN 
	Zam�wienie ON Go��.go_id = Zam�wienie.za_go_id LEFT JOIN
	Wy�ywienie ON Wy�ywienie.wy_id = Zam�wienie.za_wy_id WHERE 
	wy_dieta != 'miesna' )

SELECT * FROM pokazKlientowBezMiesa

-- 10 --
-- napisz fukcj�, kt�ra jako argumet przyjmuje typ wy�ywienia i pokazuje email os�b kt�re j� wybra�y

CREATE FUNCTION pokazGosciZDieta(@dieta VARCHAR(max))
RETURNS TABLE 
AS
RETURN (SELECT DISTINCT go_imie AS Imi�, go_nazwisko AS Nazwisko, go_mail AS Email FROM Go�� INNER JOIN
	Zam�wienie ON Go��.go_id = Zam�wienie.za_go_id LEFT JOIN 
	Wy�ywienie ON Zam�wienie.za_wy_id = Wy�ywienie.wy_id WHERE wy_dieta = @dieta)

drop FUNCTION pokazGosciZDieta

SELECT * FROM pokazGosciZDieta('miesna')
=======
SELECT dbo.znajdźNajwiększyKoszt() AS GośćCoNajwięcejZapłacił
>>>>>>> 0ef97a77977d87b297fa8be70dc17cb6eebbc286
