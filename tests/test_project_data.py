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

    def test_main_scene_and_script_exist(self):
        self.assertIn('run/main_scene="res://scenes/hotel.tscn"', (ROOT / "project.godot").read_text())
        self.assertIn('res://scripts/world/hotel.gd', (ROOT / "scenes/hotel.tscn").read_text())
        self.assertTrue((ROOT / "scripts/world/hotel.gd").is_file())


if __name__ == "__main__":
    unittest.main()
