"""Offline generator safety tests; not a substitute for UE shader compilation."""
import importlib.util
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import Mock

PATH = Path(__file__).resolve().parents[1] / 'Tools/build_weather_material_review.py'

class WeatherReviewTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(PATH.exists(), 'Weather material builder has not been implemented')
        spec = importlib.util.spec_from_file_location('weather_review', PATH)
        self.m = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.m)

    def api(self, occupied=False, dirty=False, mesh=True):
        return SimpleNamespace(
            EditorAssetLibrary=SimpleNamespace(does_directory_exist=Mock(return_value=occupied)),
            EditorLoadingAndSavingUtils=SimpleNamespace(
                get_dirty_map_packages=Mock(return_value=['dirty'] if dirty else []),
                get_dirty_content_packages=Mock(return_value=[])),
            load_asset=Mock(return_value=object() if mesh else None))

    def test_existing_destination_refused(self):
        api = self.api(occupied=True)
        with self.assertRaisesRegex(RuntimeError, 'exists'):
            self.m.preflight(api)
        api.load_asset.assert_not_called()

    def test_dirty_editor_refused(self):
        with self.assertRaisesRegex(RuntimeError, 'unsaved'):
            self.m.preflight(self.api(dirty=True))

    def test_dirty_material_refused(self):
        api = self.api()
        api.EditorLoadingAndSavingUtils.get_dirty_content_packages.return_value = ['material']
        with self.assertRaisesRegex(RuntimeError, 'unsaved'):
            self.m.preflight(api)

    def test_missing_mesh_refused(self):
        with self.assertRaisesRegex(RuntimeError, 'mesh'):
            self.m.preflight(self.api(mesh=False))

    def test_clean_preflight_returns_required_meshes(self):
        self.assertEqual(set(self.m.preflight(self.api())), {'Plane', 'Sphere', 'Cube'})

    def test_failed_connections_raise(self):
        with self.assertRaisesRegex(RuntimeError, 'connection'):
            self.m.require_connection(False, 'UV')

    def test_native_build_fails_explicitly_outside_editor(self):
        with self.assertRaisesRegex(RuntimeError, 'Unreal Editor'):
            self.m.build()

    def test_compiler_errors_rejected(self):
        with self.assertRaisesRegex(RuntimeError, 'compiler'):
            self.m.require_compilation_result(['invalid shader'])

    def test_missing_compiler_result_rejected(self):
        with self.assertRaisesRegex(RuntimeError, 'compiler'):
            self.m.require_compilation_result(None)

    def test_empty_compiler_error_list_accepted(self):
        self.m.require_compilation_result([])

    def test_plan_unique_and_confined_to_review(self):
        plan = self.m.validate()
        self.assertEqual(len(plan['materials']), 7)
        self.assertEqual(len(set(plan['materials'])), 7)
        self.assertTrue(plan['root'].startswith('/Game/TSTSS/Review/'))
        self.assertEqual(plan['native_render'], 'NOT_RUN')

if __name__ == '__main__':
    unittest.main()
