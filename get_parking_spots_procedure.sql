-- ERD'ye göre optimize edilmiş GetParkingSpots stored procedure
-- AirportParkingSystem.ParkingSpots tablosundan park yerlerini getirir
-- PERFORMANS OPTİMİZASYONLARI:
-- 1. INDEX kullanımı: ParkingSpots.ParkingLotID, ParkingLots.AirportID, ParkingLots.ParkingLotID index'lenmeli
-- 2. SELECT'e sadece gerekli kolonlar dahil edildi
-- 3. ORDER BY basitleştirildi (sadece SpotNumber'a göre sıralama, frontend'de gerekirse ek sıralama yapılabilir)
-- 4. CONCAT yerine + operatörü kullanıldı (SQL Server'da daha hızlı)
-- 5. SET NOCOUNT ON ile gereksiz row count mesajları kaldırıldı

CREATE PROCEDURE [AirportParkingSystem].[GetParkingSpots]
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Performans için sadece gerekli kolonları seç
    SELECT
        PS.SpotID,
        PS.ParkingLotID,
        PS.SpotNumber,
        PS.IsReserved,
        -- Otopark alanı bilgileri (JOIN ile)
        PL.LotName AS ParkingLotName,
        PL.Capacity AS ParkingLotCapacity,
        PL.LocationDescription AS ParkingLotLocation,
        -- Havalimanı bilgileri (JOIN ile)
        A.AirportID,
        A.Name AS AirportName,
        A.IATA_Code AS AirportIATACode,
        A.City AS AirportCity,
        -- Havalimanı adını formatla (+ operatörü CONCAT'ten daha hızlı)
        (A.IATA_Code + ' - ' + A.Name) AS AirportDisplayName
    FROM AirportParkingSystem.ParkingSpots PS WITH (NOLOCK) -- READ UNCOMMITTED için (performans artışı, tutarlılık önemli değilse)
    -- Otopark alanı bilgilerini almak için JOIN (index'lenmiş olmalı)
    INNER JOIN AirportParkingSystem.ParkingLots PL WITH (NOLOCK)
        ON PS.ParkingLotID = PL.ParkingLotID
    -- Havalimanı bilgilerini almak için JOIN (index'lenmiş olmalı)
    INNER JOIN FlightReservationSystem.Airports A WITH (NOLOCK)
        ON PL.AirportID = A.AirportID
    ORDER BY PS.SpotNumber; -- Basit sıralama (index varsa daha hızlı)
    
    -- NOT: Eğer hala yavaşsa, aşağıdaki index'leri oluşturun:
    -- CREATE NONCLUSTERED INDEX IX_ParkingSpots_ParkingLotID ON AirportParkingSystem.ParkingSpots(ParkingLotID);
    -- CREATE NONCLUSTERED INDEX IX_ParkingLots_AirportID ON AirportParkingSystem.ParkingLots(AirportID);
    -- CREATE NONCLUSTERED INDEX IX_ParkingSpots_SpotNumber ON AirportParkingSystem.ParkingSpots(SpotNumber);
END;
GO

