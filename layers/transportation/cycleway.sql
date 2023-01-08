-- this function adapted from @arichnad's openmaptiles-cycle fork for cyclemap.us
-- https://github.com/cyclemap/openmaptiles-cycle/blob/master/layers/transportation/cycleway.sql
-- TODO: I think this is missing service roads, check randalls island
CREATE OR REPLACE FUNCTION is_cycleway(highway TEXT, bicycle TEXT, cycleway TEXT, cycleway_left TEXT, cycleway_right TEXT, cycleway_both TEXT) RETURNS boolean AS
$$
SELECT CASE
  WHEN highway IN ('construction') THEN false

  WHEN bicycle IN ('no', 'private', 'permit', 'use_sidepath') THEN false

  WHEN highway = 'cycleway' THEN true
  
  WHEN cycleway IN ('lane', 'opposite_lane', 'shared_lane', 'track', 'opposite_track') OR
    cycleway_left IN ('lane', 'opposite_lane',  'shared_lane', 'track', 'opposite_track') OR
    cycleway_right IN ('lane', 'opposite_lane', 'shared_lane', 'track', 'opposite_track') OR
    cycleway_both IN ('lane', 'opposite_lane', 'shared_lane', 'track', 'opposite_track') THEN true
  
  WHEN highway IN ('pedestrian', 'living_street', 'path', 'footway', 'steps', 'bridleway', 'corridor', 'track') AND bicycle IN ('yes', 'permissive', 'dismount', 'designated') THEN true

  ELSE false
END;
$$ LANGUAGE SQL IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION get_cycleway_type(highway TEXT, cycleway TEXT, cycleway_left TEXT, cycleway_right TEXT, cycleway_both TEXT) RETURNS text AS
$$
SELECT CASE
  WHEN cycleway IN ('lane', 'opposite_lane') OR
    cycleway_left IN ('lane', 'opposite_lane') OR
    cycleway_right IN ('lane', 'opposite_lane') OR
    cycleway_both IN ('lane', 'opposite_lane')
    THEN 'lane'
  WHEN cycleway IN ('shared_lane') OR
    cycleway_left IN ('shared_lane') OR
    cycleway_right IN ('shared_lane') OR
    cycleway_both IN ('shared_lane')
    THEN 'shared_lane'
  WHEN highway IN ('path', 'footway', 'cycleway') OR
    cycleway IN ('track') OR
    cycleway_left IN ('track') OR
    cycleway_right IN ('track') OR
    cycleway_both IN ('track')
    THEN 'track'
  ELSE NULL
END;
$$ LANGUAGE SQL IMMUTABLE PARALLEL SAFE;

-- TODO: all the weird non 1/-1 values here are for debugging and get ignored by styles, but
-- probably should be removed in the future
CREATE OR REPLACE FUNCTION get_one_way_cycle_direction(oneway INT, oneway_bicycle TEXT, cycleway TEXT, cycleway_left TEXT, cycleway_left_oneway TEXT, cycleway_right TEXT, cycleway_right_oneway TEXT, cycleway_both TEXT) RETURNS int AS
$$
SELECT CASE
  -- TODO: can cycleway:both be 1-way?
  WHEN cycleway_both <> '' THEN 2
  WHEN (oneway=1 OR oneway=-1) THEN
    oneway*(
      CASE
        WHEN cycleway IN ('lane', 'shared_lane', 'track') THEN
          CASE
            WHEN oneway_bicycle='no' THEN 3
            ELSE 1
          END
        WHEN (
          cycleway IN ('opposite_lane', 'opposite_track')
          OR cycleway_left IN ('opposite_lane', 'opposite_track')
          OR cycleway_right IN ('opposite_lane', 'opposite_track')
        ) THEN -1
        -- TODO: should we use oneway:bicycle for these?
        WHEN cycleway_left IN ('lane', 'shared_lane', 'track') THEN
          CASE
            WHEN cycleway_left_oneway='-1' THEN -1
            WHEN cycleway_left_oneway='1' THEN 1
            WHEN cycleway_left_oneway='no' THEN 4
            ELSE 1
          END
        WHEN cycleway_right IN ('lane', 'shared_lane', 'track') THEN
          CASE
            WHEN cycleway_right_oneway='-1' THEN -1
            WHEN cycleway_right_oneway='1' THEN 1
            WHEN cycleway_right_oneway='no' THEN 5
            ELSE 1
          END
        ELSE 1 -- TODO: this should ideally not be reachable
      END
    )
  ELSE
    CASE
      WHEN cycleway_left IN ('lane', 'shared_lane', 'track') THEN
        CASE
          WHEN cycleway_right='' THEN -1
          ELSE 6
        END
      WHEN cycleway_right IN ('lane', 'shared_lane', 'track') THEN
        CASE
          WHEN cycleway_left='' THEN 1
          ELSE 7
        END
      ELSE 8
    END
END;
$$ LANGUAGE SQL IMMUTABLE PARALLEL SAFE;