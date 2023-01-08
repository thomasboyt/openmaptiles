-- this function adapted from @arichnad's openmaptiles-cycle fork for cyclemap.us
-- https://github.com/cyclemap/openmaptiles-cycle/blob/master/layers/transportation/cycleway.sql
CREATE OR REPLACE FUNCTION is_cycleway(highway TEXT, bicycle TEXT, cycleway TEXT, cycleway_left TEXT, cycleway_right TEXT, cycleway_both TEXT) RETURNS boolean AS
$$
SELECT CASE
        WHEN highway IN ('construction') THEN false

        WHEN bicycle IN ('no', 'private', 'permit') THEN false

        WHEN highway = 'cycleway' THEN true
        
        WHEN cycleway IN ('lane', 'opposite_lane', 'opposite', 'share_busway', 'shared', 'track', 'opposite_track') OR
            cycleway_left IN ('lane', 'opposite_lane', 'opposite', 'share_busway', 'shared', 'track', 'opposite_track') OR
            cycleway_right IN ('lane', 'opposite_lane', 'opposite', 'share_busway', 'shared', 'track', 'opposite_track') OR
            cycleway_both IN ('lane', 'opposite_lane', 'opposite', 'share_busway', 'shared', 'track', 'opposite_track') THEN true
        
        WHEN highway IN ('pedestrian', 'living_street', 'path', 'footway', 'steps', 'bridleway', 'corridor', 'track') AND bicycle IN ('yes', 'permissive', 'dismount', 'designated') THEN true

        ELSE false
END;
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;
