"""Dependency-free checks for authored population data; not gameplay tests."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class PopulationDataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.people = json.loads((ROOT / "resources/hotel_population.json").read_text())

    def test_unique_named_identities(self):
        names = [person["identity"] for person in self.people]
        self.assertEqual(len(names), 3)
        self.assertEqual(len(names), len(set(names)))
        self.assertTrue(all(names))

    def test_schedules_have_valid_activities_and_durations(self):
        for person in self.people:
            self.assertIn(person["occupation"], {"civilian", "employee", "security", "manager", "special"})
            self.assertGreaterEqual(person["alertness"], 0)
            self.assertLessEqual(person["alertness"], 1)
            self.assertTrue(person["schedule"])
            for entry in person["schedule"]:
                self.assertIn(entry["activity"], {"working", "waiting", "conversing", "idle"})
                self.assertGreater(entry["duration"], 0)

    def test_destinations_fit_the_current_navmesh(self):
        for person in self.people:
            for position in [person["start"]] + [entry["destination"] for entry in person["schedule"]]:
                self.assertEqual(len(position), 3)
                self.assertLessEqual(abs(position[0]), 11.5)
                self.assertLessEqual(abs(position[2]), 7.5)

    def test_schedule_points_do_not_land_inside_partitions(self):
        for person in self.people:
            for position in [person["start"]] + [entry["destination"] for entry in person["schedule"]]:
                x, _, z = position
                for boundary in (2.0, 7.0):
                    if abs(x - boundary) < 0.5:
                        self.assertTrue(2.35 <= abs(z) <= 3.65)

    def test_record_configuration_is_consistent_and_accessible_by_layout(self):
        mission = json.loads((ROOT / "resources/meridian_mission.json").read_text())
        records = mission["records"]
        ids = [record["id"] for record in records]
        self.assertEqual(ids, ["ledger", "memo", "archive"])
        self.assertEqual(len(set(ids)), 3)
        self.assertEqual(mission["required_records"], 2)
        self.assertLessEqual(mission["required_records"], len(ids))
        for record in records:
            self.assertTrue(record["label"] and record["message"])
            x, y, z = record["position"]
            self.assertTrue(-11.0 < x < 11.0 and y == 0 and -7.0 < z < 7.0)
            for boundary in (2.0, 7.0):
                self.assertGreater(abs(x - boundary), 0.5)
            # Record markers must not be inside the visual counter/table footprints.
            for cx, cz, sx, sz in [(-5, -4.8, 4, 1), (-5, 3.5, 2.4, 1), (4.5, -5, 2.2, 1), (9.5, -5, 2.5, 1)]:
                self.assertFalse(abs(x - cx) < sx / 2 and abs(z - cz) < sz / 2)

    def test_primary_target_data_and_routes(self):
        meridian = json.loads((ROOT / "resources/meridian_mission.json").read_text())
        target = meridian["primary_target"]
        self.assertEqual(target["id"], "adrian_locke")
        self.assertNotIn(target["name"], [person["identity"] for person in self.people])
        self.assertTrue(target["description"] and target["schedule"])
        for x, y, z in [target["start"]] + [entry["destination"] for entry in target["schedule"]]:
            self.assertTrue(-41.0 < x < -34.5 and -13.5 < z < -6.0)
            self.assertGreaterEqual(y, 3.5)
        initiation = json.loads((ROOT / "resources/initiation_mission.json").read_text())
        self.assertEqual(initiation["primary_target"]["id"], "assessment_unit")
        self.assertEqual(initiation["required_action"], "disable_assessment_unit")

    def test_hong_kong_campaign_rebuild_has_one_connected_city_operation(self):
        campaign = json.loads((ROOT / "resources/campaign.json").read_text())
        ops = json.loads((ROOT / "resources/hong_kong_operations.json").read_text())
        ids = [entry["id"] for entry in campaign["missions"]]
        self.assertEqual(ids, ["initiation", "meridian", "tung_chung", "hong_kong_sandbox", "ngong_ping"])
        self.assertFalse({"the_streets", "the_district", "the_harbour"}.intersection(ids))
        self.assertEqual(campaign["missions"][2]["key_id"], "key_01")
        sandbox = campaign["missions"][3]
        self.assertEqual(sandbox["key_ids"], ["key_02", "key_03", "key_04"])
        self.assertEqual(campaign["missions"][4]["key_id"], "key_05")
        self.assertEqual(ops["hong_kong_sandbox"]["map"], "city")
        self.assertEqual([target["id"] for target in ops["hong_kong_sandbox"]["targets"]], ["loan_shark", "corporate_fixer", "harbour_businessman"])
        self.assertEqual([key["id"] for key in ops["hong_kong_sandbox"]["keys"]], ["key_02", "key_03", "key_04"])
        for target in ops["hong_kong_sandbox"]["targets"]:
            self.assertTrue(target["identity"] and target["dialogue"] and target["routine"])
            self.assertGreaterEqual(len(target["routine"]), 3)
            self.assertEqual(len(target["start"]), 3)
        scene = ROOT / sandbox["scene"].removeprefix("res://")
        self.assertTrue(scene.is_file())
        self.assertIn('operation_id = "hong_kong_sandbox"', scene.read_text())
        for key in ["key_01", "key_02", "key_03", "key_04", "key_05"]:
            self.assertEqual(sum(mission.get("key_id") == key or key in mission.get("key_ids", []) for mission in campaign["missions"]), 1)

    def test_legacy_city_data_remains_only_for_migration_and_district_builders(self):
        campaign = json.loads((ROOT / "resources/campaign.json").read_text())
        ops = json.loads((ROOT / "resources/hong_kong_operations.json").read_text())
        for legacy_id in ["the_streets", "the_district", "the_harbour"]:
            self.assertNotIn(legacy_id, [mission["id"] for mission in campaign["missions"]])
            self.assertIn(legacy_id, ops)
        self.assertIn('if operation_id == "hong_kong_sandbox":', (ROOT / "scripts/missions/hong_kong_operation.gd").read_text())
        self.assertTrue((ROOT / "scripts/world/destructible_glass.gd").is_file())

    def test_main_scene_and_script_exist(self):
        self.assertIn('run/main_scene="res://scenes/main_menu.tscn"', (ROOT / "project.godot").read_text())
        self.assertIn('res://scripts/world/hotel.gd', (ROOT / "scenes/hotel.tscn").read_text())
        self.assertTrue((ROOT / "scripts/world/hotel.gd").is_file())


if __name__ == "__main__":
    unittest.main()
