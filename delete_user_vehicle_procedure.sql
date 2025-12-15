-- ERD'ye göre optimize edilmiş DeleteUserVehicle stored procedure
-- AirportParkingSystem.UserVehicles tablosundan kullanıcı aracını siler
-- ERD'ye göre: 
--   Parking_UserVehicles.VehicleID (PK)
--   Parking_ParkingReservations.VehicleID (FK -> Parking_UserVehicles.VehicleID)
-- PERFORMANS: Index'lenmiş VehicleID ile hızlı kontrol, minimal transaction süresi, EXISTS kullanımı

CREATE PROCEDURE [AirportParkingSystem].[DeleteUserVehicle]
    @VehicleID INT,
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

        -- PlateNumber'ı ActivityLog için al (index'lenmiş VehicleID ile hızlı)
        DECLARE @PlateNumber NVARCHAR(20);
        SELECT @PlateNumber = PlateNumber
        FROM AirportParkingSystem.UserVehicles WITH (NOLOCK)
        WHERE VehicleID = @VehicleID;

        -- Bu araca ait aktif/tamamlanmamış rezervasyonlar var mı kontrol et
        -- Parking_ParkingReservations tablosunda VehicleID FK var (ERD'ye göre)
        -- Tamamlanmamış rezervasyonlar varsa silme işlemini engelle
        -- Status değerleri: 'Active', 'Pending', 'Reserved', 'CheckedIn' -> silinemez
        -- Status değerleri: 'Completed', 'Cancelled' -> silinebilir
        IF EXISTS (
            SELECT 1 
            FROM AirportParkingSystem.ParkingReservations WITH (NOLOCK)
            WHERE VehicleID = @VehicleID
              AND Status NOT IN ('Completed', 'Cancelled') -- Tamamlanmamış rezervasyonlar
        )
        BEGIN
            ROLLBACK;
            THROW 50002, 'Bu araca ait aktif/tamamlanmamış rezervasyonlar bulunduğu için silinemez. Önce rezervasyonları iptal edin veya tamamlayın.', 1;
            RETURN;
        END

        -- Aracı sil (ROWLOCK ile row-level locking için performans)
        DELETE FROM AirportParkingSystem.UserVehicles WITH (ROWLOCK)
        WHERE VehicleID = @VehicleID;

        -- Activity Log
        INSERT INTO GeneralCommon.ActivityLog
            (UserID, Action, Description, LogDate)
        VALUES
            (
                @LogUserID,
                'DELETE_USER_VEHICLE',
                CONCAT('Araç silindi. VehicleID=', @VehicleID, ', PlateNumber=', @PlateNumber),
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
