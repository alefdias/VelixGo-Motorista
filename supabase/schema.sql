-- ==============================================================================
-- VELIX GO — SUPABASE SCHEMA & BUSINESS LOGIC
-- PostgreSQL + RLS + Realtime + Triggers
-- ==============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 1. PROFILES TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT,
    phone TEXT,
    avatar_url TEXT,
    role TEXT CHECK (role IN ('passenger', 'driver', 'unselected')) DEFAULT 'unselected',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ------------------------------------------------------------------------------
-- 2. PASSENGERS TABLE (Preferências e locais favoritos)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.passengers (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    home_address TEXT,
    home_lat DOUBLE PRECISION,
    home_lng DOUBLE PRECISION,
    work_address TEXT,
    work_lat DOUBLE PRECISION,
    work_lng DOUBLE PRECISION,
    default_payment_method TEXT DEFAULT 'pix' CHECK (default_payment_method IN ('pix', 'cash', 'card_machine')),
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ------------------------------------------------------------------------------
-- 3. DRIVERS TABLE (Dados cadastrais, veículo e saldo Velix)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.drivers (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    cnh_number TEXT,
    vehicle_type TEXT CHECK (vehicle_type IN ('car', 'motorcycle')) DEFAULT 'car',
    vehicle_model TEXT,
    vehicle_plate TEXT,
    vehicle_color TEXT,
    vehicle_year TEXT,
    cnh_doc_url TEXT,
    vehicle_doc_url TEXT,
    is_verified BOOLEAN DEFAULT false,
    is_online BOOLEAN DEFAULT false,
    current_balance NUMERIC(10,2) DEFAULT 0.00 NOT NULL, -- Saldo devedor de taxas (R$ 0,50 por corrida)
    last_billed_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    rating_avg NUMERIC(3,2) DEFAULT 5.00,
    total_rides INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ------------------------------------------------------------------------------
-- 4. DRIVER LOCATIONS TABLE (Localização em tempo real)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.driver_locations (
    driver_id UUID PRIMARY KEY REFERENCES public.drivers(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    heading DOUBLE PRECISION DEFAULT 0.0,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ------------------------------------------------------------------------------
-- 5. RIDES TABLE (Corridas e despacho com prioridade)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.rides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    passenger_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    status TEXT NOT NULL CHECK (status IN ('requested', 'accepted', 'arrived', 'in_progress', 'completed', 'cancelled')) DEFAULT 'requested',
    vehicle_type TEXT CHECK (vehicle_type IN ('car', 'motorcycle')) DEFAULT 'car',
    origin_address TEXT NOT NULL,
    origin_lat DOUBLE PRECISION NOT NULL,
    origin_lng DOUBLE PRECISION NOT NULL,
    destination_address TEXT NOT NULL,
    destination_lat DOUBLE PRECISION NOT NULL,
    destination_lng DOUBLE PRECISION NOT NULL,
    distance_km NUMERIC(6,2) NOT NULL,
    estimated_duration_min INT NOT NULL,
    estimated_fare NUMERIC(10,2) NOT NULL,
    actual_fare NUMERIC(10,2),
    payment_method TEXT NOT NULL CHECK (payment_method IN ('pix', 'cash', 'card_machine')) DEFAULT 'pix',
    priority_until TIMESTAMPTZ, -- Janela de 15 segundos exclusiva para favoritos
    favorite_driver_notified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ------------------------------------------------------------------------------
-- 6. FAVORITE DRIVERS TABLE (Motoristas favoritos de cada passageiro)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.favorite_drivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    passenger_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(passenger_id, driver_id)
);

-- ------------------------------------------------------------------------------
-- 7. RATINGS TABLE (Avaliações de 1 a 5 estrelas)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID NOT NULL REFERENCES public.rides(id) ON DELETE CASCADE,
    passenger_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    score INT NOT NULL CHECK (score >= 1 AND score <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ------------------------------------------------------------------------------
-- 8. INVOICES TABLE (Faturas do Saldo Velix para motoristas)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(10,2) NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'paid', 'overdue')) DEFAULT 'pending',
    pix_copy_paste TEXT NOT NULL,
    pix_qr_code TEXT,
    due_date TIMESTAMPTZ NOT NULL,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ------------------------------------------------------------------------------
-- 9. PAYMENTS TABLE (Histórico de quitação de faturas Pix)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(10,2) NOT NULL,
    paid_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    receipt_url TEXT
);

-- ==============================================================================
-- TRIGGERS E FUNÇÕES DE NEGÓCIO
-- ==============================================================================

-- 1. Criação automática de Perfil ao criar conta no Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, email, phone, avatar_url, role)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'full_name', 'Usuário Velix'),
        new.email,
        new.raw_user_meta_data->>'phone',
        new.raw_user_meta_data->>'avatar_url',
        COALESCE(new.raw_user_meta_data->>'role', 'unselected')
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- 2. Conclusão da Corrida:
-- - Adiciona taxa de R$ 0,50 no saldo do motorista
-- - Incrementa total de corridas
-- - Verifica se saldo atingiu R$ 20,00 OU passaram 15 dias da última fatura
-- - Se sim, gera fatura PIX e zera saldo acumulado
CREATE OR REPLACE FUNCTION public.handle_ride_completed()
RETURNS trigger AS $$
DECLARE
    v_driver_id UUID;
    v_new_balance NUMERIC(10,2);
    v_last_billed TIMESTAMPTZ;
    v_days_since_billed NUMERIC;
    v_invoice_id UUID;
    v_pix_code TEXT;
