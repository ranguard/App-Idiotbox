INSERT INTO buckets (slug, name) VALUES (
  'lpw2009', 'London Perl Workshop 2009'
);
INSERT INTO buckets (slug, name) VALUES (
  'opw2010', 'Perl Oasis 2010'
);

INSERT INTO announcements (id, made_at, bucket_slug) VALUES (
  1, '2009-12-25 09:00:00', 'lpw2009'
);
INSERT INTO announcements (id, made_at, bucket_slug) VALUES (
  2, '2010-01-01 14:00:00', 'lpw2009',
);
INSERT INTO announcements (id, made_at, bucket_slug) VALUES (
  3, '2010-01-21 01:00:00', 'opw2010'
);

INSERT INTO videos (
  slug, bucket_slug, name, author,announcement_id
) VALUES (
  'BEGIN', 'lpw2009', 'BEGINning Perl', 'Matt S Trout (mst)', 1
);
INSERT INTO videos (
  slug, bucket_slug, name, author,announcement_id
) VALUES (
  'dream', 'lpw2009', 'Dreamcasting', 'Matt S Trout (mst)', 2
);
INSERT INTO videos (
  slug, bucket_slug, name, author,announcement_id
) VALUES (
  'troll-god-mountain', 'opw2010', 'The Troll, the God and the Mountain',
   'Matt S Trout (mst)', 3
);
INSERT INTO videos (
  slug, bucket_slug, name, author,announcement_id
) VALUES (
  'keynote', 'opw2010', 'The Most Disgusting Word You''ll Hear'
  'Mark Keating (mdk)', 4
);
