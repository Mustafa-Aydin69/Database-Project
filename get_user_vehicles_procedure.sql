-- ERD'ye göre optimize edilmiş GetUserVehicles stored procedure
-- AirportParkingSystem.UserVehicles tablosundan kullanıcı araçlarını getirir
-- ERD'ye göre: 
--   Parking_UserVehicles.VehicleID (PK)
--   Parking_UserVehicles.UserID (FK -> GeneralCommon_Users.UserID)
--   Parking_UserVehicles.TypeID (FK -> Parking_VehicleTypes.TypeID)
-- PERFORMANS: Index'lenmiş FK'lar ile hızlı JOIN, NOLOCK hints, basit ORDER BY

CREATE PROCEDURE [AirportParkingSystem].[GetUserVehicles]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        uv.VehicleID,
        uv.PlateNumber,
        u.UserID,
        u.FullName,
        u.Email,
        vt.TypeID,
        vt.TypeName
    FROM AirportParkingSystem.UserVehicles uv WITH (NOLOCK)
    INNER JOIN GeneralCommon.Users u WITH (NOLOCK)
        ON uv.UserID = u.UserID
    INNER JOIN AirportParkingSystem.VehicleTypes vt WITH (NOLOCK)
        ON uv.TypeID = vt.TypeID
    ORDER BY u.FullName, uv.PlateNumber;
END;
GO
