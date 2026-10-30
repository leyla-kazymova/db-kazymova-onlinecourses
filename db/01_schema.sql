
-- Лабораторная работа № 1
-- Тема № 10. Онлайн-курсы
-- Создание таблиц, ключей и ограничений

-- 1. Авторы курсов
CREATE TABLE authors (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name text NOT NULL,
    email text NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- 2. Ученики
CREATE TABLE students (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name text NOT NULL,
    email text NOT NULL UNIQUE,
    registered_at timestamptz NOT NULL DEFAULT now()
);

-- 3. Онлайн-курсы
CREATE TABLE courses (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    author_id integer NOT NULL
        REFERENCES authors(id) ON DELETE RESTRICT,
    title text NOT NULL,
    description text,
    price numeric(10, 2) NOT NULL DEFAULT 0
        CHECK (price >= 0),
    level text NOT NULL DEFAULT 'beginner'
        CHECK (level IN ('beginner', 'intermediate', 'advanced')),
    created_at timestamptz NOT NULL DEFAULT now()
);

-- 4. Уроки курсов
CREATE TABLE lessons (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_id integer NOT NULL
        REFERENCES courses(id) ON DELETE CASCADE,
    title text NOT NULL,
    lesson_number integer NOT NULL
        CHECK (lesson_number > 0),
    duration_minutes integer NOT NULL
        CHECK (duration_minutes > 0),
    UNIQUE (course_id, lesson_number)
);

-- 5. Записи учеников на курсы
-- Связь многие ко многим между students и courses
CREATE TABLE enrollments (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id integer NOT NULL
        REFERENCES students(id) ON DELETE CASCADE,
    course_id integer NOT NULL
        REFERENCES courses(id) ON DELETE CASCADE,
    enrolled_at timestamptz NOT NULL DEFAULT now(),
    status text NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'completed', 'cancelled')),
    UNIQUE (student_id, course_id)
);

-- 6. Прогресс прохождения уроков
CREATE TABLE lesson_progress (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    enrollment_id integer NOT NULL
        REFERENCES enrollments(id) ON DELETE CASCADE,
    lesson_id integer NOT NULL
        REFERENCES lessons(id) ON DELETE CASCADE,
    status text NOT NULL DEFAULT 'available'
        CHECK (status IN ('available', 'completed')),
    completed_at timestamptz,
    UNIQUE (enrollment_id, lesson_id),
    CHECK (
        (status = 'available' AND completed_at IS NULL)
        OR
        (status = 'completed' AND completed_at IS NOT NULL)
    )
);
