-- ERD'ye göre doğru AddParkingLot stored procedure
-- AirportParkingSystem.ParkingLots tablosuna yeni otopark alanı ekler
-- ERD'ye göre: Parking_ParkingLots.ParkingLotID (PK), AirportID (FK -> Flight_Airports), LotName, Capacity, LocationDescription
-- AirportID -> Flight_Airports.AirportID (FK kontrolü yapılmalı)
-- Aynı havalimanında aynı isimde otopark olmamalı (unique kontrolü)

CREATE PROCEDURE [AirportParkingSystem].[AddParkingLot]
    @AirportID           INT,
    @LotName             NVARCHAR(100),
    @Capacity            INT,
    @LocationDescription NVARCHAR(500) = NULL,
    @UserID              INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;

    BEGIN TRY
        -- AirportID'nin varlığını kontrol et (Flight_Airports tablosunda var mı?)
        IF NOT EXISTS (SELECT 1 FROM FlightReservationSystem.Airports WHERE AirportID = @AirportID)
        BEGIN
            ROLLBACK;
            THROW 50001, 'Havalimanı bulunamadı.', 1;
            RETURN;
        END

        -- Aynı havalimanında aynı isimde otopark olmamalı (unique kontrolü)
        IF EXISTS (
            SELECT 1
            FROM AirportParkingSystem.ParkingLots
            WHERE AirportID = @AirportID
              AND LotName = @LotName
        )
        BEGIN
            ROLLBACK;
            THROW 50002, 'Bu havalimanında aynı isimde bir otopark alanı zaten mevcut.', 1;
            RETURN;
        END

        -- Capacity'nin geçerli bir pozitif sayı olduğunu kontrol et
        IF @Capacity IS NULL OR @Capacity <= 0
        BEGIN
            ROLLBACK;
            THROW 50003, 'Kapasite geçerli bir pozitif sayı olmalıdır.', 1;
            RETURN;
        END

        -- LotName'in boş olmadığını kontrol et
        IF @LotName IS NULL OR LEN(LTRIM(RTRIM(@LotName))) = 0
        BEGIN
            ROLLBACK;
            THROW 50004, 'Otopark adı boş olamaz.', 1;
            RETURN;
        END

        -- ParkingLotID IDENTITY değilse, manuel olarak bir sonraki ID'yi hesapla
        DECLARE @ParkingLotID INT;
        
        -- Mevcut en büyük ParkingLotID'yi bul ve bir artır
        SELECT @ParkingLotID = ISNULL(MAX(ParkingLotID), 0) + 1
        FROM AirportParkingSystem.ParkingLots;

        -- Yeni otopark alanını ekle (ParkingLotID dahil)
        INSERT INTO AirportParkingSystem.ParkingLots
            (ParkingLotID, AirportID, LotName, Capacity, LocationDescription)
        VALUES
            (@ParkingLotID, @AirportID, LTRIM(RTRIM(@LotName)), @Capacity, @LocationDescription);

        -- Activity Log
        INSERT INTO GeneralCommon.ActivityLog
            (UserID, Action, Description, LogDate)
        VALUES
            (
                @UserID,
                'CREATE_PARKING_LOT',
                CONCAT('Yeni otopark alanı eklendi. ParkingLotID=', @ParkingLotID, ', LotName=', LTRIM(RTRIM(@LotName)), ', AirportID=', @AirportID),
                GETDATE()
            );

        -- Yeni oluşturulan ParkingLotID'yi döndür
        SELECT @ParkingLotID AS ParkingLotID;

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

