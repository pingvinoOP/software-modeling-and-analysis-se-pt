SET NOCOUNT ON;
USE Cults3D_DB;
GO
GO
CREATE OR ALTER FUNCTION dbo.fn_GetAverageRating (@ModelID INT)
RETURNS DECIMAL(4,2)
AS
BEGIN
    DECLARE @Avg DECIMAL(4,2);
    SELECT @Avg = AVG(CAST(Score AS DECIMAL(4,2))) FROM dbo.Ratings WHERE ModelID = @ModelID;
    RETURN @Avg;
END;
GO
GO
CREATE OR ALTER FUNCTION dbo.fn_DesignerRevenue()
RETURNS TABLE
AS
RETURN
(
    SELECT d.DesignerID AS DesignerKey, u.Username AS DesignerName, SUM(p.Amount) AS TotalRevenue, COUNT(p.PurchaseID) AS PurchaseCount
    FROM dbo.Designers d
    JOIN dbo.Users u ON u.UserID = d.DesignerID
    LEFT JOIN dbo.Models m ON m.DesignerID = d.DesignerID
    LEFT JOIN dbo.Purchases p ON p.ModelID = m.ModelID
    GROUP BY d.DesignerID, u.Username
);
GO
GO
CREATE OR ALTER PROCEDURE dbo.sp_RecordPurchase
    @UserID INT,
    @ModelID INT,
    @Amount DECIMAL(10,2),
    @Currency CHAR(3) = 'USD',
    @PaymentMethod NVARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserID = @UserID)
    BEGIN
        RAISERROR ('Invalid UserID', 16, 1);
        RETURN;
    END;
    IF NOT EXISTS (SELECT 1 FROM dbo.Models WHERE ModelID = @ModelID)
    BEGIN
        RAISERROR ('Invalid ModelID', 16, 1);
        RETURN;
    END;
    INSERT INTO dbo.Purchases (UserID, ModelID, PurchaseDate, Amount, Currency, PaymentMethod)
    VALUES (@UserID, @ModelID, GETDATE(), @Amount, @Currency, @PaymentMethod);
    SELECT SCOPE_IDENTITY() AS NewPurchaseID;
END;
GO
GO
CREATE OR ALTER PROCEDURE dbo.sp_GetModelStats
    @ModelID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT m.ModelID, m.Title, SUM(p.Amount) AS TotalRevenue, COUNT(DISTINCT p.PurchaseID) AS PurchaseCount, COUNT(d.DownloadID) AS DownloadCount, dbo.fn_GetAverageRating(m.ModelID) AS AverageRating
    FROM dbo.Models m
    LEFT JOIN dbo.Purchases p ON p.ModelID = m.ModelID
    LEFT JOIN dbo.Downloads d ON d.ModelID = m.ModelID
    WHERE m.ModelID = @ModelID
    GROUP BY m.ModelID, m.Title, dbo.fn_GetAverageRating(m.ModelID);
END;
GO
IF OBJECT_ID(N'dbo.DownloadsAudit', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DownloadsAudit (
        AuditID INT IDENTITY(1,1) PRIMARY KEY,
        DownloadID INT,
        UserID INT,
        ModelID INT,
        DownloadDate DATETIME,
        Source NVARCHAR(30),
        LoggedAt DATETIME NOT NULL DEFAULT(GETDATE())
    );
END;
GO
GO
CREATE OR ALTER TRIGGER dbo.trg_Ratings_UpdateModelAverage
ON dbo.Ratings
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH ChangedModels AS (
        SELECT ModelID FROM inserted
        UNION
        SELECT ModelID FROM deleted
    )
    UPDATE m
    SET m.AverageRating = dbo.fn_GetAverageRating(m.ModelID)
    FROM dbo.Models m
    INNER JOIN ChangedModels cm ON cm.ModelID = m.ModelID;
END;
GO
GO
CREATE OR ALTER TRIGGER dbo.trg_Downloads_Audit
ON dbo.Downloads
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.DownloadsAudit (DownloadID, UserID, ModelID, DownloadDate, Source)
    SELECT i.DownloadID, i.UserID, i.ModelID, i.DownloadDate, i.Source FROM inserted i;
END;
GO
