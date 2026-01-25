-- Terragrunt State Database Setup Script
-- Run this on PostgreSQL server: psql -U jimmy -h 192.168.68.120 -p 5432 -f setup-postgres.sql

-- Create database for Tofu state
CREATE DATABASE tofu_state;

-- Connect to the new database
\c tofu_state

-- Create schemas for environments
CREATE SCHEMA IF NOT EXISTS dev_single_node;
CREATE SCHEMA IF NOT EXISTS prod_single_node;

-- Grant permissions to jimmy user
GRANT CREATE ON SCHEMA public TO jimmy;
GRANT ALL ON ALL TABLES IN SCHEMA public TO jimmy;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO jimmy;
GRANT ALL ON SCHEMA dev_single_node TO jimmy;
GRANT ALL ON SCHEMA prod_single_node TO jimmy;
GRANT ALL ON ALL TABLES IN SCHEMA dev_single_node TO jimmy;
GRANT ALL ON ALL TABLES IN SCHEMA prod_single_node TO jimmy;

-- Show completion message
SELECT 'Database setup complete!' as status;
