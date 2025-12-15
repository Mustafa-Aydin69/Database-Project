-- ERD'ye göre optimize edilmiş AddUserVehicle stored procedure
-- AirportParkingSystem.UserVehicles tablosuna yeni kullanıcı aracı ekler
-- ERD'ye göre: 
--   Parking_UserVehicles.VehicleID (PK, NOT IDENTITY - manuel ID üretimi gerekli)
--   Parking_UserVehicles.UserID (FK -> GeneralCommon_Users.UserID)
--   Parking_UserVehicles.TypeID (FK -> Parking_VehicleTypes.TypeID)
--   Parking_UserVehicles.PlateNumber
-- PERFORMANS: Index'lenmiş FK'lar ile hızlı kontrol, minimal transaction süresi, EXISTS kullanımı

CREATE PROCEDURE [AirportParkingSystem].[AddUserVehicle]
    @UserID INT,
    @TypeID INT,
    @PlateNumber NVARCHAR(20),
    @LogUserID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;

    BEGIN TRY
        -- UserID'nin varlığını kontrol et (FK kontrolü - index'lenmiş UserID ile hızlı)
        IF NOT EXISTS (SELECT 1 FROM GeneralCommon.Users WITH (NOLOCK) WHERE UserID = @UserID)
        BEGIN
            ROLLBACK;
            THROW 50001, 'Kullanıcı bulunamadı.', 1;
            RETURN;
        END

        -- TypeID'nin varlığını kontrol et (FK kontrolü - index'lenmiş TypeID ile hızlı)
        IF NOT EXISTS (SELECT 1 FROM AirportParkingSystem.VehicleTypes WITH (NOLOCK) WHERE TypeID = @TypeID)
        BEGIN
            ROLLBACK;
            THROW 50002, 'Araç tipi bulunamadı.', 1;
            RETURN;
        END

        -- PlateNumber'ı normalize et ve boş kontrolü yap
        SET @PlateNumber = LTRIM(RTRIM(@PlateNumber));
        IF @PlateNumber IS NULL OR @PlateNumber = ''
        BEGIN
            ROLLBACK;
            THROW 50003, 'Plaka numarası boş olamaz.', 1;
            RETURN;
        END

        -- Aynı kullanıcı için aynı plaka numarası kontrolü (duplicate check)
        -- Index'lenmiş (UserID, PlateNumber) composite index varsa çok hızlı olur
        IF EXISTS (
            SELECT 1 
            FROM AirportParkingSystem.UserVehicles WITH (NOLOCK)
            WHERE UserID = @UserID
              AND PlateNumber = @PlateNumber
        )
        BEGIN
            ROLLBACK;
            THROW 50004, 'Bu kullanıcı için aynı plaka numarasına sahip bir araç zaten mevcut.', 1;
            RETURN;
        END

        -- VehicleID IDENTITY değilse, manuel olarak bir sonraki ID'yi hesapla
        DECLARE @VehicleID INT;
        
        -- Mevcut en büyük VehicleID'yi bul ve bir artır (index'lenmiş VehicleID ile hızlı)
        SELECT @VehicleID = ISNULL(MAX(VehicleID), 0) + 1
        FROM AirportParkingSystem.UserVehicles WITH (NOLOCK);

        -- Yeni aracı ekle (VehicleID dahil - IDENTITY olmadığı için manuel değer veriyoruz)
        INSERT INTO AirportParkingSystem.UserVehicles WITH (ROWLOCK)
            (VehicleID, UserID, TypeID, PlateNumber)
        VALUES
            (@VehicleID, @UserID, @TypeID, @PlateNumber);

        -- Activity Log
        INSERT INTO GeneralCommon.ActivityLog
            (UserID, Action, Description, LogDate)
        VALUES
            (
                @LogUserID,
                'CREATE_USER_VEHICLE',
                CONCAT('Yeni araç eklendi. VehicleID=', @VehicleID, ', PlateNumber=', @PlateNumber, ', UserID=', @UserID, ', TypeID=', @TypeID),
                GETDATE()
            );

        -- Yeni oluşturulan VehicleID'yi döndür
        SELECT @VehicleID AS VehicleID;

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO
