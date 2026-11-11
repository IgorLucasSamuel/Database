-- EasyTravel business reports
-- Based on the tables and fields shown in the ER diagram.
-- Assumes SQLite and payment_status values including 'Paid'.


-- ================================================================
-- REPORT 1: BOOKING DETAILS
-- One row per confirmed booking.
-- ================================================================
WITH package_details AS (
    SELECT
        bp.booking_id,
        GROUP_CONCAT(DISTINCT p.package_name) AS packages,
        GROUP_CONCAT(DISTINCT d.destination_name) AS destinations,
        GROUP_CONCAT(DISTINCT h.hotel_name) AS hotels
    FROM Booking_Package bp
    JOIN Package p
        ON p.package_id = bp.package_id
    JOIN Destination d
        ON d.destination_id = p.destination_id
    LEFT JOIN Package_Hotel ph
        ON ph.package_id = p.package_id
    LEFT JOIN Hotel h
        ON h.hotel_id = ph.hotel_id
    GROUP BY bp.booking_id
),
flight_details AS (
    SELECT
        bf.booking_id,
        GROUP_CONCAT(DISTINCT f.flight_number) AS flight_numbers,
        GROUP_CONCAT(DISTINCT f.airline) AS airlines,
        GROUP_CONCAT(DISTINCT bf.seat_class) AS seat_classes
    FROM Booking_Flight bf
    JOIN Flight f
        ON f.flight_id = bf.flight_id
    GROUP BY bf.booking_id
)
SELECT
    b.booking_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email AS customer_email,
    pd.packages,
    pd.destinations,
    pd.hotels,
    fd.flight_numbers,
    fd.airlines,
    fd.seat_classes,
    b.booking_date,
    b.travel_date,
    b.return_date,
    b.total_amount,
    b.booking_status,
    b.payment_status
FROM Booking b
JOIN Customer c
    ON c.customer_id = b.customer_id
LEFT JOIN package_details pd
    ON pd.booking_id = b.booking_id
LEFT JOIN flight_details fd
    ON fd.booking_id = b.booking_id
WHERE b.booking_status = 'Confirmed'
ORDER BY b.booking_date DESC
LIMIT 10;


-- ================================================================
-- REPORT 2: BOOKED PACKAGE VALUE BY DESTINATION
-- This is package value, not necessarily total money collected.
-- ================================================================
SELECT
    d.destination_name,
    d.country,
    COUNT(DISTINCT b.booking_id) AS paid_bookings,
    SUM(p.price * bp.quantity) AS booked_package_value
FROM Destination d
JOIN Package p
    ON p.destination_id = d.destination_id
JOIN Booking_Package bp
    ON bp.package_id = p.package_id
JOIN Booking b
    ON b.booking_id = bp.booking_id
WHERE b.payment_status = 'Paid'
GROUP BY
    d.destination_id,
    d.destination_name,
    d.country
ORDER BY booked_package_value DESC
LIMIT 10;


