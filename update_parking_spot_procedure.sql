-- ERD'ye göre optimize edilmiş UpdateParkingSpot stored procedure
-- AirportParkingSystem.ParkingSpots tablosundan park yerini günceller
-- ERD'ye göre: Parking_ParkingSpots.SpotID (PK), ParkingLotID (FK), SpotNumber, IsReserved
-- Sadece IsReserved güncellenebilir (ParkingLotID ve SpotNumber değiştirilemez)
-- PERFORMANS: Index'lenmiş SpotID ile hızlı UPDATE, minimal transaction süresi

CREATE PROCEDURE [AirportParkingSystem].[UpdateParkingSpot]
    @SpotID      INT,
    @IsReserved  BIT,
    @UserID      INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;

    BEGIN TRY
        -- SpotID'nin varlığını kontrol et
        IF NOT EXISTS (SELECT 1 FROM AirportParkingSystem.ParkingSpots WHERE SpotID = @SpotID)
        BEGIN
            ROLLBACK;
            THROW 50001, 'Park yeri bulunamadı.', 1;
            RETURN;
        END

        -- Sadece IsReserved güncellenir
        -- ParkingLotID ve SpotNumber değiştirilemez
        UPDATE AirportParkingSystem.ParkingSpots WITH (ROWLOCK) -- Row-level lock (performans için)
        SET IsReserved = @IsReserved
        WHERE SpotID = @SpotID;

        -- Activity Log
        DECLARE @SpotNumber NVARCHAR(20);
        SELECT @SpotNumber = SpotNumber 
        FROM AirportParkingSystem.ParkingSpots 
        WHERE SpotID = @SpotID;

        INSERT INTO GeneralCommon.ActivityLog
            (UserID, Action, Description, LogDate)
        VALUES
            (
                @UserID,
                'UPDATE_PARKING_SPOT',
                CONCAT('Park yeri güncellendi. SpotID=', @SpotID, ', SpotNumber=', @SpotNumber, ', IsReserved=', @IsReserved),
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