BEGIN
    -- Dispara somente quando a corrida mudar para 'completed'
    IF (OLD.status <> 'completed' AND NEW.status = 'completed' AND NEW.driver_id IS NOT NULL) THEN
        v_driver_id := NEW.driver_id;
        
        -- Atualiza motorista adicionando R$ 0.50 e obtém saldo atualizado
        UPDATE public.drivers
        SET current_balance = current_balance + 0.50,
            total_rides = total_rides + 1
        WHERE id = v_driver_id
        RETURNING current_balance, last_billed_at INTO v_new_balance, v_last_billed;

        -- Calcula diferença de dias
        v_days_since_billed := EXTRACT(EPOCH FROM (now() - v_last_billed)) / 86400;

        -- Regra: Atingir R$ 20,00 OU completar 15 dias (com saldo > 0)
        IF (v_new_balance >= 20.00 OR (v_days_since_billed >= 15 AND v_new_balance > 0.00)) THEN
            v_invoice_id := gen_random_uuid();
            -- Simulação de string Pix Copia e Cola padrão BACEN (EMV)
            v_pix_code := '00020126580014BR.GOV.BCB.PIX0136velixgo-taxas@velixgo.com.br520400005303986540' 
                          || TO_CHAR(v_new_balance, 'FM999990.00') 
                          || '5802BR5908VELIX GO6009SAO PAULO62070503***6304';

            -- Cria a fatura pendente
            INSERT INTO public.invoices (
                id, driver_id, amount, status, pix_copy_paste, pix_qr_code, due_date
            ) VALUES (
                v_invoice_id,
                v_driver_id,
                v_new_balance,
                'pending',
                v_pix_code,
                v_pix_code,
                now() + INTERVAL '3 days'
            );

            -- Zera o saldo e atualiza a data da última cobrança
            UPDATE public.drivers
            SET current_balance = 0.00,
                last_billed_at = now()
            WHERE id = v_driver_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_ride_completed ON public.rides;
CREATE TRIGGER on_ride_completed
    AFTER UPDATE ON public.rides
    FOR EACH ROW EXECUTE PROCEDURE public.handle_ride_completed();


-- 3. Atualização automática de média de avaliação do motorista
CREATE OR REPLACE FUNCTION public.handle_rating_update()
RETURNS trigger AS $$
DECLARE
    v_avg NUMERIC(3,2);
BEGIN
    SELECT ROUND(AVG(score)::numeric, 2)
    INTO v_avg
    FROM public.ratings
    WHERE driver_id = NEW.driver_id;

    UPDATE public.drivers
    SET rating_avg = COALESCE(v_avg, 5.00)
    WHERE id = NEW.driver_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_rating_created ON public.ratings;
CREATE TRIGGER on_rating_created
    AFTER INSERT ON public.ratings
    FOR EACH ROW EXECUTE PROCEDURE public.handle_rating_update();


-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.passengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorite_drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- PROFILES
CREATE POLICY "Profiles são visíveis por usuários autenticados" 
    ON public.profiles FOR SELECT TO authenticated USING (true);

CREATE POLICY "Usuário pode editar apenas seu próprio profile" 
    ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

