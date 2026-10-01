-- Non-personal engine dictionaries copied from the authoritative migration
-- sources. This file intentionally contains no operational or identity rows.
INSERT INTO public.domain (code) VALUES
  ('NUM'),('FRA'),('DEC'),('GEO'),('MEA'),('ALG'),('FUN'),('STA'),('PRO'),('TRG'),('LOG'),('VEC'),('MAT'),('CAL'),('DIS');
INSERT INTO public.grade_band (code) VALUES
  ('1'),('2'),('3'),('4'),('5'),('6'),('7'),('8'),('9'),('10'),('11'),('UNIVERSITY');
INSERT INTO public.tier_code (code) VALUES ('T1'),('T2'),('T3');
INSERT INTO public.validation_method (code) VALUES ('EXACT-INT'),('EXACT-RAT'),('TOL'),('SET'),('CANON'),('CAS'),('BOOL'),('TUPLE'),('MATRIX');
INSERT INTO public.equivalence_policy (code) VALUES ('STRICT-FORM'),('EQUIV-CLASS'),('CAS-EQUIV');
INSERT INTO public.generation_mode (code) VALUES ('CODE'),('HYBRID-AI');
INSERT INTO public.task_type_status (code) VALUES ('DRAFT'),('GATED'),('FINAL');
INSERT INTO public.verdict (code) VALUES ('CORRECT'),('INCORRECT'),('UNPARSEABLE');
INSERT INTO public.reason_code (code) VALUES ('OK'),('PARSE_ERROR'),('EMPTY_INPUT'),('INPUT_TOO_LONG'),('WRONG_FORMAT'),('VALUE_MISMATCH'),('CANON_NOT_REDUCED'),('INCOMPLETE_TUPLE'),('SET_CARDINALITY_MISMATCH'),('CAS_TIMEOUT');
INSERT INTO public.render_target (code) VALUES ('plaintext'),('unicode-math'),('latex');
INSERT INTO public.locale (code) VALUES ('ru-KZ'),('kk-KZ'),('en-US');
INSERT INTO public.user_type (code) VALUES ('STUDENT'),('GUARDIAN'),('ADMIN');
INSERT INTO public.cas_operation_type (code) VALUES ('EQUIVALENCE');
INSERT INTO public.cas_evaluation_status (code) VALUES ('PENDING'),('IN_PROGRESS'),('DONE'),('FAILED');
INSERT INTO public.event_type (code) VALUES ('GENERATION_REQUESTED'),('GENERATION_COMPLETED'),('GENERATION_FAILED'),('SUBMISSION_GRADED'),('MASTERY_UPDATED'),('CAS_EVALUATION_COMPLETED'),('CAS_EVALUATION_FAILED');
