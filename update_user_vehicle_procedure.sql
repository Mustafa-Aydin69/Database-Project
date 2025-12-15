-- ERD'ye göre optimize edilmiş UpdateUserVehicle stored procedure
-- AirportParkingSystem.UserVehicles tablosunda kullanıcı aracını günceller
-- ERD'ye göre: 
--   Parking_UserVehicles.VehicleID (PK)
--   Parking_UserVehicles.UserID (FK -> GeneralCommon_Users.UserID)
--   Parking_UserVehicles.TypeID (FK -> Parking_VehicleTypes.TypeID)
--   Parking_ParkingReservations.VehicleID (FK -> Parking_UserVehicles.VehicleID) - güncelleme için sorun yok
-- PERFORMANS: Index'lenmiş FK'lar ile hızlı kontrol, minimal transaction süresi, EXISTS kullanımı

CREATE PROCEDURE [AirportParkingSystem].[UpdateUserVehicle]
    @VehicleID INT,
    @UserID INT,
    @TypeID INT,
    @PlateNumber NVARCHAR(20),
    @LogUserID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;

    BEGIN TRY
        -- VehicleID'nin varlığını kontrol et (index'lenmiş VehicleID ile hızlı)
        IF NOT EXISTS (SELECT 1 FROM AirportParkingSystem.UserVehicles WITH (NOLOCK) WHERE VehicleID = @VehicleID)
        BEGIN
            ROLLBACK;
            THROW 50001, 'Araç bulunamadı.', 1;
            RETURN;
        END

        -- UserID'nin varlığını kontrol et (FK kontrolü - index'lenmiş UserID ile hızlı)
        IF NOT EXISTS (SELECT 1 FROM GeneralCommon.Users WITH (NOLOCK) WHERE UserID = @UserID)
        BEGIN
            ROLLBACK;
            THROW 50002, 'Kullanıcı bulunamadı.', 1;
            RETURN;
        END

        -- TypeID'nin varlığını kontrol et (FK kontrolü - index'lenmiş TypeID ile hızlı)
        IF NOT EXISTS (SELECT 1 FROM AirportParkingSystem.VehicleTypes WITH (NOLOCK) WHERE TypeID = @TypeID)
        BEGIN
            ROLLBACK;
            THROW 50003, 'Araç tipi bulunamadı.', 1;
            RETURN;
        END

        -- PlateNumber'un boş olmadığını kontrol et
        IF @PlateNumber IS NULL OR LEN(LTRIM(RTRIM(@PlateNumber))) = 0
        BEGIN
            ROLLBACK;
            THROW 50004, 'Plaka numarası boş olamaz.', 1;
            RETURN;
        END

        -- Aynı kullanıcı için aynı plaka numarasıyla başka bir araç var mı kontrol et (mevcut araç hariç)
        -- Not: ERD'de unique constraint görünmüyor, ancak mantıksal olarak aynı kullanıcının aynı plakalı iki aracı olmamalı
        IF EXISTS (
            SELECT 1 
            FROM AirportParkingSystem.UserVehicles WITH (NOLOCK)
            WHERE UserID = @UserID
              AND PlateNumber = LTRIM(RTRIM(@PlateNumber))
              AND VehicleID != @VehicleID
        )
        BEGIN
            ROLLBACK;
            THROW 50005, 'Bu kullanıcı için aynı plaka numarasına sahip başka bir araç zaten mevcut.', 1;
            RETURN;
        END

        -- Araç bilgilerini güncelle (ROWLOCK ile row-level locking için performans)
        UPDATE AirportParkingSystem.UserVehicles WITH (ROWLOCK)
        SET
            UserID      = @UserID,
            TypeID      = @TypeID,
            PlateNumber = LTRIM(RTRIM(@PlateNumber))
        WHERE VehicleID = @VehicleID;

        -- Activity Log
        INSERT INTO GeneralCommon.ActivityLog
            (UserID, Action, Description, LogDate)
        VALUES
            (
                @LogUserID,
                'UPDATE_USER_VEHICLE',
                CONCAT('Araç güncellendi. VehicleID=', @VehicleID, ', PlateNumber=', LTRIM(RTRIM(@PlateNumber)), ', UserID=', @UserID, ', TypeID=', @TypeID),
                GETDATE()
            );

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO
