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

    def test_main_scene_and_script_exist(self):
        self.assertIn('run/main_scene="res://scenes/hotel.tscn"', (ROOT / "project.godot").read_text())
        self.assertIn('res://scripts/world/hotel.gd', (ROOT / "scenes/hotel.tscn").read_text())
        self.assertTrue((ROOT / "scripts/world/hotel.gd").is_file())


if __name__ == "__main__":
    unittest.main()
