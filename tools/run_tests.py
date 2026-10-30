import sys
import unittest
from pathlib import Path
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'tests'))
result=unittest.TextTestRunner(stream=sys.stdout,verbosity=2).run(unittest.defaultTestLoader.discover(str(root/'tests')))
raise SystemExit(not result.wasSuccessful())
