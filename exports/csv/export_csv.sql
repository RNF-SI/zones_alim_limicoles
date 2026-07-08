DROP VIEW IF EXISTS gn_monitoring.v_export_zones_alim_limicoles_standard;

CREATE OR REPLACE VIEW gn_monitoring.v_export_zones_alim_limicoles_standard AS
WITH visites AS (
    SELECT
        v.id_base_visit,
        v.visit_date_min::text AS date,
        v.id_base_site,
        v.comments AS commentaire_visit,
        b.base_site_name AS zone_etude,
        b.base_site_code,
        b.base_site_description,
        st_y(b.geom) AS latitude,
        st_x(b.geom) AS longitude,
        sg.sites_group_name AS site,
        sg.id_sites_group,
        sc.data AS site_data,
        vc.data AS visit_data
    FROM gn_monitoring.t_base_visits v
    JOIN gn_commons.t_modules mod ON v.id_module = mod.id_module
        AND mod.module_code = 'zones_alim_limicoles'
    JOIN gn_monitoring.t_base_sites b ON v.id_base_site = b.id_base_site
    LEFT JOIN gn_monitoring.t_site_complements sc ON b.id_base_site = sc.id_base_site
    LEFT JOIN gn_monitoring.t_sites_groups sg ON sc.id_sites_group = sg.id_sites_group
    LEFT JOIN gn_monitoring.t_visit_complements vc ON v.id_base_visit = vc.id_base_visit
),
observations AS (
    SELECT
        o.id_observation,
        o.id_base_visit,
        o.cd_nom,
        o.comments AS commentaire_obs,
        oc.data AS obs_data,
        o.uuid_observation,
        CASE WHEN o.cd_nom != 0 THEN tx.lb_nom END AS nom_taxon
    FROM gn_monitoring.t_observations o
    JOIN gn_monitoring.t_base_visits v ON o.id_base_visit = v.id_base_visit
    JOIN gn_commons.t_modules mod ON v.id_module = mod.id_module
        AND mod.module_code = 'zones_alim_limicoles'
    LEFT JOIN gn_monitoring.t_observation_complements oc ON o.id_observation = oc.id_observation
    LEFT JOIN taxonomie.taxref tx ON o.cd_nom = tx.cd_nom
),
fusion AS (
    SELECT
        v.id_base_visit,
        v.id_base_site,
        v.id_sites_group,
        v.site,
        v.zone_etude,
        v.base_site_code,
        v.base_site_description,
        v.latitude,
        v.longitude,
        v.site_data->>'gestionnaire' AS gestionnaire,
        v.site_data->>'operateur' AS operateur,
        v.site_data->>'superficie' AS superficie,
        n_habitat.label_default AS habitat_sedimentaire,
        v.date,
        v.visit_data->>'heure_debut' AS heure_debut,
        v.visit_data->>'heure_fin' AS heure_fin,
        v.visit_data->>'duree' AS duree,
        v.visit_data->>'xobs' AS xobs,
        v.visit_data->>'yobs' AS yobs,
        v.visit_data->>'dist_eau' AS dist_eau,
        v.visit_data->>'azimut_eau' AS azimut_eau,
        n_nebulosite.label_default AS nebulosite,
        n_vent_force.label_default AS vent_force,
        v.visit_data->>'azimut_vent' AS azimut_vent,
        v.visit_data->>'heure_pm' AS heure_pm,
        v.visit_data->>'heure_bm' AS heure_bm,
        v.visit_data->>'coeff' AS coeff,
        v.visit_data->>'obsv' AS observateurs,
        v.commentaire_visit,
        o.id_observation,
        o.uuid_observation,
        n_choix.label_default AS type_observation,
        o.obs_data->>'groupe' AS groupe,
        o.obs_data->>'distance' AS distance,
        o.obs_data->>'azimut' AS azimut,
        o.cd_nom,
        o.nom_taxon,
        o.obs_data->>'effectif_alim' AS effectif_alim,
        o.obs_data->>'effectif_repos' AS effectif_repos,
        o.obs_data->>'effectif_total' AS effectif_total,
        n_activite.label_default AS activite,
        o.obs_data->>'nombre' AS nombre,
        o.commentaire_obs
    FROM visites v
    JOIN observations o ON v.id_base_visit = o.id_base_visit
    LEFT JOIN ref_nomenclatures.t_nomenclatures n_habitat
        ON NULLIF(v.site_data->>'habitat_sedimentaire', '')::int = n_habitat.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n_nebulosite
        ON NULLIF(v.visit_data->>'nebulosite', '')::int = n_nebulosite.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n_vent_force
        ON NULLIF(v.visit_data->>'vent_force', '')::int = n_vent_force.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n_choix
        ON NULLIF(o.obs_data->>'choix', '')::int = n_choix.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n_activite
        ON NULLIF(o.obs_data->>'activite', '')::int = n_activite.id_nomenclature
)
SELECT
    f.site,
    f.zone_etude,
    f.base_site_code,
    f.base_site_description,
    f.gestionnaire,
    f.operateur,
    f.superficie::numeric,
    f.habitat_sedimentaire,
    f.latitude,
    f.longitude,
    f.date,
    f.heure_debut,
    f.heure_fin,
    f.duree::numeric,
    f.xobs::numeric,
    f.yobs::numeric,
    f.dist_eau::numeric,
    f.azimut_eau::numeric,
    f.nebulosite,
    f.vent_force,
    f.azimut_vent::numeric,
    f.heure_pm,
    f.heure_bm,
    f.coeff::numeric,
    f.observateurs,
    f.commentaire_visit,
    f.type_observation,
    f.groupe::numeric,
    f.distance::numeric,
    f.azimut::numeric,
    f.nom_taxon,
    f.cd_nom::bigint,
    f.effectif_alim::numeric,
    f.effectif_repos::numeric,
    f.effectif_total::numeric,
    f.activite,
    f.nombre::numeric,
    f.commentaire_obs,
    f.uuid_observation
FROM fusion f;
