-- Optimize edilmiş UpdateSeat Procedure
-- Sadece ClassID güncellenecek (AircraftID ve SeatNumber değiştirilmeyecek)

CREATE PROCEDURE [FlightReservationSystem].[UpdateSeat]
    @SeatID INT,
    @ClassID INT,
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Koltuk var mı kontrol et
    IF NOT EXISTS (SELECT 1 FROM FlightReservationSystem.Seats WHERE SeatID = @SeatID)
    BEGIN
        RAISERROR('Koltuk bulunamadı.', 16, 1);
        RETURN;
    END

    -- Sadece ClassID'yi güncelle
    UPDATE FlightReservationSystem.Seats
    SET ClassID = @ClassID
    WHERE SeatID = @SeatID;

    -- Activity Log kaydı
    INSERT INTO GeneralCommon.ActivityLog
        (UserID, Action, Description, LogDate)
    VALUES
        (
            @UserID,
            'UPDATE_SEAT',
            CONCAT('Koltuk güncellendi. SeatID: ', @SeatID, ', ClassID: ', @ClassID),
            GETDATE()
        );
END;
GO
