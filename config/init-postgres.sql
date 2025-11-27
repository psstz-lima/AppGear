-- AppGear - PostgreSQL Initialization Script
-- This script creates necessary schemas and tables

-- Create extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create schema for Flowise
CREATE SCHEMA IF NOT EXISTS flowise;
GRANT ALL PRIVILEGES ON SCHEMA flowise TO appgear;

-- Create schema for n8n
CREATE SCHEMA IF NOT EXISTS n8n;
GRANT ALL PRIVILEGES ON SCHEMA n8n TO appgear;

-- Create schema for LiteLLM
CREATE SCHEMA IF NOT EXISTS litellm;
GRANT ALL PRIVILEGES ON SCHEMA litellm TO appgear;

-- Create schema for AppGear applications
CREATE SCHEMA IF NOT EXISTS apps;
GRANT ALL PRIVILEGES ON SCHEMA apps TO appgear;

-- Create basic tables for multi-tenancy
CREATE TABLE IF NOT EXISTS public.tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.workspaces (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, name)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_workspaces_tenant_id ON public.workspaces(tenant_id);

-- Insert default tenant for development
INSERT INTO public.tenants (id, name) 
VALUES ('00000000-0000-0000-0000-000000000001', 'default')
ON CONFLICT (name) DO NOTHING;

-- Insert default workspace
INSERT INTO public.workspaces (id, tenant_id, name)
VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'development')
ON CONFLICT (tenant_id, name) DO NOTHING;
