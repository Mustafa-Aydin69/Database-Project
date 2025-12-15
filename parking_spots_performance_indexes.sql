-- AddParkingSpot procedure performans optimizasyonu için INDEX'ler
-- Bu index'ler procedure'ın çok daha hızlı çalışmasını sağlar
-- Özellikle büyük veri setlerinde kritik öneme sahiptir

-- ParkingSpots tablosundaki ParkingLotID için index (JOIN ve varlık kontrolü için)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ParkingSpots_ParkingLotID' AND object_id = OBJECT_ID('AirportParkingSystem.ParkingSpots'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_ParkingSpots_ParkingLotID 
    ON AirportParkingSystem.ParkingSpots(ParkingLotID)
    INCLUDE (SpotID, SpotNumber, IsReserved);
    PRINT 'IX_ParkingSpots_ParkingLotID index oluşturuldu.';
END
ELSE
BEGIN
    PRINT 'IX_ParkingSpots_ParkingLotID index zaten mevcut.';
END
GO

-- ParkingSpots tablosunda (ParkingLotID, SpotNumber) composite unique index (unique kontrolü için)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ParkingSpots_ParkingLotID_SpotNumber' AND object_id = OBJECT_ID('AirportParkingSystem.ParkingSpots'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX IX_ParkingSpots_ParkingLotID_SpotNumber 
    ON AirportParkingSystem.ParkingSpots(ParkingLotID, SpotNumber);
    PRINT 'IX_ParkingSpots_ParkingLotID_SpotNumber unique index oluşturuldu.';
END
ELSE
BEGIN
    PRINT 'IX_ParkingSpots_ParkingLotID_SpotNumber index zaten mevcut.';
END
GO

-- ParkingSpots tablosundaki SpotID için index (MAX sorgusu için)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ParkingSpots_SpotID' AND object_id = OBJECT_ID('AirportParkingSystem.ParkingSpots'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_ParkingSpots_SpotID 
    ON AirportParkingSystem.ParkingSpots(SpotID);
    PRINT 'IX_ParkingSpots_SpotID index oluşturuldu.';
END
ELSE
BEGIN
    PRINT 'IX_ParkingSpots_SpotID index zaten mevcut.';
END
GO

PRINT 'Tüm index'ler kontrol edildi. AddParkingSpot procedure performansı artacak.';
GO