-- ================================================================
-- REPORT 3: CUSTOMER LOYALTY
-- Booking and review totals are calculated separately to avoid
-- multiplying booking amounts when a customer has multiple reviews.
-- ================================================================
WITH booking_summary AS (
    SELECT
        customer_id,
        COUNT(*) AS total_paid_bookings,
        SUM(total_amount) AS lifetime_paid_value,
        ROUND(AVG(total_amount), 2) AS average_paid_booking_value,
        MAX(booking_date) AS last_booking_date
    FROM Booking
    WHERE payment_status = 'Paid'
    GROUP BY customer_id
),
review_summary AS (
    SELECT
        customer_id,
        COUNT(review_id) AS reviews_written,
        ROUND(AVG(rating), 2) AS average_review_rating
    FROM Review
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    c.loyalty_points,
    CASE
        WHEN c.loyalty_points >= 400 THEN 'Platinum'
        WHEN c.loyalty_points >= 250 THEN 'Gold'
        WHEN c.loyalty_points >= 150 THEN 'Silver'
        ELSE 'Bronze'
    END AS loyalty_tier,
    bs.total_paid_bookings,
    bs.lifetime_paid_value,
    bs.average_paid_booking_value,
    bs.last_booking_date,
    COALESCE(rs.reviews_written, 0) AS reviews_written,
    rs.average_review_rating
FROM Customer c
JOIN booking_summary bs
    ON bs.customer_id = c.customer_id
LEFT JOIN review_summary rs
    ON rs.customer_id = c.customer_id
ORDER BY
    bs.lifetime_paid_value DESC,
    c.loyalty_points DESC
LIMIT 15;

SELECT 'Booking' AS table_name,
       COUNT(*) AS row_count,
       MIN(booking_id) AS min_booking_id,
       MAX(booking_id) AS max_booking_id
FROM Booking

UNION ALL

SELECT 'Booking_Package',
       COUNT(*),
       MIN(booking_id),
       MAX(booking_id)
FROM Booking_Package

UNION ALL

SELECT 'Booking_Flight',
       COUNT(*),
       MIN(booking_id),
       MAX(booking_id)
FROM Booking_Flight;

SELECT
    'Booking_Package' AS table_name,
    COUNT(*) AS link_rows,
    COUNT(b.booking_id) AS matching_bookings_after_offset
FROM Booking_Package bp
LEFT JOIN Booking b
    ON b.booking_id = bp.booking_id + 30

UNION ALL

SELECT
    'Booking_Flight',
    COUNT(*),
    COUNT(b.booking_id)
FROM Booking_Flight bf
LEFT JOIN Booking b
    ON b.booking_id = bf.booking_id + 30;

UPDATE Booking_Package
SET booking_id = booking_id + 30
WHERE booking_id BETWEEN 1 AND 30
  AND EXISTS (
      SELECT 1
      FROM Booking b
      WHERE b.booking_id = Booking_Package.booking_id + 30
  );

UPDATE Booking_Flight
SET booking_id = booking_id + 30
WHERE booking_id BETWEEN 1 AND 30
  AND EXISTS (
      SELECT 1
      FROM Booking b
      WHERE b.booking_id = Booking_Flight.booking_id + 30
  );

UPDATE Booking_Flight
SET booking_id = booking_id + 30
WHERE booking_id BETWEEN 1 AND 30
  AND EXISTS (
      SELECT 1
      FROM Booking b
      WHERE b.booking_id = Booking_Flight.booking_id + 30
  );

SELECT 'Booking_Package' AS table_name,
       COUNT(*) AS link_rows,
       COUNT(b.booking_id) AS matched_bookings
FROM Booking_Package bp
LEFT JOIN Booking b ON b.booking_id = bp.booking_id

UNION ALL

SELECT 'Booking_Flight',
       COUNT(*),
       COUNT(b.booking_id)
FROM Booking_Flight bf
LEFT JOIN Booking b ON b.booking_id = bf.booking_id;

SELECT
    'Booking_Package to Package' AS relationship,
    COUNT(*) AS link_rows,
    COUNT(p.package_id) AS matched_records
FROM Booking_Package bp
LEFT JOIN Package p
    ON p.package_id = bp.package_id

UNION ALL

SELECT
    'Booking_Flight to Flight',
    COUNT(*),
    COUNT(f.flight_id)
FROM Booking_Flight bf
LEFT JOIN Flight f
    ON f.flight_id = bf.flight_id

UNION ALL

SELECT
    'Package_Hotel to Hotel',
    COUNT(*),
    COUNT(h.hotel_id)
FROM Package_Hotel ph
LEFT JOIN Hotel h
    ON h.hotel_id = ph.hotel_id

UNION ALL

SELECT
    'Package to Destination',
    COUNT(*),
    COUNT(d.destination_id)
FROM Package p
LEFT JOIN Destination d
    ON d.destination_id = p.destination_id;

SELECT 'Package.package_id' AS id_source,
       COUNT(*) AS row_count,
       MIN(package_id) AS min_id,
       MAX(package_id) AS max_id
FROM Package

UNION ALL
SELECT 'Booking_Package.package_id', COUNT(*), MIN(package_id), MAX(package_id)
FROM Booking_Package

UNION ALL
SELECT 'Package_Hotel.package_id', COUNT(*), MIN(package_id), MAX(package_id)
FROM Package_Hotel

UNION ALL
SELECT 'Flight.flight_id', COUNT(*), MIN(flight_id), MAX(flight_id)
FROM Flight

UNION ALL
SELECT 'Booking_Flight.flight_id', COUNT(*), MIN(flight_id), MAX(flight_id)
FROM Booking_Flight

UNION ALL
SELECT 'Hotel.hotel_id', COUNT(*), MIN(hotel_id), MAX(hotel_id)
FROM Hotel

UNION ALL
SELECT 'Package_Hotel.hotel_id', COUNT(*), MIN(hotel_id), MAX(hotel_id)
FROM Package_Hotel

UNION ALL
SELECT 'Destination.destination_id', COUNT(*), MIN(destination_id), MAX(destination_id)
FROM Destination

UNION ALL
SELECT 'Package.destination_id', COUNT(*), MIN(destination_id), MAX(destination_id)
FROM Package;

SELECT
    'Booking_Package to Package (+30)' AS relationship,
    COUNT(*) AS link_rows,
    COUNT(p.package_id) AS proposed_matches
FROM Booking_Package bp
LEFT JOIN Package p
    ON p.package_id = bp.package_id + 30

UNION ALL

SELECT
    'Package_Hotel to Package (+30)',
    COUNT(*),
    COUNT(p.package_id)
FROM Package_Hotel ph
LEFT JOIN Package p
    ON p.package_id = ph.package_id + 30

UNION ALL

SELECT
    'Package_Hotel to Hotel (+60)',
    COUNT(*),
    COUNT(h.hotel_id)
FROM Package_Hotel ph
LEFT JOIN Hotel h
    ON h.hotel_id = ph.hotel_id + 60

UNION ALL

SELECT
    'Booking_Flight to Flight (+30)',
    COUNT(*),
    COUNT(f.flight_id)
FROM Booking_Flight bf
LEFT JOIN Flight f
    ON f.flight_id = bf.flight_id + 30

UNION ALL

SELECT
    'Package to Destination (+60)',
    COUNT(*),
    COUNT(d.destination_id)
FROM Package p
LEFT JOIN Destination d
    ON d.destination_id = p.destination_id + 60;

SELECT
    'Booking_Package to Package (+30)' AS relationship,
    COUNT(*) AS link_rows,
    COUNT(p.package_id) AS proposed_matches
FROM Booking_Package bp
LEFT JOIN Package p
    ON p.package_id = bp.package_id + 30

UNION ALL

SELECT
    'Package_Hotel to Package (+30)',
    COUNT(*),
    COUNT(p.package_id)
FROM Package_Hotel ph
LEFT JOIN Package p
    ON p.package_id = ph.package_id + 30

UNION ALL

SELECT
    'Package_Hotel to Hotel (+60)',
    COUNT(*),
    COUNT(h.hotel_id)
FROM Package_Hotel ph
LEFT JOIN Hotel h
    ON h.hotel_id = ph.hotel_id + 60

UNION ALL

SELECT
    'Booking_Flight to Flight (+30)',
    COUNT(*),
    COUNT(f.flight_id)
FROM Booking_Flight bf
LEFT JOIN Flight f
    ON f.flight_id = bf.flight_id + 30

UNION ALL

SELECT
    'Package to Destination (+60)',
    COUNT(*),
    COUNT(d.destination_id)
FROM Package p
LEFT JOIN Destination d
    ON d.destination_id = p.destination_id + 60;
