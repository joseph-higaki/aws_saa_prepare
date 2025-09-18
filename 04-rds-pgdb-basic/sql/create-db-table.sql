DROP DATABASE IF EXISTS person_db; 

-- Complete script with database creation
CREATE DATABASE person_db;

\c person_db;

-- Create person table
CREATE TABLE person (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert 10 sample records
INSERT INTO person (first_name, last_name) VALUES
('John', 'Smith'),
('Emma', 'Johnson'),
('Michael', 'Williams'),
('Sophia', 'Brown'),
('James', 'Jones'),
('Olivia', 'Garcia'),
('Robert', 'Miller'),
('Ava', 'Davis'),
('William', 'Rodriguez'),
('Isabella', 'Martinez');


-- Verify the data
SELECT * FROM person ORDER BY last_name;