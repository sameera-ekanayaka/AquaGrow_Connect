-- Migration 005: Add farm_name and phone to user profiles
alter table public.profiles add column if not exists farm_name text;
alter table public.profiles add column if not exists phone text;
