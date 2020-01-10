USE [Property_Advanced]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--get the nearest suburb name and postcode name according to the stop in the publictransport table

CREATE PROCEDURE [dbo].[StationForSuburb]
AS
BEGIN
    DECLARE station_cursor CURSOR FOR SELECT PublicTransport.Stop_Lat, PublicTransport.Stop_Lon FROM PublicTransport 
    ORDER BY Stop_Id FOR UPDATE OF PublicTransport.postcode, PublicTransport.suburb;

    DECLARE @geo1 geography;
    DECLARE @stationlat float;
    DECLARE @stationlong float;

open station_cursor;

FETCH NEXT FROM station_cursor into @stationlat, @stationlong;

WHILE @@FETCH_STATUS=0

BEGIN

SET @geo1=geography::Point(@stationlat,@stationlong,4326);

DECLARE nearestSub_cursor CURSOR FOR SELECT Suburb.PostCode,Suburb.SuburbName FROM Suburb
   
INNER JOIN (SELECT TOP 1 Suburb.id, min((@geo1.STDistance(geography::Point(ISNULL(Suburb.Lat,0),
ISNULL(Suburb.Lon,0), 4326)))) mindistance
FROM Suburb
GROUP BY Suburb.Id 
ORDER BY mindistance asc) rs
ON Suburb.Id=rs.Id;
DECLARE @nearestpostcode nvarchar(5);
DECLARE @nearestsuburb nvarchar(50);
OPEN nearestSub_cursor;

FETCH NEXT FROM nearestSub_cursor INTO @nearestpostcode,@nearestsuburb ;

--loop until records are available

WHILE @@FETCH_STATUS=0
BEGIN
PRINT @nearestpostcode+','+@nearestsuburb;

UPDATE PublicTransport SET suburb=@nearestsuburb, postcode=@nearestpostcode WHERE current of station_cursor;
FETCH NEXT FROM nearestSub_cursor INTO @nearestpostcode,@nearestsuburb ;
END;
CLOSE nearestSub_cursor;
DEALLOCATE nearestSub_cursor;
FETCH NEXT FROM station_cursor INTO @stationlat,@stationlong;
END;
CLOSE station_cursor;
DEALLOCATE station_cursor;
END
GO

