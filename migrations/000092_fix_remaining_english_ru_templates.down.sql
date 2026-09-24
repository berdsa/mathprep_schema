UPDATE task_type_template SET template_text = CASE type_id
  WHEN 'G3-FRA-008' THEN 'What is 1/{{b}} of {{n}}?'
  WHEN 'G3-NUM-002' THEN '{{a}} × {{b}} = ?'
  WHEN 'G3-NUM-003' THEN '{{a}} ÷ {{b}} = ?'
  WHEN 'G6-NUM-002' THEN '{{a}} {{operator}} {{b}} = ?'
  WHEN 'G7-ALG-006' THEN '{{a}}^{{m}} × {{a}}^{{n}} = ?'
  ELSE template_text END
WHERE type_id IN ('G2-NUM-019','G2-NUM-020','G3-FRA-008','G3-NUM-002','G3-NUM-003','G6-NUM-002','G7-ALG-006')
  AND locale='ru-KZ' AND render_target='plaintext' AND spec_version='1.0.0-draft';
