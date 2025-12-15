-- ERD'ye göre optimize edilmiş AddParkingSpot stored procedure
-- AirportParkingSystem.ParkingSpots tablosuna yeni park yeri ekler
-- ERD'ye göre: Parking_ParkingSpots.SpotID (PK), ParkingLotID (FK -> Parking_ParkingLots), SpotNumber, IsReserved
-- PERFORMANS: Index'lenmiş ParkingLotID ile hızlı kontrol, minimal transaction süresi

CREATE PROCEDURE [AirportParkingSystem].[AddParkingSpot]
    @ParkingLotID INT,
    @SpotNumber   NVARCHAR(20),
    @IsReserved   BIT,
    @UserID       INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;

    BEGIN TRY
        -- ParkingLotID'nin varlığını kontrol et (index'lenmiş olmalı)
        IF NOT EXISTS (SELECT 1 FROM AirportParkingSystem.ParkingLots WITH (NOLOCK) WHERE ParkingLotID = @ParkingLotID)
        BEGIN
            ROLLBACK;
            THROW 50001, 'Otopark alanı bulunamadı.', 1;
            RETURN;
        END

        -- SpotNumber'un boş olmadığını kontrol et
        IF @SpotNumber IS NULL OR LEN(LTRIM(RTRIM(@SpotNumber))) = 0
        BEGIN
            ROLLBACK;
            THROW 50002, 'Park yeri numarası boş olamaz.', 1;
            RETURN;
        END

        -- Aynı otopark alanında aynı numarada park yeri olmamalı (unique kontrolü)
        -- Index'lenmiş (ParkingLotID, SpotNumber) composite index varsa çok hızlı olur
        IF EXISTS (
            SELECT 1 
            FROM AirportParkingSystem.ParkingSpots WITH (NOLOCK)
            WHERE ParkingLotID = @ParkingLotID
              AND SpotNumber = LTRIM(RTRIM(@SpotNumber))
        )
        BEGIN
            ROLLBACK;
            THROW 50003, 'Bu otopark alanında aynı numarada bir park yeri zaten mevcut.', 1;
            RETURN;
        END

        -- SpotID IDENTITY değilse, manuel olarak bir sonraki ID'yi hesapla
        DECLARE @SpotID INT;
        
        -- Mevcut en büyük SpotID'yi bul ve bir artır (index'lenmiş SpotID ile hızlı)
        SELECT @SpotID = ISNULL(MAX(SpotID), 0) + 1
        FROM AirportParkingSystem.ParkingSpots WITH (NOLOCK);

        -- Yeni park yerini ekle (SpotID dahil - IDENTITY olmadığı için manuel değer veriyoruz)
        INSERT INTO AirportParkingSystem.ParkingSpots WITH (ROWLOCK)
            (SpotID, ParkingLotID, SpotNumber, IsReserved)
        VALUES
            (@SpotID, @ParkingLotID, LTRIM(RTRIM(@SpotNumber)), @IsReserved);

        -- Activity Log
        INSERT INTO GeneralCommon.ActivityLog
            (UserID, Action, Description, LogDate)
        VALUES
            (
                @UserID,
                'CREATE_PARKING_SPOT',
                CONCAT('Yeni park yeri eklendi. SpotID=', @SpotID, ', SpotNumber=', LTRIM(RTRIM(@SpotNumber)), ', ParkingLotID=', @ParkingLotID),
                GETDATE()
            );

        -- Yeni oluşturulan SpotID'yi döndür
        SELECT @SpotID AS SpotID;

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