CREATE POLICY "Usuário pode inserir seu próprio profile" 
    ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

-- PASSENGERS
CREATE POLICY "Passageiro gerencia seu próprio perfil" 
    ON public.passengers FOR ALL TO authenticated USING (auth.uid() = id);

-- DRIVERS
CREATE POLICY "Informações de motorista visíveis para autenticados" 
    ON public.drivers FOR SELECT TO authenticated USING (true);

CREATE POLICY "Motorista gerencia seu próprio registro" 
    ON public.drivers FOR ALL TO authenticated USING (auth.uid() = id);

-- DRIVER LOCATIONS
CREATE POLICY "Localizações visíveis para autenticados" 
    ON public.driver_locations FOR SELECT TO authenticated USING (true);

CREATE POLICY "Motorista atualiza sua própria localização" 
    ON public.driver_locations FOR ALL TO authenticated USING (auth.uid() = driver_id);

-- RIDES
CREATE POLICY "Visualização de corridas para passageiro ou motorista da corrida"
    ON public.rides FOR SELECT TO authenticated
    USING (
        auth.uid() = passenger_id 
        OR auth.uid() = driver_id 
        OR (status = 'requested' AND (
            -- Corrida pública liberada após 15s ou se não houver prioridade
            priority_until IS NULL 
            OR priority_until <= now() 
            -- Ou se o motorista estiver nos favoritos do passageiro
            OR EXISTS (
                SELECT 1 FROM public.favorite_drivers fd 
                WHERE fd.passenger_id = rides.passenger_id AND fd.driver_id = auth.uid()
            )
        ))
    );

CREATE POLICY "Passageiro pode solicitar corrida"
    ON public.rides FOR INSERT TO authenticated WITH CHECK (auth.uid() = passenger_id);

CREATE POLICY "Atualização de corrida pelo passageiro ou motorista vinculado"
    ON public.rides FOR UPDATE TO authenticated
    USING (
        auth.uid() = passenger_id 
        OR auth.uid() = driver_id 
        OR (status = 'requested' AND driver_id IS NULL) -- Para motorista poder aceitar
    );

-- FAVORITE DRIVERS
CREATE POLICY "Passageiro gerencia seus favoritos" 
    ON public.favorite_drivers FOR ALL TO authenticated USING (auth.uid() = passenger_id);

CREATE POLICY "Motorista pode visualizar quem o favoritou" 
    ON public.favorite_drivers FOR SELECT TO authenticated USING (auth.uid() = driver_id);

-- RATINGS
CREATE POLICY "Avaliações visíveis para autenticados" 
    ON public.ratings FOR SELECT TO authenticated USING (true);

CREATE POLICY "Passageiro insere avaliação" 
    ON public.ratings FOR INSERT TO authenticated WITH CHECK (auth.uid() = passenger_id);

-- INVOICES
CREATE POLICY "Motorista visualiza suas faturas" 
    ON public.invoices FOR SELECT TO authenticated USING (auth.uid() = driver_id);

CREATE POLICY "Motorista pode atualizar status da fatura ao pagar" 
    ON public.invoices FOR UPDATE TO authenticated USING (auth.uid() = driver_id);

-- PAYMENTS
CREATE POLICY "Motorista visualiza e insere pagamentos" 
    ON public.payments FOR ALL TO authenticated USING (auth.uid() = driver_id);

-- ==============================================================================
-- SUPABASE REALTIME CONFIGURATION
-- ==============================================================================

-- Habilita o realtime nas tabelas que requerem sincronização ao vivo
ALTER PUBLICATION supabase_realtime ADD TABLE public.rides;
ALTER PUBLICATION supabase_realtime ADD TABLE public.driver_locations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.invoices;

-- ==============================================================================
-- STORAGE BUCKETS (Documentos e Fotos)
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('driver_documents', 'driver_documents', false)
ON CONFLICT (id) DO NOTHING;

-- Policies de Storage
CREATE POLICY "Fotos de perfil públicas" 
    ON storage.objects FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Usuário envia sua própria foto de perfil" 
    ON storage.objects FOR INSERT TO authenticated 
    WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Motorista acessa seus próprios documentos" 
    ON storage.objects FOR ALL TO authenticated 
    USING (bucket_id = 'driver_documents' AND auth.uid()::text = (storage.foldername(name))[1]);
