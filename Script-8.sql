-- ================================================================
-- ADD PACKAGE_HOTEL AND BOOKING_FLIGHT TABLES (SAFE VERSION)
-- Drops existing tables first, then recreates with data
-- ================================================================

-- ================================================================
-- STEP 1: DROP EXISTING TABLES IF THEY EXIST
-- ================================================================
DROP TABLE IF EXISTS Package_Hotel;
DROP TABLE IF EXISTS Booking_Flight;

-- ================================================================
-- STEP 2: CREATE PACKAGE_HOTEL TABLE
-- ================================================================
CREATE TABLE Package_Hotel (
    package_id INTEGER,
    hotel_id INTEGER,
    nights INTEGER NOT NULL,
    PRIMARY KEY (package_id, hotel_id),
    FOREIGN KEY (package_id) REFERENCES Package(package_id),
    FOREIGN KEY (hotel_id) REFERENCES Hotel(hotel_id)
);

-- ================================================================
-- STEP 3: CREATE BOOKING_FLIGHT TABLE
-- ================================================================
CREATE TABLE Booking_Flight (
    booking_id INTEGER,
    flight_id INTEGER,
    seat_class TEXT DEFAULT 'Economy',
    PRIMARY KEY (booking_id, flight_id),
    FOREIGN KEY (booking_id) REFERENCES Booking(booking_id),
    FOREIGN KEY (flight_id) REFERENCES Flight(flight_id)
);

-- ================================================================
-- STEP 4: INSERT DATA INTO PACKAGE_HOTEL (30 rows)
-- Links each package to its corresponding hotel
-- ================================================================
INSERT INTO Package_Hotel (package_id, hotel_id, nights) VALUES
(1, 1, 6), (2, 2, 2), (3, 3, 9), (4, 4, 4), (5, 5, 6),
(6, 6, 5), (7, 7, 7), (8, 8, 4), (9, 9, 3), (10, 10, 5),
(11, 11, 4), (12, 12, 6), (13, 13, 3), (14, 14, 2), (15, 15, 8),
(16, 16, 5), (17, 17, 7), (18, 18, 4), (19, 19, 3), (20, 20, 2),
(21, 21, 4), (22, 22, 3), (23, 23, 7), (24, 24, 5), (25, 25, 3),
(26, 26, 2), (27, 27, 4), (28, 28, 3), (29, 29, 4), (30, 30, 6);

-- ================================================================
-- STEP 5: INSERT DATA INTO BOOKING_FLIGHT (30 rows)
-- Links each booking to its corresponding flight
-- ================================================================
INSERT INTO Booking_Flight (booking_id, flight_id, seat_class) VALUES
(1, 1, 'Economy'), (2, 2, 'Economy'), (3, 3, 'Business'), (4, 4, 'Economy'),
(5, 5, 'Premium Economy'), (6, 6, 'Business'), (7, 7, 'Economy'), (8, 8, 'Economy'),
(9, 9, 'Economy'), (10, 10, 'Economy'), (11, 11, 'Premium Economy'), (12, 12, 'Economy'),
(13, 13, 'Economy'), (14, 14, 'Business'), (15, 15, 'Economy'), (16, 16, 'Economy'),
(17, 17, 'Economy'), (18, 18, 'Premium Economy'), (19, 19, 'Economy'), (20, 20, 'Economy'),
(21, 21, 'Business'), (22, 22, 'Economy'), (23, 23, 'Economy'), (24, 24, 'Economy'),
(25, 25, 'Economy'), (26, 26, 'Economy'), (27, 27, 'Economy'), (28, 28, 'Economy'),
(29, 29, 'Premium Economy'), (30, 30, 'Business');

-- ================================================================
-- VERIFICATION QUERIES
-- ================================================================

-- Count all tables (should be 12)
SELECT COUNT(*) as total_tables FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';

-- List all 12 tables
SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;

-- Count rows in junction tables
SELECT 'Package_Hotel' as table_name, COUNT(*) as row_count FROM Package_Hotel
UNION ALL
SELECT 'Booking_Flight', COUNT(*) FROM Booking_Flight;

-- Test Package-Hotel relationship
SELECT 
    p.package_name,
    h.hotel_name,
    ph.nights || ' nights' as stay_duration
FROM Package_Hotel ph
JOIN Package p ON ph.package_id = p.package_id
JOIN Hotel h ON ph.hotel_id = h.hotel_id
LIMIT 5;

-- Test Booking-Flight relationship
SELECT 
    b.booking_id,
    c.first_name || ' ' || c.last_name as customer,
    f.flight_number,
    f.airline,
    bf.seat_class
FROM Booking_Flight bf
JOIN Booking b ON bf.booking_id = b.booking_id
JOIN Customer c ON b.customer_id = c.customer_id
JOIN Flight f ON bf.flight_id = f.flight_id
LIMIT 5;

-- ================================================================
-- SUCCESS! You now have 12 fully connected tables
-- ================================================================

