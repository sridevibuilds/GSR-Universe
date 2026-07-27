-- Module 1 Database Schema Enhancements

-- 1. Create OTP storage table
CREATE TABLE IF NOT EXISTS public.otps (
    id SERIAL PRIMARY KEY,
    mobile VARCHAR(15) NOT NULL,
    otp_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    attempts INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Create FCM tokens table
CREATE TABLE IF NOT EXISTS public.fcm_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('ADMIN', 'FACULTY', 'PARENT')),
    token TEXT NOT NULL,
    device_info TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_token_per_user UNIQUE (user_id, role, token)
);

-- 3. Create Call settings table for automated fee reminders
CREATE TABLE IF NOT EXISTS public.call_settings (
    id SERIAL PRIMARY KEY,
    is_enabled BOOLEAN DEFAULT false,
    schedule_day_start INTEGER DEFAULT 1 CHECK (schedule_day_start >= 1 AND schedule_day_start <= 28),
    schedule_day_end INTEGER DEFAULT 7 CHECK (schedule_day_end >= 1 AND schedule_day_end <= 28),
    calling_number VARCHAR(20),
    twilio_account_sid VARCHAR(100),
    twilio_auth_token VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default single record if not exists
INSERT INTO public.call_settings (id, is_enabled, schedule_day_start, schedule_day_end, calling_number)
SELECT 1, false, 1, 7, ''
WHERE NOT EXISTS (SELECT 1 FROM public.call_settings WHERE id = 1);

-- 4. Create Call history log table
CREATE TABLE IF NOT EXISTS public.call_history (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    academic_year_id INTEGER NOT NULL REFERENCES public.academic_years(id) ON DELETE CASCADE,
    parent_mobile VARCHAR(15) NOT NULL,
    amount_due NUMERIC(10,2) NOT NULL,
    call_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'Initiated' CHECK (status IN ('Initiated', 'Queued', 'In-Progress', 'Answered', 'Busy', 'No-Answer', 'Failed')),
    duration INTEGER DEFAULT 0,
    provider_call_sid VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Add session column to attendance table if not exists
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS session VARCHAR(20) DEFAULT 'Morning' CONSTRAINT chk_attendance_session CHECK (session IN ('Morning', 'Afternoon'));

-- 6. Add indexes on foreign keys and search columns
CREATE INDEX IF NOT EXISTS idx_scm_student ON public.student_class_mapping(student_id);
CREATE INDEX IF NOT EXISTS idx_scm_class ON public.student_class_mapping(class_id);
CREATE INDEX IF NOT EXISTS idx_scm_academic_year ON public.student_class_mapping(academic_year_id);
CREATE INDEX IF NOT EXISTS idx_scm_current ON public.student_class_mapping(is_current);

CREATE INDEX IF NOT EXISTS idx_attendance_mapping ON public.attendance(student_class_mapping_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON public.attendance(attendance_date);

CREATE INDEX IF NOT EXISTS idx_fees_mapping ON public.fees(student_class_mapping_id);
CREATE INDEX IF NOT EXISTS idx_fees_academic_year ON public.fees(academic_year_id);

CREATE INDEX IF NOT EXISTS idx_ar_assessment ON public.assessment_results(assessment_id);
CREATE INDEX IF NOT EXISTS idx_ar_mapping ON public.assessment_results(student_class_mapping_id);

CREATE INDEX IF NOT EXISTS idx_students_parent_mobile ON public.students(primary_parent_mobile);

-- 7. Sync Trigger for Class & Section Compatibility
-- Keeps student.class_name and student.section in sync with student_class_mapping updates

CREATE OR REPLACE FUNCTION sync_student_class_section()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_current = true THEN
        UPDATE public.students s
        SET class_name = c.class_name,
            section = c.section
        FROM public.classes c
        WHERE c.id = NEW.class_id AND s.id = NEW.student_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_sync_student_class ON public.student_class_mapping;

CREATE TRIGGER trigger_sync_student_class
AFTER INSERT OR UPDATE ON public.student_class_mapping
FOR EACH ROW
EXECUTE FUNCTION sync_student_class_section();
