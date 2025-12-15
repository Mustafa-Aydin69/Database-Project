-- ERD'ye göre optimize edilmiş GetParkingReservations stored procedure
-- AirportParkingSystem.ParkingReservations tablosundan tüm rezervasyonları getirir
-- ERD'ye göre JOIN path:
--   ParkingReservations -> Users (UserID FK)
--   ParkingReservations -> ParkingSpots (SpotID FK)
--   ParkingSpots -> ParkingLots (ParkingLotID FK)
--   ParkingLots -> Airports (AirportID FK)
--   ParkingReservations -> UserVehicles (VehicleID FK)
--   UserVehicles -> VehicleTypes (TypeID FK)
-- PERFORMANS: WITH (NOLOCK) hints, basit ORDER BY, + operatörü (CONCAT yerine), index'lenmiş FK'lar

CREATE PROCEDURE [AirportParkingSystem].[GetParkingReservations]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        -- Ana rezervasyon bilgileri
        PR.ParkingReservationID,
        PR.CheckinTime,
        PR.CheckOutTime,
        PR.Status,
        
        -- Kullanıcı bilgileri (Users tablosundan)
        U.UserID,
        U.FullName AS UserName,
        U.Email AS UserEmail,
        U.Phone AS UserPhone,
        
        -- Park yeri bilgileri (ParkingSpots tablosundan)
        PS.SpotID,
        PS.SpotNumber,
        PS.IsReserved,
        
        -- Otopark alanı bilgileri (ParkingLots tablosundan)
        PL.ParkingLotID,
        PL.LotName AS ParkingLotName,
        PL.Capacity AS ParkingLotCapacity,
        PL.LocationDescription AS ParkingLotLocation,
        
        -- Havalimanı bilgileri (Airports tablosundan)
        A.AirportID,
        A.Name AS AirportName,
        A.IATA_Code AS AirportIATACode,
        A.City AS AirportCity,
        A.Country AS AirportCountry,
        -- Havalimanı adını formatla (CONCAT yerine + operatörü - performans için)
        (A.IATA_Code + ' - ' + A.Name) AS AirportDisplayName,
        
        -- Araç bilgileri (UserVehicles tablosundan)
        UV.VehicleID,
        UV.PlateNumber,
        
        -- Araç tipi bilgileri (VehicleTypes tablosundan)
        VT.TypeID,
        VT.TypeName AS VehicleTypeName,
        VT.PriceMultiplier AS VehiclePriceMultiplier

    FROM AirportParkingSystem.ParkingReservations PR WITH (NOLOCK)
    
    -- Kullanıcı bilgileri için JOIN
    INNER JOIN GeneralCommon.Users U WITH (NOLOCK)
        ON PR.UserID = U.UserID
    
    -- Park yeri bilgileri için JOIN
    INNER JOIN AirportParkingSystem.ParkingSpots PS WITH (NOLOCK)
        ON PR.SpotID = PS.SpotID
    
    -- Otopark alanı bilgileri için JOIN
    INNER JOIN AirportParkingSystem.ParkingLots PL WITH (NOLOCK)
        ON PS.ParkingLotID = PL.ParkingLotID
    
    -- Havalimanı bilgileri için JOIN
    INNER JOIN FlightReservationSystem.Airports A WITH (NOLOCK)
        ON PL.AirportID = A.AirportID
    
    -- Araç bilgileri için JOIN
    INNER JOIN AirportParkingSystem.UserVehicles UV WITH (NOLOCK)
        ON PR.VehicleID = UV.VehicleID
    
    -- Araç tipi bilgileri için JOIN
    INNER JOIN AirportParkingSystem.VehicleTypes VT WITH (NOLOCK)
        ON UV.TypeID = VT.TypeID
    
    -- Performans için basit ORDER BY (index'lenmiş kolonlar tercih edilir)
    ORDER BY PR.CheckinTime DESC, PR.ParkingReservationID DESC;
END;
GO
