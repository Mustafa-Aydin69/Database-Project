-- ERD'ye göre optimize edilmiş DeleteParkingSpot stored procedure
-- AirportParkingSystem.ParkingSpots tablosundan park yeri siler
-- ERD'ye göre: Parking_ParkingSpots.SpotID (PK), Parking_ParkingReservations.SpotID (FK -> Parking_ParkingSpots)
-- PERFORMANS: Index'lenmiş SpotID ile hızlı kontrol, minimal transaction süresi, EXISTS kullanımı

CREATE PROCEDURE [AirportParkingSystem].[DeleteParkingSpot]
    @SpotID INT,
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;

    BEGIN TRY
        -- SpotID'nin varlığını kontrol et (index'lenmiş SpotID ile hızlı)
        IF NOT EXISTS (SELECT 1 FROM AirportParkingSystem.ParkingSpots WITH (NOLOCK) WHERE SpotID = @SpotID)
        BEGIN
            ROLLBACK;
            THROW 50001, 'Park yeri bulunamadı.', 1;
            RETURN;
        END

        -- SpotNumber'ı ActivityLog için al (index'lenmiş SpotID ile hızlı)
        DECLARE @SpotNumber NVARCHAR(20);
        SELECT @SpotNumber = SpotNumber
        FROM AirportParkingSystem.ParkingSpots WITH (NOLOCK)
        WHERE SpotID = @SpotID;

        -- Bu park yeri ile ilgili aktif/tamamlanmamış rezervasyonlar var mı kontrol et
        -- Parking_ParkingReservations tablosunda SpotID FK var (ERD'ye göre)
        -- Tamamlanmamış rezervasyonlar varsa silme işlemini engelle
        -- Status değerleri: 'Active', 'Pending', 'Reserved', 'CheckedIn' -> silinemez
        -- Status değerleri: 'Completed', 'Cancelled' -> silinebilir
        IF EXISTS (
            SELECT 1 
            FROM AirportParkingSystem.ParkingReservations WITH (NOLOCK)
            WHERE SpotID = @SpotID
              AND Status NOT IN ('Completed', 'Cancelled') -- Tamamlanmamış rezervasyonlar
        )
        BEGIN
            ROLLBACK;
            THROW 50002, 'Bu park yerine ait aktif/tamamlanmamış rezervasyonlar bulunduğu için silinemez. Önce rezervasyonları iptal edin veya tamamlayın.', 1;
            RETURN;
        END

        -- Park yerini sil (ROWLOCK ile row-level locking için performans)
        DELETE FROM AirportParkingSystem.ParkingSpots WITH (ROWLOCK)
        WHERE SpotID = @SpotID;

        -- Activity Log
        INSERT INTO GeneralCommon.ActivityLog
            (UserID, Action, Description, LogDate)
        VALUES
            (
                @UserID,
                'DELETE_PARKING_SPOT',
                CONCAT('Park yeri silindi. SpotID=', @SpotID, ', SpotNumber=', @SpotNumber),
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
