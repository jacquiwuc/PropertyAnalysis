USE [PropertyDW_Advanced]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CalculateDistanceSubToStop]
AS 
BEGIN

DECLARE @GeoAltKey int;
DECLARE @fromsuburb nvarchar(50);
DECLARE @fromsuburblat float;
DECLARE @fromsuburblong float;
DEClARE @GeoDistance geography
DECLARE FromSuburb_Cursor CURSOR FOR SELECT DISTINCT 
dg.geographyAltkey,dg.Suburb,dg.Latitude,dg.Longitude
FROM DimGeography dg ORDER BY dg.GeographyAltKey;

OPEN FromSuburb_Cursor;
FETCH NEXT FROM FromSuburb_Cursor INTO @GeoAltKey, @fromsuburb, @fromsuburblat,@fromsuburblong;
WHILE @@FETCH_STATUS=0
   BEGIN
   SET @GeoDistance=Geography::Point(@fromsuburblat,@fromsuburblong,4326);

DECLARE @TransportAltKey int;
DECLARE @StopName nvarchar(50);
DECLARE @Suburb nvarchar(50);
DECLARE @nearestdistance float;
DECLARE Stop_Cursor CURSOR FOR SELECT DISTINCT 
  dt.TransportAltKey,dt.StopName,dt.suburb,
(@GeoDistance.STDistance(geography::Point(ISNULL(dt.StopLat,0),ISNULL(dt.StopLon,0),4326)))/1000 AS distance
FROM DimTransport dt
WHERE (@GeoDistance.STDistance(geography::Point(ISNULL(dt.StopLat,0),ISNULL(dt.StopLon,0),4326)))/1000>0 AND
(@GeoDistance.STDistance(geography::Point(ISNULL(dt.StopLat,0),ISNULL(dt.StopLon,0),4326)))/1000<=1

OPEN Stop_Cursor;
FETCH NEXT FROM Stop_Cursor INTO @TransportAltKey, @StopName, @Suburb, @nearestdistance;
WHILE @@FETCH_STATUS=0
  Begin
     INSERT INTO StopDistance(Fromsuburbid,FromsuburbName,Tosuburbid,Tosuburbname,StopName,Distance)
     values (@GeoAltKey,@fromsuburb,@TransportAltKey,@Suburb,@StopName,@nearestdistance);
     Fetch Next from Stop_Cursor into @TransportAltKey, @StopName, @Suburb, @nearestdistance;
  END;
Close Stop_Cursor;
Deallocate Stop_Cursor;
    Fetch Next From FromSuburb_Cursor into @GeoAltKey, @fromsuburb, @fromsuburblat,@fromsuburblong;
END;
Close FromSuburb_Cursor;
Deallocate FromSuburb_Cursor;
END

GO

EXEC [dbo].[CalculateDistanceSubToStop]