-- Studio pull: 130 mm authored span on a 328 mm front. At the narrowest
-- front setting a 27 cm input renders 292.5 mm, leaving room for the
-- existing lateral offset and a margin on each side. 8 cm retains a usable grip.
UPDATE product_components SET min_width_cm=8, max_width_cm=27
WHERE component_key='desk_drawer_handle' AND default_width_cm=12
  AND min_width_cm=10 AND max_width_cm=14 AND is_active=1;
